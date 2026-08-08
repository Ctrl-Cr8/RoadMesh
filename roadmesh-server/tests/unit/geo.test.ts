// ─── Geo Utility Unit Tests ──────────────────────────────────────────────────

import { describe, it, expect } from 'vitest';
import {
    haversineDistance,
    calculateBearing,
    predictPosition,
    angleDifference,
    normalizeAngle,
    closestApproachTime,
    toRadians,
    toDegrees,
} from '../../src/utils/geo';

describe('haversineDistance', () => {
    it('returns 0 for identical points', () => {
        expect(haversineDistance(10.0, 76.0, 10.0, 76.0)).toBe(0);
    });

    it('calculates known distance accurately (Kochi area, ~1.1km)', () => {
        // Two points ~1km apart
        const dist = haversineDistance(10.0200, 76.3100, 10.0290, 76.3100);
        expect(dist).toBeGreaterThan(900);
        expect(dist).toBeLessThan(1100);
    });

    it('is commutative (A→B == B→A)', () => {
        const d1 = haversineDistance(10.0, 76.0, 10.01, 76.01);
        const d2 = haversineDistance(10.01, 76.01, 10.0, 76.0);
        expect(d1).toBeCloseTo(d2, 5);
    });

    it('handles anti-podal points without error', () => {
        const dist = haversineDistance(0, 0, 0, 180);
        expect(dist).toBeGreaterThan(18_000_000);
    });
});

describe('calculateBearing', () => {
    it('returns ~0° for due North', () => {
        const bearing = calculateBearing(10.0, 76.0, 10.1, 76.0);
        expect(bearing).toBeCloseTo(0, 0);
    });

    it('returns ~90° for due East', () => {
        const bearing = calculateBearing(10.0, 76.0, 10.0, 76.1);
        expect(bearing).toBeCloseTo(90, 0);
    });

    it('returns ~180° for due South', () => {
        const bearing = calculateBearing(10.1, 76.0, 10.0, 76.0);
        expect(bearing).toBeCloseTo(180, 0);
    });

    it('returns ~270° for due West', () => {
        const bearing = calculateBearing(10.0, 76.1, 10.0, 76.0);
        expect(bearing).toBeCloseTo(270, 0);
    });

    it('result is always in [0, 360)', () => {
        for (let i = 0; i < 10; i++) {
            const bearing = calculateBearing(
                Math.random() * 10,
                Math.random() * 10,
                Math.random() * 10,
                Math.random() * 10
            );
            expect(bearing).toBeGreaterThanOrEqual(0);
            expect(bearing).toBeLessThan(360);
        }
    });
});

describe('predictPosition', () => {
    it('returns original position when speed is 0', () => {
        const result = predictPosition(10.0, 76.0, 0, 90, 5);
        expect(result.lat).toBeCloseTo(10.0, 5);
        expect(result.lng).toBeCloseTo(76.0, 5);
    });

    it('moves north at 36 km/h for 10s → ~100m north', () => {
        // 36 km/h = 10 m/s; 10s = 100m
        const result = predictPosition(10.0, 76.0, 36, 0, 10);
        const dist = haversineDistance(10.0, 76.0, result.lat, result.lng);
        expect(dist).toBeCloseTo(100, 0);
        expect(result.lat).toBeGreaterThan(10.0); // should be north
    });

    it('moves east at 72 km/h for 5s → ~100m east', () => {
        const result = predictPosition(10.0, 76.0, 72, 90, 5);
        const dist = haversineDistance(10.0, 76.0, result.lat, result.lng);
        expect(dist).toBeCloseTo(100, 0);
        expect(result.lng).toBeGreaterThan(76.0); // should be east
    });
});

describe('angleDifference', () => {
    it('returns 0 for same angles', () => {
        expect(angleDifference(45, 45)).toBe(0);
    });

    it('returns 180 for opposite directions', () => {
        expect(angleDifference(0, 180)).toBe(180);
        expect(angleDifference(90, 270)).toBe(180);
    });

    it('wraps correctly (350 and 10 → 20)', () => {
        expect(angleDifference(350, 10)).toBeCloseTo(20, 5);
    });

    it('result is always in [0, 180]', () => {
        for (let i = 0; i < 20; i++) {
            const a = Math.random() * 360;
            const b = Math.random() * 360;
            const diff = angleDifference(a, b);
            expect(diff).toBeGreaterThanOrEqual(0);
            expect(diff).toBeLessThanOrEqual(180);
        }
    });
});

describe('normalizeAngle', () => {
    it('keeps values in [0, 360)', () => {
        expect(normalizeAngle(0)).toBe(0);
        expect(normalizeAngle(360)).toBe(0);
        expect(normalizeAngle(-90)).toBeCloseTo(270, 5);
        expect(normalizeAngle(450)).toBeCloseTo(90, 5);
    });
});

describe('closestApproachTime', () => {
    it('returns 0 or very small for head-on vehicles already at minimum separation', () => {
        // Two vehicles 10m apart, heading directly at each other at 60 km/h each
        const tca = closestApproachTime(
            10.0, 76.0, 60, 0,       // northbound
            10.0001, 76.0, 60, 180,  // southbound, ~11m away
            10
        );
        // TCA should be very small (already converging)
        expect(tca).toBeGreaterThanOrEqual(0);
        expect(tca).toBeLessThan(2);
    });

    it('returns a positive time for converging vehicles that have not met yet', () => {
        const tca = closestApproachTime(
            10.00, 76.0, 60, 0,  // northbound
            10.01, 76.0, 60, 180, // southbound, ~1.1km apart
            10
        );
        expect(tca).toBeGreaterThan(0);
    });

    it('returns horizonSec for parallel vehicles (no convergence)', () => {
        const horizon = 10;
        const tca = closestApproachTime(
            10.0, 76.0, 60, 90,   // eastbound
            10.001, 76.0, 60, 90, // also eastbound, parallel
            horizon
        );
        expect(tca).toBe(horizon);
    });
});

describe('toRadians / toDegrees', () => {
    it('converts 180° to π', () => {
        expect(toRadians(180)).toBeCloseTo(Math.PI, 10);
    });

    it('converts π to 180°', () => {
        expect(toDegrees(Math.PI)).toBeCloseTo(180, 10);
    });

    it('round-trips accurately', () => {
        expect(toDegrees(toRadians(45))).toBeCloseTo(45, 10);
    });
});
