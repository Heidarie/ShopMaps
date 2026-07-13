import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const storeCategories = [
  "commercial.supermarket",
  "commercial.convenience",
  "commercial.discount_store",
  "commercial.food_and_drink",
  "commercial.marketplace",
].join(",");

const supportedStoreCountries = new Set([
  "gb",
  "pl",
  "de",
  "nl",
  "es",
  "fr",
  "ua",
  "it",
  "pt",
]);

type SupabaseAdmin = ReturnType<typeof createClient>;

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const apiKey = Deno.env.get("GEOAPIFY_API_KEY");
  if (!apiKey) {
    return jsonResponse({ error: "Geoapify is not configured" }, 503);
  }

  try {
    const body = await request.json();
    const language = String(body.language ?? "en")
      .trim()
      .toLowerCase()
      .slice(0, 2);
    const profileContext = await resolveProfileContext(request);
    if ("response" in profileContext) {
      return profileContext.response;
    }

    if (body.mode === "nearby_stores") {
      return searchNearbyStores(
        body,
        language,
        apiKey,
        profileContext.countryCode,
        profileContext.admin,
      );
    }

    return searchAddresses(body, language, apiKey, profileContext.countryCode);
  } catch {
    return jsonResponse({ error: "Invalid request" }, 400);
  }
});

async function searchAddresses(
  body: Record<string, unknown>,
  language: string,
  apiKey: string,
  countryCode: string,
): Promise<Response> {
  const query = String(body.query ?? "").trim();

  try {
    if (query.length < 3 || query.length > 200) {
      return jsonResponse(
        { error: "Address query must contain between 3 and 200 characters" },
        400,
      );
    }

    const url = new URL("https://api.geoapify.com/v1/geocode/autocomplete");
    url.searchParams.set("text", query);
    url.searchParams.set("format", "json");
    url.searchParams.set("limit", "8");
    url.searchParams.set("lang", language || "en");
    url.searchParams.set("filter", `countrycode:${countryCode}`);
    url.searchParams.set("apiKey", apiKey);

    const geoapifyResponse = await fetch(url);
    if (!geoapifyResponse.ok) {
      return jsonResponse({ error: "Address provider request failed" }, 502);
    }

    const payload = await geoapifyResponse.json();
    const results = Array.isArray(payload.results) ? payload.results : [];
    const suggestions = results
      .filter((entry: Record<string, unknown>) =>
        Boolean(entry.place_id && entry.formatted && entry.country_code)
      )
      .map((entry: Record<string, unknown>) => ({
        provider: "geoapify",
        provider_place_id: String(entry.place_id),
        formatted_address: String(entry.formatted),
        street: optionalString(entry.street),
        house_number: optionalString(entry.housenumber),
        postcode: optionalString(entry.postcode),
        city: optionalString(entry.city ?? entry.town ?? entry.village),
        country_code: String(entry.country_code).toLowerCase(),
        latitude: Number(entry.lat),
        longitude: Number(entry.lon),
      }))
      .filter((entry: Record<string, unknown>) =>
        entry.country_code === countryCode
      )
      .filter((entry: Record<string, unknown>) =>
        Number.isFinite(entry.latitude) && Number.isFinite(entry.longitude)
      );

    return jsonResponse({ suggestions });
  } catch {
    return jsonResponse({ error: "Address provider request failed" }, 502);
  }
}

async function searchNearbyStores(
  body: Record<string, unknown>,
  language: string,
  apiKey: string,
  countryCode: string,
  admin: SupabaseAdmin,
): Promise<Response> {
  const latitude = Number(body.latitude);
  const longitude = Number(body.longitude);
  if (
    !Number.isFinite(latitude) ||
    !Number.isFinite(longitude) ||
    latitude < -90 ||
    latitude > 90 ||
    longitude < -180 ||
    longitude > 180
  ) {
    return jsonResponse({ error: "Valid coordinates are required" }, 400);
  }

  try {
    const url = new URL("https://api.geoapify.com/v2/places");
    url.searchParams.set("categories", storeCategories);
    url.searchParams.set("conditions", "named");
    url.searchParams.set("filter", `circle:${longitude},${latitude},4000`);
    url.searchParams.set("bias", `proximity:${longitude},${latitude}`);
    url.searchParams.set("limit", "50");
    url.searchParams.set("lang", language || "en");
    url.searchParams.set("apiKey", apiKey);

    const geoapifyResponse = await fetch(url);
    if (!geoapifyResponse.ok) {
      return jsonResponse({ error: "Places provider request failed" }, 502);
    }

    const payload = await geoapifyResponse.json();
    const features = Array.isArray(payload.features) ? payload.features : [];
    const candidates = features
      .map((feature: Record<string, unknown>) => {
        const properties = isRecord(feature.properties)
          ? feature.properties
          : {};
        const geometry = isRecord(feature.geometry) ? feature.geometry : {};
        const coordinates = Array.isArray(geometry.coordinates)
          ? geometry.coordinates
          : [];
        const resultLatitude = Number(properties.lat ?? coordinates[1]);
        const resultLongitude = Number(properties.lon ?? coordinates[0]);
        const formattedAddress = optionalString(
          properties.formatted ??
            [properties.address_line1, properties.address_line2]
              .filter(Boolean)
              .join(", "),
        );

        return {
          provider: "geoapify",
          provider_place_id: optionalString(properties.place_id),
          name: optionalString(properties.name),
          formatted_address: formattedAddress,
          street: optionalString(properties.street),
          house_number: optionalString(properties.housenumber),
          postcode: optionalString(properties.postcode),
          city: optionalString(
            properties.city ?? properties.town ?? properties.village,
          ),
          country_code: optionalString(properties.country_code)?.toLowerCase(),
          latitude: resultLatitude,
          longitude: resultLongitude,
          distance_meters: Math.max(
            0,
            Math.round(Number(properties.distance ?? 0)),
          ),
          categories: Array.isArray(properties.categories)
            ? properties.categories.map(String)
            : [],
        };
      })
      .filter((entry: Record<string, unknown>) =>
        Boolean(
          entry.provider_place_id &&
            entry.name &&
            entry.formatted_address &&
            entry.country_code,
        ) &&
        Number.isFinite(entry.latitude) &&
        Number.isFinite(entry.longitude) &&
        Number.isFinite(entry.distance_meters)
      )
      .filter((entry: Record<string, unknown>) =>
        entry.country_code === countryCode
      )
      .sort(
        (left: Record<string, unknown>, right: Record<string, unknown>) =>
          Number(left.distance_meters) - Number(right.distance_meters),
      );

    const stores = [];
    for (const candidate of candidates) {
      const registered = await registerCanonicalStore(admin, candidate);
      if (registered) {
        stores.push({
          ...candidate,
          store_location_id: registered.id,
          name: registered.store_name,
        });
      }
    }

    return jsonResponse({ stores });
  } catch {
    return jsonResponse({ error: "Places provider request failed" }, 502);
  }
}

async function resolveProfileContext(
  request: Request,
): Promise<
  | { admin: SupabaseAdmin; countryCode: string }
  | { response: Response }
> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return {
      response: jsonResponse({ error: "Supabase is not configured" }, 503),
    };
  }

  const userId = userIdFromAuthorization(request.headers.get("Authorization"));
  if (!userId) {
    return {
      response: jsonResponse({ error: "Authentication required" }, 401),
    };
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await admin
    .from("profiles")
    .select("country_code")
    .eq("id", userId)
    .single();
  const countryCode = optionalString(data?.country_code)?.toLowerCase();
  if (error || !countryCode || !supportedStoreCountries.has(countryCode)) {
    return {
      response: jsonResponse({ error: "Complete your profile first" }, 403),
    };
  }

  return { admin, countryCode };
}

function userIdFromAuthorization(header: string | null): string | null {
  const token = header?.replace(/^Bearer\s+/i, "").trim();
  const payload = token?.split(".")[1];
  if (!payload) {
    return null;
  }

  try {
    const normalizedPayload = payload
      .replace(/-/g, "+")
      .replace(/_/g, "/")
      .padEnd(Math.ceil(payload.length / 4) * 4, "=");
    const claims = JSON.parse(atob(normalizedPayload));
    return optionalString(claims.sub);
  } catch {
    return null;
  }
}

async function registerCanonicalStore(
  admin: SupabaseAdmin,
  candidate: Record<string, unknown>,
): Promise<{ id: string; store_name: string } | null> {
  const storeName = trimTo(candidate.name, 100);
  const providerPlaceId = trimTo(candidate.provider_place_id, 512);
  const formattedAddress = trimTo(candidate.formatted_address, 500);
  const countryCode = trimTo(candidate.country_code, 2).toLowerCase();
  if (!storeName || !providerPlaceId || !formattedAddress || !countryCode) {
    return null;
  }

  const canonicalData = {
    provider: "geoapify",
    provider_place_id: providerPlaceId,
    store_name: storeName,
    store_name_normalized: normalizeStoreName(storeName),
    formatted_address: formattedAddress,
    street: nullableTrimTo(candidate.street, 200),
    house_number: nullableTrimTo(candidate.house_number, 50),
    postcode: nullableTrimTo(candidate.postcode, 50),
    city: nullableTrimTo(candidate.city, 200),
    country_code: countryCode,
    latitude: Number(candidate.latitude),
    longitude: Number(candidate.longitude),
  };
  const { data: existing, error: lookupError } = await admin
    .from("store_locations")
    .select("id,store_name_normalized")
    .eq("provider", "geoapify")
    .eq("provider_place_id", providerPlaceId)
    .order("updated_at", { ascending: false });

  if (lookupError) {
    console.error("Canonical store lookup failed", lookupError.code);
    return null;
  }

  const normalizedName = canonicalData.store_name_normalized;
  const preferred =
    existing?.find((entry) => entry.store_name_normalized === normalizedName) ??
    existing?.[0];
  const write = preferred
    ? admin
        .from("store_locations")
        .update(canonicalData)
        .eq("id", preferred.id)
    : admin.from("store_locations").insert(canonicalData);
  const { data, error } = await write.select("id,store_name").single();

  if (error || !data) {
    console.error("Canonical store registration failed", error?.code);
    return null;
  }
  return { id: String(data.id), store_name: String(data.store_name) };
}

function normalizeStoreName(value: string): string {
  return value.toLowerCase().replace(/\s+/g, " ").trim();
}

function trimTo(value: unknown, maxLength: number): string {
  return String(value ?? "").trim().slice(0, maxLength);
}

function nullableTrimTo(value: unknown, maxLength: number): string | null {
  return optionalString(trimTo(value, maxLength));
}

function optionalString(value: unknown): string | null {
  const result = String(value ?? "").trim();
  return result.length === 0 ? null : result;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
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
