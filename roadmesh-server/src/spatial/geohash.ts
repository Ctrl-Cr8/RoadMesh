// ─── Geohash Spatial Indexing ───────────────────────────────────────────────
//
// Geohashes divide the Earth into a grid of cells. At precision 6, each cell
// is roughly 1.2km × 0.6km — perfect for our ~500m nearby radius.

// eslint-disable-next-line @typescript-eslint/no-var-requires
const ngeohash = require('ngeohash');

/**
 * Encode latitude/longitude into a geohash string.
 */
export function encode(lat: number, lng: number, precision: number = 6): string {
    return ngeohash.encode(lat, lng, precision);
}

/**
 * Decode a geohash string back to lat/lng.
 */
export function decode(hash: string): { lat: number; lng: number } {
    const { latitude, longitude } = ngeohash.decode(hash);
    return { lat: latitude, lng: longitude };
}

/**
 * Get the 8 neighboring geohash cells plus the cell itself.
 * This ensures we find vehicles near cell boundaries.
 */
export function getNeighborhood(hash: string): string[] {
    const neighbors = ngeohash.neighbors(hash);
    return [hash, ...neighbors];
}

/**
 * Get all geohash cells that a circle (center + radius) might overlap.
 * For our use case, the neighborhood of the center cell is usually sufficient.
 */
export function getCoveringCells(
    lat: number,
    lng: number,
    _radiusMeters: number,
    precision: number = 6
): string[] {
    const centerHash = encode(lat, lng, precision);
    return getNeighborhood(centerHash);
}
