// City-level geocoding (§1: city granularity ONLY — never street or precise
// coordinates). We map a "City, Country" string to that city's CENTROID, which
// is all the Hall of Flags map ever needs. Coordinates here are deliberately
// coarse city centers, not member locations.
//
// A small built-in table keeps the app fully offline and deterministic; unknown
// cities still work everywhere else (directory, profile) — they just don't get a
// map pin until added here or resolved by an optional geocoder.

export interface Centroid {
  lat: number;
  lng: number;
}

const TABLE: Record<string, Centroid> = {
  "moscow|russia": { lat: 55.7558, lng: 37.6173 },
  "london|united kingdom": { lat: 51.5074, lng: -0.1278 },
  "new york|united states": { lat: 40.7128, lng: -74.006 },
  "san francisco|united states": { lat: 37.7749, lng: -122.4194 },
  "boston|united states": { lat: 42.3601, lng: -71.0589 },
  "washington|united states": { lat: 38.9072, lng: -77.0369 },
  "toronto|canada": { lat: 43.6532, lng: -79.3832 },
  "dubai|united arab emirates": { lat: 25.2048, lng: 55.2708 },
  "berlin|germany": { lat: 52.52, lng: 13.405 },
  "amsterdam|netherlands": { lat: 52.3676, lng: 4.9041 },
  "paris|france": { lat: 48.8566, lng: 2.3522 },
  "geneva|switzerland": { lat: 46.2044, lng: 6.1432 },
  "singapore|singapore": { lat: 1.3521, lng: 103.8198 },
  "tokyo|japan": { lat: 35.6762, lng: 139.6503 },
  "sydney|australia": { lat: -33.8688, lng: 151.2093 },
  "istanbul|turkey": { lat: 41.0082, lng: 28.9784 },
  "tbilisi|georgia": { lat: 41.7151, lng: 44.8271 },
  "yerevan|armenia": { lat: 40.1792, lng: 44.4991 },
  "almaty|kazakhstan": { lat: 43.222, lng: 76.8512 },
  "vienna|austria": { lat: 48.2082, lng: 16.3738 },
};

function key(city: string, country: string): string {
  return `${city.trim().toLowerCase()}|${country.trim().toLowerCase()}`;
}

// Resolve a city centroid. Returns null when the city is unknown — callers
// store null lat/lng and the member simply has no map pin (still fully usable).
export function cityCentroid(city: string, country: string): Centroid | null {
  return TABLE[key(city, country)] ?? null;
}
