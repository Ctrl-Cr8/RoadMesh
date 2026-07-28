// ─── Vehicle State Store ────────────────────────────────────────────────────
//
// Central in-memory store for all connected vehicle states.
// Integrates with SpatialGrid for spatial queries and handles auto-expiry.

import { VehicleState, ServerConfig, DEFAULT_CONFIG } from './types';
import { SpatialGrid } from '../spatial/grid';
import { haversineDistance } from '../utils/geo';
import { createLogger } from '../utils/logger';

const log = createLogger('VehicleStore');

export class VehicleStore {
    private vehicles: Map<string, VehicleState> = new Map();
    private spatialGrid: SpatialGrid;
    private config: ServerConfig;
    private cleanupTimer: ReturnType<typeof setInterval> | null = null;

    constructor(config: Partial<ServerConfig> = {}) {
        this.config = { ...DEFAULT_CONFIG, ...config };
        this.spatialGrid = new SpatialGrid(this.config.geohashPrecision);
    }

    /**
     * Start the cleanup timer to remove stale vehicles.
     */
    startCleanup(): void {
        if (this.cleanupTimer) return;
        this.cleanupTimer = setInterval(() => {
            this.removeStaleVehicles();
        }, this.config.vehicleTimeoutMs);
        log.info('Stale vehicle cleanup started', {
            intervalMs: this.config.vehicleTimeoutMs,
        });
    }

    /**
     * Stop the cleanup timer.
     */
    stopCleanup(): void {
        if (this.cleanupTimer) {
            clearInterval(this.cleanupTimer);
            this.cleanupTimer = null;
        }
    }

    /**
     * Update or insert a vehicle's state.
     */
    updateVehicle(state: VehicleState): void {
        this.vehicles.set(state.id, state);
        this.spatialGrid.updateVehicle(state.id, state.lat, state.lng);
    }

    /**
     * Remove a vehicle from the store.
     */
    removeVehicle(vehicleId: string): void {
        this.vehicles.delete(vehicleId);
        this.spatialGrid.removeVehicle(vehicleId);
        log.debug(`Vehicle removed: ${vehicleId}`);
    }

    /**
     * Get a vehicle's current state.
     */
    getVehicle(vehicleId: string): VehicleState | undefined {
        return this.vehicles.get(vehicleId);
    }

    /**
     * Get all vehicles near a given position, excluding the requesting vehicle.
     * Filters by actual Haversine distance (geohash gives rough candidates).
     */
    getNearbyVehicles(
        lat: number,
        lng: number,
        excludeId: string,
        radiusMeters?: number
    ): VehicleState[] {
        const radius = radiusMeters ?? this.config.nearbyRadiusMeters;
        const candidateIds = this.spatialGrid.getNearbyVehicleIds(lat, lng);

        const nearby: VehicleState[] = [];
        for (const id of candidateIds) {
            if (id === excludeId) continue;
            const vehicle = this.vehicles.get(id);
            if (!vehicle) continue;

            const distance = haversineDistance(lat, lng, vehicle.lat, vehicle.lng);
            if (distance <= radius) {
                nearby.push(vehicle);
            }
        }

        return nearby;
    }

    /**
     * Remove vehicles that haven't sent an update within the timeout.
     */
    private removeStaleVehicles(): void {
        const now = Date.now();
        const staleIds: string[] = [];

        for (const [id, state] of this.vehicles) {
            if (now - state.timestamp > this.config.vehicleTimeoutMs) {
                staleIds.push(id);
            }
        }

        for (const id of staleIds) {
            this.removeVehicle(id);
        }

        if (staleIds.length > 0) {
            log.info(`Cleaned up ${staleIds.length} stale vehicles`);
        }
    }

    /**
     * Get store statistics.
     */
    getStats(): {
        totalVehicles: number;
        gridStats: { totalCells: number; totalVehicles: number };
    } {
        return {
            totalVehicles: this.vehicles.size,
            gridStats: this.spatialGrid.getStats(),
        };
    }

    /**
     * Get all vehicles (for debugging/admin).
     */
    getAllVehicles(): VehicleState[] {
        return Array.from(this.vehicles.values());
    }
}
