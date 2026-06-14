import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

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

    if (body.mode === "nearby_stores") {
      return searchNearbyStores(body, language, apiKey);
    }

    return searchAddresses(body, language, apiKey);
  } catch {
    return jsonResponse({ error: "Invalid request" }, 400);
  }
});

async function searchAddresses(
  body: Record<string, unknown>,
  language: string,
  apiKey: string,
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
    url.searchParams.set("bias", "countrycode:none");
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
    url.searchParams.set("categories", "commercial");
    url.searchParams.set("conditions", "named");
    url.searchParams.set("filter", `circle:${longitude},${latitude},500`);
    url.searchParams.set("bias", `proximity:${longitude},${latitude}`);
    url.searchParams.set("limit", "20");
    url.searchParams.set("lang", language || "en");
    url.searchParams.set("apiKey", apiKey);

    const geoapifyResponse = await fetch(url);
    if (!geoapifyResponse.ok) {
      return jsonResponse({ error: "Places provider request failed" }, 502);
    }

    const payload = await geoapifyResponse.json();
    const features = Array.isArray(payload.features) ? payload.features : [];
    const stores = features
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
      .sort(
        (left: Record<string, unknown>, right: Record<string, unknown>) =>
          Number(left.distance_meters) - Number(right.distance_meters),
      );

    return jsonResponse({ stores });
  } catch {
    return jsonResponse({ error: "Places provider request failed" }, 502);
  }
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
