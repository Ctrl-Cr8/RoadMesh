// ─── Spatial Grid Manager ───────────────────────────────────────────────────
//
// Maintains a mapping of geohash cells → vehicle IDs for efficient
// nearby-vehicle lookups. Instead of iterating all vehicles O(N),
// we only check vehicles in the same + neighboring cells O(K) where K << N.

import { encode, getCoveringCells } from './geohash';
import { createLogger } from '../utils/logger';

const log = createLogger('SpatialGrid');

export class SpatialGrid {
    // geohash → Set of vehicle IDs in that cell
    private grid: Map<string, Set<string>> = new Map();

    // vehicle ID → current geohash (for efficient removal on move)
    private vehicleCells: Map<string, string> = new Map();

    private precision: number;

    constructor(precision: number = 6) {
        this.precision = precision;
    }

    /**
     * Update a vehicle's position in the grid.
     * Removes from old cell if moved, adds to new cell.
     */
    updateVehicle(vehicleId: string, lat: number, lng: number): void {
        const newHash = encode(lat, lng, this.precision);
        const oldHash = this.vehicleCells.get(vehicleId);

        // If vehicle hasn't moved to a new cell, no grid update needed
        if (oldHash === newHash) return;

        // Remove from old cell
        if (oldHash) {
            const oldCell = this.grid.get(oldHash);
            if (oldCell) {
                oldCell.delete(vehicleId);
                if (oldCell.size === 0) {
                    this.grid.delete(oldHash);
                }
            }
        }

        // Add to new cell
        if (!this.grid.has(newHash)) {
            this.grid.set(newHash, new Set());
        }
        this.grid.get(newHash)!.add(vehicleId);
        this.vehicleCells.set(vehicleId, newHash);
    }

    /**
     * Remove a vehicle from the grid entirely.
     */
    removeVehicle(vehicleId: string): void {
        const hash = this.vehicleCells.get(vehicleId);
        if (hash) {
            const cell = this.grid.get(hash);
            if (cell) {
                cell.delete(vehicleId);
                if (cell.size === 0) {
                    this.grid.delete(hash);
                }
            }
            this.vehicleCells.delete(vehicleId);
        }
    }

    /**
     * Get all vehicle IDs near a given position.
     * Checks the center cell + all 8 neighboring cells.
     */
    getNearbyVehicleIds(lat: number, lng: number): string[] {
        const cells = getCoveringCells(lat, lng, 0, this.precision);
        const vehicleIds: string[] = [];

        for (const cellHash of cells) {
            const cell = this.grid.get(cellHash);
            if (cell) {
                for (const id of cell) {
                    vehicleIds.push(id);
                }
            }
        }

        return vehicleIds;
    }

    /**
     * Get statistics about the spatial grid.
     */
    getStats(): { totalCells: number; totalVehicles: number } {
        return {
            totalCells: this.grid.size,
            totalVehicles: this.vehicleCells.size,
        };
    }
}
