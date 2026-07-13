import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type ServiceAccount = {
  client_email: string;
  private_key: string;
  private_key_id?: string;
  project_id: string;
  token_uri?: string;
};

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const publishableKey = getNamedSupabaseKey("SUPABASE_PUBLISHABLE_KEYS") ??
    Deno.env.get("SUPABASE_ANON_KEY");
  const secretKey = getNamedSupabaseKey("SUPABASE_SECRET_KEYS") ??
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  const authorization = request.headers.get("Authorization");

  if (
    !supabaseUrl ||
    !publishableKey ||
    !secretKey ||
    !serviceAccountJson ||
    !authorization
  ) {
    return jsonResponse({ error: "Push notifications are not configured" }, 503);
  }

  try {
    const token = authorization.replace(/^Bearer\s+/i, "");
    const body = await request.json();
    const listId = String(body.list_id ?? "").trim();
    if (!isUuid(listId)) {
      return jsonResponse({ error: "Valid shared list id is required" }, 400);
    }

    const userClient = createClient(supabaseUrl, publishableKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const adminClient = createClient(supabaseUrl, secretKey, {
      auth: { persistSession: false },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser(token);
    if (userError || !user) {
      return jsonResponse({ error: "Authentication required" }, 401);
    }

    const { data: claimedRows, error: claimError } = await userClient.rpc(
      "claim_shared_list_addition_notification",
      { target_list_id: listId },
    );
    if (claimError) {
      return jsonResponse({ error: claimError.message }, 403);
    }

    const claim = Array.isArray(claimedRows) ? claimedRows[0] : null;
    if (!claim) {
      return jsonResponse({ accepted: true, sent: 0 });
    }

    const { data: members, error: membersError } = await adminClient
      .from("space_members")
      .select("user_id")
      .eq("space_id", claim.target_space_id)
      .neq("user_id", user.id);
    if (membersError) {
      throw membersError;
    }

    const recipientIds = (members ?? []).map((member) => member.user_id);
    if (recipientIds.length === 0) {
      console.log("Shared-list push result: no recipients");
      return jsonResponse({ accepted: true, sent: 0 });
    }

    const { data: devices, error: devicesError } = await adminClient
      .from("push_devices")
      .select("token")
      .in("user_id", recipientIds);
    if (devicesError) {
      throw devicesError;
    }

    if (!devices || devices.length === 0) {
      console.log(
        `Shared-list push result: recipients=${recipientIds.length}, devices=0, sent=0`,
      );
      return jsonResponse({ accepted: true, failed: 0, sent: 0 });
    }

    const serviceAccount = parseServiceAccount(serviceAccountJson);
    const accessToken = await getGoogleAccessToken(serviceAccount);
    const notificationBody =
      `Do listy zakupów ${claim.target_list_name} dodano nowe produkty.`;
    const invalidTokens: string[] = [];
    let sent = 0;

    await Promise.all(
      (devices ?? []).map(async ({ token: deviceToken }) => {
        const result = await sendFcmNotification({
          accessToken,
          body: notificationBody,
          deviceToken,
          listId,
          projectId: serviceAccount.project_id,
        });
        if (result.sent) {
          sent++;
        }
        if (result.invalidToken) {
          invalidTokens.push(deviceToken);
        }
      }),
    );

    if (invalidTokens.length > 0) {
      const { error: cleanupError } = await adminClient
        .from("push_devices")
        .delete()
        .in("token", invalidTokens);
      if (cleanupError) {
        console.error("Failed to remove invalid push tokens", cleanupError);
      }
    }

    const failed = devices.length - sent;
    console.log(
      `Shared-list push result: recipients=${recipientIds.length}, ` +
        `devices=${devices.length}, sent=${sent}, failed=${failed}`,
    );
    return jsonResponse({ accepted: true, failed, sent });
  } catch (error) {
    console.error("Shared-list push notification failed", error);
    return jsonResponse({ error: "Push notification request failed" }, 500);
  }
});

async function sendFcmNotification({
  accessToken,
  body,
  deviceToken,
  listId,
  projectId,
}: {
  accessToken: string;
  body: string;
  deviceToken: string;
  listId: string;
  projectId: string;
}): Promise<{ invalidToken: boolean; sent: boolean }> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: deviceToken,
          notification: {
            title: "ShopMaps",
            body,
          },
          data: {
            type: "shared_list_additions",
            list_id: listId,
          },
          android: {
            priority: "high",
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        },
      }),
    },
  );

  if (response.ok) {
    return { invalidToken: false, sent: true };
  }

  const payload = await response.json().catch(() => ({}));
  console.error("FCM request failed", response.status, payload);
  return {
    invalidToken:
      response.status === 404 ||
      JSON.stringify(payload).includes('"errorCode":"UNREGISTERED"'),
    sent: false,
  };
}

async function getGoogleAccessToken(
  serviceAccount: ServiceAccount,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const assertion = await signJwt(
    {
      alg: "RS256",
      typ: "JWT",
      ...(serviceAccount.private_key_id
        ? { kid: serviceAccount.private_key_id }
        : {}),
    },
    {
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
    },
    serviceAccount.private_key,
  );

  const response = await fetch(
    serviceAccount.token_uri ?? "https://oauth2.googleapis.com/token",
    {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        assertion,
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      }),
    },
  );
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const oauthError = stringValue(payload.error);
    const description = stringValue(payload.error_description);
    console.error("Google OAuth request failed", response.status, {
      error: oauthError,
      error_description: description,
      firebase_project_id: serviceAccount.project_id,
      service_account_email: serviceAccount.client_email,
      service_account_key_id: serviceAccount.private_key_id ?? "missing",
    });
    throw new Error(
      `Google OAuth request failed (${response.status})` +
        (oauthError ? `: ${oauthError}` : "") +
        (description ? `: ${description}` : ""),
    );
  }

  if (!payload.access_token) {
    throw new Error("Google OAuth did not return an access token");
  }
  return String(payload.access_token);
}

async function signJwt(
  header: Record<string, unknown>,
  claims: Record<string, unknown>,
  privateKeyPem: string,
): Promise<string> {
  const unsignedToken =
    `${base64Url(new TextEncoder().encode(JSON.stringify(header)))}.` +
    base64Url(new TextEncoder().encode(JSON.stringify(claims)));
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToBytes(privateKeyPem),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(unsignedToken),
  );
  return `${unsignedToken}.${base64Url(new Uint8Array(signature))}`;
}

function parseServiceAccount(rawValue: string): ServiceAccount {
  let value = JSON.parse(rawValue);
  if (typeof value === "string") {
    value = JSON.parse(value);
  }
  if (!value.client_email || !value.private_key || !value.project_id) {
    throw new Error("Firebase service account is incomplete");
  }
  if (value.type && value.type !== "service_account") {
    throw new Error("Firebase credential is not a service account");
  }
  return {
    client_email: String(value.client_email),
    private_key: String(value.private_key).replace(/\\n/g, "\n"),
    private_key_id: stringValue(value.private_key_id) || undefined,
    project_id: String(value.project_id),
    token_uri: stringValue(value.token_uri) || undefined,
  };
}

function stringValue(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function getNamedSupabaseKey(environmentName: string): string | null {
  const rawValue = Deno.env.get(environmentName);
  if (!rawValue) {
    return null;
  }
  try {
    const keys = JSON.parse(rawValue);
    const defaultKey = String(keys.default ?? "").trim();
    return defaultKey.length === 0 ? null : defaultKey;
  } catch {
    return null;
  }
}

function pemToBytes(value: string): Uint8Array {
  const base64 = value
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  return Uint8Array.from(atob(base64), (character) => character.charCodeAt(0));
}

function base64Url(value: Uint8Array): string {
  let binary = "";
  for (const byte of value) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Connection": "keep-alive",
    },
  });
}
