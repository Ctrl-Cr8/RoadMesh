// ─── Geographic Utility Functions ──────────────────────────────────────────

const EARTH_RADIUS_METERS = 6_371_000;

/**
 * Convert degrees to radians.
 */
export function toRadians(degrees: number): number {
    return (degrees * Math.PI) / 180;
}

/**
 * Convert radians to degrees.
 */
export function toDegrees(radians: number): number {
    return (radians * 180) / Math.PI;
}

/**
 * Calculate the Haversine distance between two GPS coordinates.
 * @returns Distance in meters.
 */
export function haversineDistance(
    lat1: number,
    lng1: number,
    lat2: number,
    lng2: number
): number {
    const dLat = toRadians(lat2 - lat1);
    const dLng = toRadians(lng2 - lng1);

    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos(toRadians(lat1)) *
        Math.cos(toRadians(lat2)) *
        Math.sin(dLng / 2) ** 2;

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return EARTH_RADIUS_METERS * c;
}

/**
 * Calculate the initial bearing from point 1 to point 2.
 * @returns Bearing in degrees (0-360, 0 = North, 90 = East).
 */
export function calculateBearing(
    lat1: number,
    lng1: number,
    lat2: number,
    lng2: number
): number {
    const φ1 = toRadians(lat1);
    const φ2 = toRadians(lat2);
    const Δλ = toRadians(lng2 - lng1);

    const y = Math.sin(Δλ) * Math.cos(φ2);
    const x =
        Math.cos(φ1) * Math.sin(φ2) -
        Math.sin(φ1) * Math.cos(φ2) * Math.cos(Δλ);

    const bearing = toDegrees(Math.atan2(y, x));
    return (bearing + 360) % 360;
}

/**
 * Predict a future GPS position given current position, speed, and heading.
 * @param lat Current latitude
 * @param lng Current longitude
 * @param speedKmh Speed in km/h
 * @param heading Heading in degrees (0=North)
 * @param seconds Time horizon in seconds
 * @returns Predicted { lat, lng }
 */
export function predictPosition(
    lat: number,
    lng: number,
    speedKmh: number,
    heading: number,
    seconds: number
): { lat: number; lng: number } {
    const speedMs = (speedKmh * 1000) / 3600; // km/h → m/s
    const distanceMeters = speedMs * seconds;

    const δ = distanceMeters / EARTH_RADIUS_METERS; // angular distance
    const θ = toRadians(heading);
    const φ1 = toRadians(lat);
    const λ1 = toRadians(lng);

    const φ2 = Math.asin(
        Math.sin(φ1) * Math.cos(δ) + Math.cos(φ1) * Math.sin(δ) * Math.cos(θ)
    );
    const λ2 =
        λ1 +
        Math.atan2(
            Math.sin(θ) * Math.sin(δ) * Math.cos(φ1),
            Math.cos(δ) - Math.sin(φ1) * Math.sin(φ2)
        );

    return {
        lat: toDegrees(φ2),
        lng: toDegrees(λ2),
    };
}

/**
 * Normalize an angle to 0-360 range.
 */
export function normalizeAngle(angle: number): number {
    return ((angle % 360) + 360) % 360;
}

/**
 * Calculate the smallest angle difference between two headings.
 * @returns Angle difference in degrees (0-180).
 */
export function angleDifference(heading1: number, heading2: number): number {
    const diff = Math.abs(normalizeAngle(heading1) - normalizeAngle(heading2));
    return diff > 180 ? 360 - diff : diff;
}

/**
 * Calculate the time of closest approach (TCA) between two linearly-moving objects.
 * Uses dot product of relative velocity and relative position vectors.
 * @returns Seconds until closest approach (capped at horizonSec; 0 if already diverging)
 */
export function closestApproachTime(
    lat1: number, lng1: number, speedKmh1: number, heading1: number,
    lat2: number, lng2: number, speedKmh2: number, heading2: number,
    horizonSec: number = 10
): number {
    // Convert speeds to m/s
    const s1 = (speedKmh1 * 1000) / 3600;
    const s2 = (speedKmh2 * 1000) / 3600;

    // Velocity vectors (North-East frame, in m/s)
    const v1n = s1 * Math.cos(toRadians(heading1));
    const v1e = s1 * Math.sin(toRadians(heading1));
    const v2n = s2 * Math.cos(toRadians(heading2));
    const v2e = s2 * Math.sin(toRadians(heading2));

    // Relative velocity
    const dvn = v1n - v2n;
    const dve = v1e - v2e;

    // Relative position (approximate, in meters via lat/lng difference)
    const metersPerDegreeLat = (Math.PI / 180) * EARTH_RADIUS_METERS;
    const metersPerDegreeLng = metersPerDegreeLat * Math.cos(toRadians((lat1 + lat2) / 2));
    const dpn = (lat1 - lat2) * metersPerDegreeLat;
    const dpe = (lng1 - lng2) * metersPerDegreeLng;

    // TCA = -(dp · dv) / |dv|²
    const dvMagSq = dvn * dvn + dve * dve;
    if (dvMagSq < 1e-9) return horizonSec; // Vehicles moving in parallel

    const tca = -(dpn * dvn + dpe * dve) / dvMagSq;

    if (tca < 0) return 0; // Already at or past closest approach
    return Math.min(tca, horizonSec);
}
