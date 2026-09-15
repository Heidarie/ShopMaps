import "edge-runtime";
import { createRemoteJWKSet, importPKCS8, jwtVerify, SignJWT } from "jose";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const appleIssuer = "https://appleid.apple.com";
const appleKeys = createRemoteJWKSet(
  new URL("https://appleid.apple.com/auth/keys"),
);

type SupabaseIdentity = {
  id?: unknown;
  identity_data?: {
    sub?: unknown;
  };
  identity_id?: unknown;
  provider?: unknown;
};

type SupabaseUser = {
  app_metadata?: {
    provider?: unknown;
    providers?: unknown;
  };
  identities?: SupabaseIdentity[];
};

type AppleTokenResponse = {
  access_token?: unknown;
  error?: unknown;
  id_token?: unknown;
  refresh_token?: unknown;
};

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const authorization = request.headers.get("Authorization");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const publishableKey = getNamedSupabaseKey("SUPABASE_PUBLISHABLE_KEYS") ??
    Deno.env.get("SUPABASE_ANON_KEY");
  const appleTeamId = Deno.env.get("APPLE_TEAM_ID")?.trim();
  const appleKeyId = Deno.env.get("APPLE_KEY_ID")?.trim();
  const appleClientId = Deno.env.get("APPLE_CLIENT_ID")?.trim();
  const applePrivateKey = normalizePrivateKey(
    Deno.env.get("APPLE_PRIVATE_KEY"),
  );

  if (!authorization || !supabaseUrl || !publishableKey) {
    return jsonResponse({ error: "Authentication required" }, 401);
  }
  if (!appleTeamId || !appleKeyId || !appleClientId || !applePrivateKey) {
    return jsonResponse(
      { error: "Apple token revocation is not configured" },
      503,
    );
  }

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return jsonResponse({ error: "Invalid request body" }, 400);
  }

  const authorizationCode = stringValue(body.authorization_code);
  if (
    !authorizationCode ||
    authorizationCode.length < 20 ||
    authorizationCode.length > 4096
  ) {
    return jsonResponse(
      { error: "Valid Apple authorization code is required" },
      400,
    );
  }

  try {
    const user = await authenticatedUser({
      authorization,
      publishableKey,
      supabaseUrl,
    });
    if (!user) {
      return jsonResponse({ error: "Authentication required" }, 401);
    }

    const appleSubjects = appleIdentitySubjects(user);
    if (appleSubjects.size === 0) {
      return jsonResponse({ error: "Apple identity is not linked" }, 403);
    }

    const clientSecret = await createAppleClientSecret({
      clientId: appleClientId,
      keyId: appleKeyId,
      privateKey: applePrivateKey,
      teamId: appleTeamId,
    });
    const tokenResponse = await fetch("https://appleid.apple.com/auth/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: appleClientId,
        client_secret: clientSecret,
        code: authorizationCode,
        grant_type: "authorization_code",
      }),
    });
    const tokenPayload = await tokenResponse.json()
      .catch(() => ({})) as AppleTokenResponse;
    if (!tokenResponse.ok) {
      console.error(
        "Apple authorization-code exchange failed",
        tokenResponse.status,
        stringValue(tokenPayload.error) ?? "unknown_error",
      );
      return jsonResponse(
        { error: "Apple authorization code was rejected" },
        502,
      );
    }

    const appleIdToken = stringValue(tokenPayload.id_token);
    const refreshToken = stringValue(tokenPayload.refresh_token);
    const accessToken = stringValue(tokenPayload.access_token);
    if (!appleIdToken || (!refreshToken && !accessToken)) {
      return jsonResponse(
        { error: "Apple token response was incomplete" },
        502,
      );
    }

    const { payload } = await jwtVerify(appleIdToken, appleKeys, {
      audience: appleClientId,
      issuer: appleIssuer,
    });
    if (!payload.sub || !appleSubjects.has(payload.sub)) {
      return jsonResponse(
        { error: "Apple authorization belongs to another account" },
        403,
      );
    }

    const tokenToRevoke = refreshToken ?? accessToken!;
    const tokenTypeHint = refreshToken ? "refresh_token" : "access_token";
    const revokeResponse = await fetch(
      "https://appleid.apple.com/auth/revoke",
      {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          client_id: appleClientId,
          client_secret: clientSecret,
          token: tokenToRevoke,
          token_type_hint: tokenTypeHint,
        }),
      },
    );
    if (!revokeResponse.ok) {
      const revokePayload = await revokeResponse.json().catch(() => ({}));
      console.error(
        "Apple token revocation failed",
        revokeResponse.status,
        stringValue(revokePayload.error) ?? "unknown_error",
      );
      return jsonResponse({ error: "Apple token could not be revoked" }, 502);
    }

    return jsonResponse({ revoked: true });
  } catch (error) {
    console.error(
      "Apple token revocation request failed",
      error instanceof Error ? error.message : "unknown_error",
    );
    return jsonResponse({ error: "Apple token revocation failed" }, 500);
  }
});

async function authenticatedUser({
  authorization,
  publishableKey,
  supabaseUrl,
}: {
  authorization: string;
  publishableKey: string;
  supabaseUrl: string;
}): Promise<SupabaseUser | null> {
  const response = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      apikey: publishableKey,
      Authorization: authorization,
    },
  });
  if (!response.ok) {
    return null;
  }
  return await response.json() as SupabaseUser;
}

function appleIdentitySubjects(user: SupabaseUser): Set<string> {
  const subjects = new Set<string>();
  for (const identity of user.identities ?? []) {
    if (identity.provider !== "apple") {
      continue;
    }
    for (
      const candidate of [
        identity.identity_data?.sub,
        identity.identity_id,
        identity.id,
      ]
    ) {
      const value = stringValue(candidate);
      if (value) {
        subjects.add(value);
      }
    }
  }

  const providers = user.app_metadata?.providers;
  const hasAppleProvider = user.app_metadata?.provider === "apple" ||
    (Array.isArray(providers) && providers.includes("apple"));
  return hasAppleProvider ? subjects : new Set<string>();
}

async function createAppleClientSecret({
  clientId,
  keyId,
  privateKey,
  teamId,
}: {
  clientId: string;
  keyId: string;
  privateKey: string;
  teamId: string;
}): Promise<string> {
  const signingKey = await importPKCS8(privateKey, "ES256");
  const issuedAt = Math.floor(Date.now() / 1000);
  return await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyId, typ: "JWT" })
    .setIssuer(teamId)
    .setSubject(clientId)
    .setAudience(appleIssuer)
    .setIssuedAt(issuedAt)
    .setExpirationTime(issuedAt + 300)
    .sign(signingKey);
}

function getNamedSupabaseKey(environmentName: string): string | null {
  const rawValue = Deno.env.get(environmentName);
  if (!rawValue) {
    return null;
  }
  try {
    const keys = JSON.parse(rawValue);
    return stringValue(keys.default);
  } catch {
    return null;
  }
}

function normalizePrivateKey(value: string | undefined): string | null {
  const normalized = value?.replaceAll("\\n", "\n").trim();
  return normalized?.includes("BEGIN PRIVATE KEY") ? normalized : null;
}

function stringValue(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value.trim();
  return normalized ? normalized : null;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
