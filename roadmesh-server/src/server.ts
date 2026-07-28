// ─── RoadMesh Server ────────────────────────────────────────────────────────
//
// Express HTTP server + WebSocket upgrade + MQTT broker.
// All protocol handlers share a single VehicleStore.

import express from 'express';
import cors from 'cors';
import http from 'http';
import { VehicleStore } from './vehicles/store';
import { WebSocketHandler } from './protocol/websocket';
import { MqttHandler } from './protocol/mqtt';
import { ServerConfig, DEFAULT_CONFIG } from './vehicles/types';
import { createLogger } from './utils/logger';

const log = createLogger('Server');

export class RoadMeshServer {
    private app: express.Application;
    private httpServer: http.Server;
    private store: VehicleStore;
    private wsHandler: WebSocketHandler;
    private mqttHandler: MqttHandler;
    private config: ServerConfig;

    constructor(config: Partial<ServerConfig> = {}) {
        this.config = { ...DEFAULT_CONFIG, ...config };
        this.app = express();
        this.httpServer = http.createServer(this.app);

        // Shared vehicle store
        this.store = new VehicleStore(this.config);

        // Protocol handlers
        this.wsHandler = new WebSocketHandler(this.store);
        this.mqttHandler = new MqttHandler(this.store);

        this.setupMiddleware();
        this.setupRoutes();
    }

    /**
     * Configure Express middleware.
     */
    private setupMiddleware(): void {
        this.app.use(cors());
        this.app.use(express.json());
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
                mqttClients: this.mqttHandler.getClientCount(),
                config: {
                    nearbyRadiusMeters: this.config.nearbyRadiusMeters,
                    vehicleTimeoutMs: this.config.vehicleTimeoutMs,
                    collisionPredictionHorizonSec: this.config.collisionPredictionHorizonSec,
                },
            });
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
                description: 'Cooperative Vehicle Awareness Platform',
                endpoints: {
                    health: '/health',
                    stats: '/stats',
                    vehicles: '/vehicles',
                    websocket: '/ws',
                },
                mqtt: {
                    port: this.config.mqttPort,
                    topics: {
                        position: 'roadmesh/vehicles/{vehicleId}/position',
                        nearby: 'roadmesh/nearby/{vehicleId}',
                    },
                },
            });
        });
    }

    /**
     * Start the server.
     */
    start(): void {
        // Attach WebSocket handler to HTTP server
        this.wsHandler.attach(this.httpServer);

        // Start MQTT broker
        this.mqttHandler.start(this.config.mqttPort);

        // Start stale vehicle cleanup
        this.store.startCleanup();

        // Start HTTP server
        this.httpServer.listen(this.config.httpPort, () => {
            log.info(`
╔══════════════════════════════════════════════════════╗
║                                                      ║
║     🚗  RoadMesh Server v1.0.0                       ║
║     Cooperative Vehicle Awareness Platform            ║
║                                                      ║
║     HTTP/WS:  http://localhost:${this.config.httpPort}                ║
║     MQTT:     mqtt://localhost:${this.config.mqttPort}                ║
║     WebSocket: ws://localhost:${this.config.httpPort}/ws               ║
║                                                      ║
║     Nearby radius: ${this.config.nearbyRadiusMeters}m                         ║
║     Collision horizon: ${this.config.collisionPredictionHorizonSec}s                       ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
      `);
        });
    }

    /**
     * Gracefully stop the server.
     */
    stop(): void {
        log.info('Shutting down RoadMesh server...');
        this.store.stopCleanup();
        this.mqttHandler.stop();
        this.httpServer.close();
    }
}
