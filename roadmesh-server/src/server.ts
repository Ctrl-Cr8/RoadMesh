// ─── RoadMesh Server ────────────────────────────────────────────────────────
//
// Express HTTP server + WebSocket upgrade.
// High-performance, pure-software V2X architecture for mobile apps & simulators.

import express from 'express';
import cors from 'cors';
import http from 'http';
import path from 'path';
import fs from 'fs';
import rateLimit from 'express-rate-limit';
import { VehicleStore } from './vehicles/store';
import { WebSocketHandler } from './protocol/websocket';
import { ServerConfig, DEFAULT_CONFIG } from './vehicles/types';
import { createLogger } from './utils/logger';

const log = createLogger('Server');

export class RoadMeshServer {
    private app: express.Application;
    private httpServer: http.Server;
    private store: VehicleStore;
    private wsHandler: WebSocketHandler;
    private config: ServerConfig;

    // Prometheus-style counters
    private metrics = {
        positionUpdatesTotal: 0,
        alertsGeneratedTotal: 0,
        wsConnectsTotal: 0,
        validationErrorsTotal: 0,
        startedAt: Date.now(),
    };

    constructor(config: Partial<ServerConfig> = {}) {
        this.config = { ...DEFAULT_CONFIG, ...config };
        this.app = express();
        this.httpServer = http.createServer(this.app);

        // Shared vehicle store
        this.store = new VehicleStore(this.config);

        // WebSocket protocol handler
        this.wsHandler = new WebSocketHandler(this.store);

        this.setupMiddleware();
        this.setupRoutes();
    }

    /**
     * Configure Express middleware.
     */
    private setupMiddleware(): void {
        this.app.use(cors());
        this.app.use(express.json());

        // Rate limiting for REST API
        const limiter = rateLimit({
            windowMs: this.config.rateLimitWindowMs,
            max: this.config.rateLimitMax,
            standardHeaders: true,
            legacyHeaders: false,
            message: { error: 'Too many requests, please slow down.' },
        });
        this.app.use('/api', limiter);

        // Serve admin dashboard static files
        const candidatePaths = [
            path.join(__dirname, '../src/dashboard'),
            path.join(__dirname, 'dashboard'),
            path.join(__dirname, '../dashboard'),
        ];
        const dashboardDir = candidatePaths.find(p => fs.existsSync(p)) || candidatePaths[0];
        this.app.use('/dashboard', express.static(dashboardDir));
        this.app.get('/dashboard', (_req, res) => {
            res.sendFile(path.join(dashboardDir, 'index.html'));
        });
    }

    /**
     * Configure HTTP routes.
     */
    private setupRoutes(): void {
        // Health check
        this.app.get('/health', (_req, res) => {
            res.json({
                status: 'ok',
                uptime: process.uptime(),
                timestamp: Date.now(),
            });
        });

        // Server statistics
        this.app.get('/stats', (_req, res) => {
            const storeStats = this.store.getStats();
            res.json({
                ...storeStats,
                wsClients: this.wsHandler.getClientCount(),
                config: {
                    nearbyRadiusMeters: this.config.nearbyRadiusMeters,
                    vehicleTimeoutMs: this.config.vehicleTimeoutMs,
                    collisionPredictionHorizonSec: this.config.collisionPredictionHorizonSec,
                },
            });
        });

        // Prometheus-compatible metrics endpoint
        this.app.get('/metrics', (_req, res) => {
            const uptimeSec = (Date.now() - this.metrics.startedAt) / 1000;
            const storeStats = this.store.getStats();

            res.set('Content-Type', 'text/plain; version=0.0.4');
            res.send([
                `# HELP roadmesh_active_vehicles Number of currently active vehicles`,
                `# TYPE roadmesh_active_vehicles gauge`,
                `roadmesh_active_vehicles ${storeStats.totalVehicles}`,
                ``,
                `# HELP roadmesh_position_updates_total Total position updates received`,
                `# TYPE roadmesh_position_updates_total counter`,
                `roadmesh_position_updates_total ${this.metrics.positionUpdatesTotal}`,
                ``,
                `# HELP roadmesh_alerts_generated_total Total collision alerts generated`,
                `# TYPE roadmesh_alerts_generated_total counter`,
                `roadmesh_alerts_generated_total ${this.metrics.alertsGeneratedTotal}`,
                ``,
                `# HELP roadmesh_ws_connections_total Total WebSocket connections accepted`,
                `# TYPE roadmesh_ws_connections_total counter`,
                `roadmesh_ws_connections_total ${this.metrics.wsConnectsTotal}`,
                ``,
                `# HELP roadmesh_validation_errors_total Total message validation errors`,
                `# TYPE roadmesh_validation_errors_total counter`,
                `roadmesh_validation_errors_total ${this.metrics.validationErrorsTotal}`,
                ``,
                `# HELP roadmesh_uptime_seconds Server uptime in seconds`,
                `# TYPE roadmesh_uptime_seconds gauge`,
                `roadmesh_uptime_seconds ${uptimeSec.toFixed(2)}`,
            ].join('\n'));
        });

        // Get all vehicles (debug/admin endpoint)
        this.app.get('/vehicles', (_req, res) => {
            res.json({
                vehicles: this.store.getAllVehicles(),
                count: this.store.getStats().totalVehicles,
            });
        });

        // Root
        this.app.get('/', (_req, res) => {
            res.json({
                name: 'RoadMesh Server',
                version: '1.0.0',
                description: 'Smartphone-Based Cooperative Vehicle Awareness Platform',
                endpoints: {
                    health: '/health',
                    stats: '/stats',
                    metrics: '/metrics',
                    vehicles: '/vehicles',
                    websocket: '/ws',
                    dashboard: '/dashboard',
                },
            });
        });
    }

    /**
     * Increment a named metric counter.
     */
    incrementMetric(key: keyof Omit<typeof this.metrics, 'startedAt'>): void {
        (this.metrics[key] as number)++;
    }

    /**
     * Start the server.
     */
    start(): void {
        // Attach WebSocket handler to HTTP server
        this.wsHandler.attach(this.httpServer);

        // Start stale vehicle cleanup
        this.store.startCleanup();

        // Start HTTP server
        this.httpServer.listen(this.config.httpPort, () => {
            log.info(`
╔══════════════════════════════════════════════════════╗
║                                                      ║
║     🚗  RoadMesh Server v1.0.0                       ║
║     100% Smartphone-Based V2X Safety Platform        ║
║                                                      ║
║     HTTP/WS:    http://localhost:${this.config.httpPort}              ║
║     WebSocket:  ws://localhost:${this.config.httpPort}/ws             ║
║     Dashboard:  http://localhost:${this.config.httpPort}/dashboard    ║
║     Metrics:    http://localhost:${this.config.httpPort}/metrics      ║
║                                                      ║
║     Nearby radius: ${this.config.nearbyRadiusMeters}m                        ║
║     Collision horizon: ${this.config.collisionPredictionHorizonSec}s                      ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
      `);
        });
    }

    /**
     * Gracefully stop the server.
     */
    stop(): Promise<void> {
        return new Promise((resolve) => {
            log.info('Shutting down RoadMesh server...');
            this.store.stopCleanup();
            this.httpServer.close(() => {
                log.info('Server stopped cleanly.');
                resolve();
            });
        });
    }

    /**
     * Expose the Express app (for testing with supertest).
     */
    get expressApp(): express.Application {
        return this.app;
    }
}
