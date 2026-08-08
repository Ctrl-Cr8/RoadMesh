// ─── VehicleStore Unit Tests ──────────────────────────────────────────────────

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { VehicleStore } from '../../src/vehicles/store';
import { VehicleState } from '../../src/vehicles/types';

// ─── Helper ──────────────────────────────────────────────────────────────────

function makeVehicle(id: string, lat: number, lng: number, speed = 40): VehicleState {
    return {
        id,
        lat,
        lng,
        speed,
        heading: 0,
        vehicleType: 'CAR',
        timestamp: Date.now(),
    };
}

// ─── Tests ───────────────────────────────────────────────────────────────────

describe('VehicleStore — basic CRUD', () => {
    let store: VehicleStore;

    beforeEach(() => {
        store = new VehicleStore({ vehicleTimeoutMs: 5000 });
    });

    it('starts empty', () => {
        expect(store.getStats().totalVehicles).toBe(0);
        expect(store.getAllVehicles()).toHaveLength(0);
    });

    it('adds a vehicle', () => {
        store.updateVehicle(makeVehicle('v1', 10.0, 76.0));
        expect(store.getStats().totalVehicles).toBe(1);
    });

    it('retrieves a vehicle by ID', () => {
        store.updateVehicle(makeVehicle('v1', 10.0, 76.0));
        const v = store.getVehicle('v1');
        expect(v).toBeDefined();
        expect(v?.id).toBe('v1');
    });

    it('updates an existing vehicle', () => {
        store.updateVehicle(makeVehicle('v1', 10.0, 76.0));
        store.updateVehicle({ ...makeVehicle('v1', 10.1, 76.1), speed: 80 });

        const v = store.getVehicle('v1');
        expect(v?.lat).toBeCloseTo(10.1, 5);
        expect(v?.speed).toBe(80);
        expect(store.getStats().totalVehicles).toBe(1); // still only 1 vehicle
    });

    it('removes a vehicle', () => {
        store.updateVehicle(makeVehicle('v1', 10.0, 76.0));
        store.removeVehicle('v1');
        expect(store.getVehicle('v1')).toBeUndefined();
        expect(store.getStats().totalVehicles).toBe(0);
    });

    it('silently handles removing non-existent vehicle', () => {
        expect(() => store.removeVehicle('ghost')).not.toThrow();
    });
});

describe('VehicleStore — getNearbyVehicles', () => {
    let store: VehicleStore;

    beforeEach(() => {
        store = new VehicleStore({ nearbyRadiusMeters: 500 });
    });

    it('excludes the requesting vehicle itself', () => {
        const ego = makeVehicle('ego', 10.0, 76.0);
        store.updateVehicle(ego);
        const nearby = store.getNearbyVehicles(10.0, 76.0, 'ego');
        expect(nearby.every(v => v.id !== 'ego')).toBe(true);
    });

    it('finds vehicles within radius', () => {
        store.updateVehicle(makeVehicle('ego', 10.0000, 76.0000));
        store.updateVehicle(makeVehicle('near', 10.0010, 76.0000)); // ~111m
        store.updateVehicle(makeVehicle('far', 10.1000, 76.0000));  // ~11km

        const nearby = store.getNearbyVehicles(10.0, 76.0, 'ego');
        const ids = nearby.map(v => v.id);
        expect(ids).toContain('near');
        expect(ids).not.toContain('far');
    });

    it('returns empty when no vehicles in radius', () => {
        store.updateVehicle(makeVehicle('ego', 10.0, 76.0));
        store.updateVehicle(makeVehicle('far', 11.0, 76.0)); // ~110km

        const nearby = store.getNearbyVehicles(10.0, 76.0, 'ego');
        expect(nearby).toHaveLength(0);
    });
});

describe('VehicleStore — stale vehicle cleanup', () => {
    it('removes vehicles that have not updated within timeout', async () => {
        // Short timeout for test
        const store = new VehicleStore({ vehicleTimeoutMs: 100 });

        // Add a vehicle with an old timestamp
        const stale: VehicleState = {
            id: 'stale',
            lat: 10.0,
            lng: 76.0,
            speed: 0,
            heading: 0,
            vehicleType: 'CAR',
            timestamp: Date.now() - 1000, // 1 second old
        };
        store.updateVehicle(stale);
        expect(store.getStats().totalVehicles).toBe(1);

        // Start cleanup with very short interval
        store.startCleanup();

        // Wait for cleanup to run
        await new Promise(r => setTimeout(r, 250));
        store.stopCleanup();

        expect(store.getStats().totalVehicles).toBe(0);
    });
});

describe('VehicleStore — getAllVehicles', () => {
    it('returns all vehicles as an array', () => {
        const store = new VehicleStore();
        store.updateVehicle(makeVehicle('v1', 10.0, 76.0));
        store.updateVehicle(makeVehicle('v2', 10.1, 76.0));

        const all = store.getAllVehicles();
        expect(all).toHaveLength(2);
        expect(all.map(v => v.id)).toContain('v1');
        expect(all.map(v => v.id)).toContain('v2');
    });
});
