// ─── Collision Predictor Unit Tests ──────────────────────────────────────────

import { describe, it, expect } from 'vitest';
import { predictCollisions } from '../../src/collision/predictor';
import { VehicleState } from '../../src/vehicles/types';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function makeVehicle(
    id: string,
    lat: number,
    lng: number,
    speed: number,
    heading: number,
    vehicleType: VehicleState['vehicleType'] = 'CAR'
): VehicleState {
    return {
        id,
        lat,
        lng,
        speed,
        heading,
        vehicleType,
        timestamp: Date.now(),
    };
}

// ─── Tests ───────────────────────────────────────────────────────────────────

describe('predictCollisions — no alert cases', () => {
    it('returns empty when no nearby vehicles', () => {
        const ego = makeVehicle('ego', 10.0, 76.0, 50, 0);
        expect(predictCollisions(ego, [])).toEqual([]);
    });

    it('returns empty when vehicles are far apart and diverging', () => {
        const ego = makeVehicle('ego', 10.000, 76.000, 50, 0);   // going North
        const other = makeVehicle('v2', 10.100, 76.000, 50, 0);  // also going North, far ahead
        const alerts = predictCollisions(ego, [other]);
        expect(alerts).toEqual([]);
    });

    it('returns empty for slow/stopped vehicles not in path', () => {
        const ego = makeVehicle('ego', 10.000, 76.000, 50, 90);  // going East
        const other = makeVehicle('v2', 10.010, 76.000, 0, 0);   // stopped, far N
        const alerts = predictCollisions(ego, [other]);
        expect(alerts).toEqual([]);
    });
});

describe('predictCollisions — HEAD_ON scenario', () => {
    it('generates a RED alert for head-on approaching vehicles', () => {
        // Two vehicles very close, heading toward each other
        const ego = makeVehicle('ego', 10.0000, 76.0000, 60, 0);   // going North
        const other = makeVehicle('v2', 10.0002, 76.0000, 60, 180); // going South
        // ~22m apart, converging at 120km/h

        const alerts = predictCollisions(ego, [other]);
        expect(alerts.length).toBeGreaterThan(0);

        const alert = alerts[0];
        expect(alert.vehicleId).toBe('v2');
        expect(alert.riskLevel).toBe('RED');
        expect(alert.alertType).toBe('HEAD_ON');
        expect(alert.timeToCollision).toBeLessThan(5);
    });
});

describe('predictCollisions — REAR_END scenario', () => {
    it('generates an alert for fast vehicle approaching slow vehicle from behind', () => {
        // Fast car right behind slow car, both going North
        const ego = makeVehicle('ego', 10.0000, 76.0000, 80, 0);   // fast, behind
        const other = makeVehicle('v2', 10.0002, 76.0000, 20, 0);  // slow, ahead

        const alerts = predictCollisions(ego, [other]);
        expect(alerts.length).toBeGreaterThan(0);
        expect(['REAR_END', 'STOPPED_VEHICLE']).toContain(alerts[0].alertType);
    });
});

describe('predictCollisions — EMERGENCY_VEHICLE', () => {
    it('always generates EMERGENCY_VEHICLE alert type for ambulances', () => {
        const ego = makeVehicle('ego', 10.0000, 76.0000, 40, 0);
        const ambulance = makeVehicle('amb', 10.0002, 76.0000, 80, 180, 'AMBULANCE');

        const alerts = predictCollisions(ego, [ambulance]);
        expect(alerts.length).toBeGreaterThan(0);
        expect(alerts[0].alertType).toBe('EMERGENCY_VEHICLE');
    });
});

describe('predictCollisions — alert sorting', () => {
    it('sorts RED alerts before YELLOW alerts', () => {
        const ego = makeVehicle('ego', 10.0000, 76.0000, 60, 0);

        // Very close head-on (RED)
        const danger = makeVehicle('danger', 10.0002, 76.0000, 60, 180);
        // Moderately close (might be YELLOW)
        const caution = makeVehicle('caution', 10.0005, 76.0000, 60, 180);

        const alerts = predictCollisions(ego, [danger, caution]);

        if (alerts.length >= 2) {
            const riskOrder: Record<string, number> = { RED: 0, YELLOW: 1, GREEN: 2 };
            for (let i = 0; i < alerts.length - 1; i++) {
                expect(riskOrder[alerts[i].riskLevel]).toBeLessThanOrEqual(
                    riskOrder[alerts[i + 1].riskLevel]
                );
            }
        }
    });
});

describe('predictCollisions — alert fields', () => {
    it('returns alerts with all required fields', () => {
        const ego = makeVehicle('ego', 10.0000, 76.0000, 60, 0);
        const other = makeVehicle('v2', 10.0002, 76.0000, 60, 180);

        const alerts = predictCollisions(ego, [other]);
        if (alerts.length > 0) {
            const alert = alerts[0];
            expect(alert).toHaveProperty('vehicleId');
            expect(alert).toHaveProperty('riskLevel');
            expect(alert).toHaveProperty('alertType');
            expect(alert).toHaveProperty('timeToCollision');
            expect(alert).toHaveProperty('distance');
            expect(alert).toHaveProperty('bearing');
            expect(alert.timeToCollision).toBeGreaterThanOrEqual(0);
            expect(alert.distance).toBeGreaterThanOrEqual(0);
            expect(alert.bearing).toBeGreaterThanOrEqual(0);
            expect(alert.bearing).toBeLessThan(360);
        }
    });
});
