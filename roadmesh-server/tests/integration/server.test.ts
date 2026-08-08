// ─── Server Integration Tests ─────────────────────────────────────────────────

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { RoadMeshServer } from '../../src/server';

let server: RoadMeshServer;

beforeAll(() => {
    server = new RoadMeshServer({
        httpPort: 13001, // Use non-standard port to avoid conflicts
        mqttPort: 11883,
    });
    server.start();
});

afterAll(async () => {
    await server.stop();
});

describe('GET /', () => {
    it('returns server info with all endpoint keys', async () => {
        const res = await request(server.expressApp).get('/');
        expect(res.status).toBe(200);
        expect(res.body.name).toBe('RoadMesh Server');
        expect(res.body.endpoints).toHaveProperty('health');
        expect(res.body.endpoints).toHaveProperty('stats');
        expect(res.body.endpoints).toHaveProperty('metrics');
        expect(res.body.endpoints).toHaveProperty('websocket');
        expect(res.body.endpoints).toHaveProperty('dashboard');
        expect(res.body.mqtt).toHaveProperty('port');
    });
});

describe('GET /health', () => {
    it('returns 200 with status ok', async () => {
        const res = await request(server.expressApp).get('/health');
        expect(res.status).toBe(200);
        expect(res.body.status).toBe('ok');
    });

    it('includes uptime and timestamp', async () => {
        const res = await request(server.expressApp).get('/health');
        expect(res.body).toHaveProperty('uptime');
        expect(res.body).toHaveProperty('timestamp');
        expect(typeof res.body.uptime).toBe('number');
        expect(typeof res.body.timestamp).toBe('number');
    });
});

describe('GET /stats', () => {
    it('returns 200 with stats structure', async () => {
        const res = await request(server.expressApp).get('/stats');
        expect(res.status).toBe(200);
        expect(res.body).toHaveProperty('totalVehicles');
        expect(res.body).toHaveProperty('wsClients');
        expect(res.body).toHaveProperty('mqttClients');
        expect(res.body).toHaveProperty('config');
    });

    it('starts with 0 vehicles', async () => {
        const res = await request(server.expressApp).get('/stats');
        expect(res.body.totalVehicles).toBe(0);
    });
});

describe('GET /vehicles', () => {
    it('returns 200 with empty vehicle list initially', async () => {
        const res = await request(server.expressApp).get('/vehicles');
        expect(res.status).toBe(200);
        expect(res.body).toHaveProperty('vehicles');
        expect(res.body).toHaveProperty('count');
        expect(Array.isArray(res.body.vehicles)).toBe(true);
        expect(res.body.count).toBe(0);
    });
});

describe('GET /metrics', () => {
    it('returns 200 with prometheus text format', async () => {
        const res = await request(server.expressApp).get('/metrics');
        expect(res.status).toBe(200);
        expect(res.headers['content-type']).toContain('text/plain');
    });

    it('contains expected metric names', async () => {
        const res = await request(server.expressApp).get('/metrics');
        expect(res.text).toContain('roadmesh_active_vehicles');
        expect(res.text).toContain('roadmesh_position_updates_total');
        expect(res.text).toContain('roadmesh_uptime_seconds');
    });
});

describe('GET /nonexistent', () => {
    it('returns 404 for unknown routes', async () => {
        const res = await request(server.expressApp).get('/this-does-not-exist');
        expect(res.status).toBe(404);
    });
});
