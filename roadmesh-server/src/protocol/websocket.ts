// ─── WebSocket Protocol Handler ─────────────────────────────────────────────
//
// Handles mobile client connections via WebSocket.
// Each connected client sends POSITION_UPDATE, receives NEARBY_VEHICLES + alerts.

import { WebSocketServer, WebSocket } from 'ws';
import { IncomingMessage } from 'http';
import { v4 as uuidv4 } from 'uuid';
import { VehicleStore } from '../vehicles/store';
import { VehicleState, PositionUpdateMessage, NearbyVehiclesMessage } from '../vehicles/types';
import { predictCollisions } from '../collision/predictor';
import { createLogger } from '../utils/logger';

const log = createLogger('WebSocket');

interface ClientInfo {
    id: string;
    ws: WebSocket;
    lastUpdate: number;
}

export class WebSocketHandler {
    private wss: WebSocketServer | null = null;
    private clients: Map<string, ClientInfo> = new Map();
    private store: VehicleStore;

    constructor(store: VehicleStore) {
        this.store = store;
    }

    /**
     * Attach WebSocket handling to an HTTP server.
     */
    attach(server: import('http').Server): void {
        this.wss = new WebSocketServer({ server, path: '/ws' });

        this.wss.on('connection', (ws: WebSocket, req: IncomingMessage) => {
            this.handleConnection(ws, req);
        });

        log.info('WebSocket server attached on /ws');
    }

    /**
     * Handle a new WebSocket connection.
     */
    private handleConnection(ws: WebSocket, _req: IncomingMessage): void {
        const clientId = uuidv4();
        const client: ClientInfo = { id: clientId, ws, lastUpdate: Date.now() };
        this.clients.set(clientId, client);

        log.info(`Client connected: ${clientId}`);

        // Send registration confirmation
        this.send(ws, {
            type: 'REGISTER',
            timestamp: Date.now(),
            payload: { id: clientId, vehicleType: 'UNKNOWN' },
        });

        ws.on('message', (data: Buffer | string) => {
            try {
                const message = JSON.parse(data.toString());
                this.handleMessage(clientId, message);
            } catch (err) {
                log.error(`Invalid message from ${clientId}`, err);
            }
        });

        ws.on('close', () => {
            this.handleDisconnect(clientId);
        });

        ws.on('error', (err) => {
            log.error(`WebSocket error for ${clientId}`, err);
            this.handleDisconnect(clientId);
        });
    }

    /**
     * Handle an incoming message from a client.
     */
    private handleMessage(clientId: string, message: any): void {
        if (message.type === 'POSITION_UPDATE') {
            this.handlePositionUpdate(clientId, message as PositionUpdateMessage);
        } else if (message.type === 'HEARTBEAT') {
            const client = this.clients.get(clientId);
            if (client) client.lastUpdate = Date.now();
        }
    }

    /**
     * Process a position update:
     * 1. Update vehicle store
     * 2. Query nearby vehicles
     * 3. Run collision prediction
     * 4. Send response with nearby vehicles + alerts
     */
    private handlePositionUpdate(
        clientId: string,
        message: PositionUpdateMessage
    ): void {
        const { payload } = message;

        const vehicleState: VehicleState = {
            id: clientId,
            lat: payload.lat,
            lng: payload.lng,
            speed: payload.speed,
            heading: payload.heading,
            vehicleType: payload.vehicleType || 'CAR',
            timestamp: payload.timestamp || Date.now(),
        };

        // 1. Update store
        this.store.updateVehicle(vehicleState);

        // 2. Get nearby vehicles
        const nearbyVehicles = this.store.getNearbyVehicles(
            vehicleState.lat,
            vehicleState.lng,
            clientId
        );

        // 3. Run collision prediction
        const alerts = predictCollisions(vehicleState, nearbyVehicles);

        // 4. Send response
        const client = this.clients.get(clientId);
        if (client && client.ws.readyState === WebSocket.OPEN) {
            const response: NearbyVehiclesMessage = {
                type: 'NEARBY_VEHICLES',
                timestamp: Date.now(),
                payload: {
                    vehicles: nearbyVehicles,
                    alerts,
                },
            };
            this.send(client.ws, response);
        }
    }

    /**
     * Handle client disconnect.
     */
    private handleDisconnect(clientId: string): void {
        this.clients.delete(clientId);
        this.store.removeVehicle(clientId);
        log.info(`Client disconnected: ${clientId}`);
    }

    /**
     * Send a JSON message to a WebSocket client.
     */
    private send(ws: WebSocket, data: any): void {
        if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify(data));
        }
    }

    /**
     * Get the count of connected clients.
     */
    getClientCount(): number {
        return this.clients.size;
    }

    /**
     * Broadcast a message to all connected clients.
     */
    broadcast(data: any): void {
        const message = JSON.stringify(data);
        for (const client of this.clients.values()) {
            if (client.ws.readyState === WebSocket.OPEN) {
                client.ws.send(message);
            }
        }
    }
}
