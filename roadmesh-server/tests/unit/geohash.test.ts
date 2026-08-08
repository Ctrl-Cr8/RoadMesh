// ─── Geohash Unit Tests ───────────────────────────────────────────────────────

import { describe, it, expect } from 'vitest';
import { encode, decode, getNeighborhood, getCoveringCells } from '../../src/spatial/geohash';

describe('encode / decode', () => {
    it('encodes a Kochi location to a 6-character hash', () => {
        const hash = encode(10.0261, 76.3125, 6);
        expect(hash).toHaveLength(6);
        expect(typeof hash).toBe('string');
    });

    it('encodes with default precision 6', () => {
        const hash = encode(10.0, 76.0);
        expect(hash).toHaveLength(6);
    });

    it('round-trips within cell error bounds', () => {
        const lat = 10.0261, lng = 76.3125;
        const hash = encode(lat, lng, 6);
        const { lat: dLat, lng: dLng } = decode(hash);
        // Precision 6 ≈ ±0.001° error
        expect(Math.abs(dLat - lat)).toBeLessThan(0.01);
        expect(Math.abs(dLng - lng)).toBeLessThan(0.01);
    });

    it('produces different hashes for different locations', () => {
        const h1 = encode(10.0, 76.0);
        const h2 = encode(10.1, 76.1);
        expect(h1).not.toBe(h2);
    });
});

describe('getNeighborhood', () => {
    it('returns 9 cells (center + 8 neighbors)', () => {
        const hash = encode(10.0, 76.0);
        const cells = getNeighborhood(hash);
        expect(cells).toHaveLength(9);
    });

    it('includes the original hash as the first element', () => {
        const hash = encode(10.0, 76.0);
        const cells = getNeighborhood(hash);
        expect(cells[0]).toBe(hash);
    });

    it('all cells are 6-character strings', () => {
        const hash = encode(10.0, 76.0);
        const cells = getNeighborhood(hash);
        cells.forEach(cell => {
            expect(cell).toHaveLength(6);
        });
    });

    it('all cells are unique', () => {
        const hash = encode(10.0, 76.0);
        const cells = getNeighborhood(hash);
        const unique = new Set(cells);
        expect(unique.size).toBe(9);
    });
});

describe('getCoveringCells', () => {
    it('returns 9 cells (neighborhood) for any radius', () => {
        const cells = getCoveringCells(10.0, 76.0, 500);
        expect(cells).toHaveLength(9);
    });

    it('includes the center cell', () => {
        const lat = 10.0261, lng = 76.3125;
        const centerHash = encode(lat, lng);
        const cells = getCoveringCells(lat, lng, 500);
        expect(cells).toContain(centerHash);
    });
});
