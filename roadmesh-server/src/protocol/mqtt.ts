// ─── MQTT Protocol Handler ──────────────────────────────────────────────────
//
// Embedded MQTT broker for ESP32 IoT nodes.
// Bridges MQTT messages into the same vehicle store as WebSocket clients.

import Aedes from 'aedes';
import { createServer, Server as NetServer } from 'net';
import { VehicleStore } from '../vehicles/store';
import { VehicleState } from '../vehicles/types';
import { predictCollisions } from '../collision/predictor';
import { createLogger } from '../utils/logger';

const log = createLogger('MQTT');

// MQTT Topic structure:
// Publish:   roadmesh/vehicles/{vehicleId}/position
// Subscribe: roadmesh/nearby/{vehicleId}

const POSITION_TOPIC_PREFIX = 'roadmesh/vehicles/';
const POSITION_TOPIC_SUFFIX = '/position';
const NEARBY_TOPIC_PREFIX = 'roadmesh/nearby/';

export class MqttHandler {
    private aedes: Aedes;
    private server: NetServer | null = null;
    private store: VehicleStore;
    private connectedClients: Set<string> = new Set();

    constructor(store: VehicleStore) {
        this.store = store;
        this.aedes = new Aedes();

        this.setupHandlers();
    }

    /**
     * Start the MQTT broker on the given port.
     */
    start(port: number): void {
        this.server = createServer(this.aedes.handle);
        this.server.listen(port, () => {
            log.info(`MQTT broker listening on port ${port}`);
        });
    }

    /**
     * Stop the MQTT broker.
     */
    stop(): void {
        if (this.server) {
            this.server.close();
        }
        this.aedes.close();
    }

    /**
     * Set up MQTT event handlers.
     */
    private setupHandlers(): void {
        this.aedes.on('client', (client) => {
            if (client.id) {
                this.connectedClients.add(client.id);
                log.info(`MQTT client connected: ${client.id}`);
            }
        });

        this.aedes.on('clientDisconnect', (client) => {
            if (client.id) {
                this.connectedClients.delete(client.id);
                this.store.removeVehicle(client.id);
                log.info(`MQTT client disconnected: ${client.id}`);
            }
        });

        this.aedes.on('publish', (packet, client) => {
            if (!client) return; // System messages, ignore

            const topic = packet.topic;

            // Handle position updates
            if (
                topic.startsWith(POSITION_TOPIC_PREFIX) &&
                topic.endsWith(POSITION_TOPIC_SUFFIX)
            ) {
                try {
                    const payload = JSON.parse(packet.payload.toString());
                    this.handlePositionUpdate(client.id, payload);
                } catch (err) {
                    log.error(`Invalid MQTT payload from ${client.id}`, err);
                }
            }
        });

        this.aedes.on('subscribe', (subscriptions, client) => {
            if (client) {
                log.debug(`${client.id} subscribed to:`, subscriptions.map((s) => s.topic));
            }
        });
    }

    /**
     * Process position update from an MQTT client (ESP32 node).
     */
    private handlePositionUpdate(clientId: string, payload: any): void {
        const vehicleState: VehicleState = {
            id: clientId,
            lat: payload.lat,
            lng: payload.lng,
            speed: payload.speed || 0,
            heading: payload.heading || 0,
            vehicleType: payload.vehicleType || 'CAR',
            timestamp: payload.timestamp || Date.now(),
        };

        // Update store
        this.store.updateVehicle(vehicleState);

        // Get nearby vehicles and run collision prediction
        const nearby = this.store.getNearbyVehicles(
            vehicleState.lat,
            vehicleState.lng,
            clientId
        );

        const alerts = predictCollisions(vehicleState, nearby);

        // Publish nearby info back to this client's topic
        const response = JSON.stringify({
            type: 'NEARBY_VEHICLES',
            timestamp: Date.now(),
            vehicles: nearby,
            alerts,
        });

        this.aedes.publish(
            {
                topic: `${NEARBY_TOPIC_PREFIX}${clientId}`,
                payload: Buffer.from(response),
                qos: 0,
                retain: false,
                cmd: 'publish',
                dup: false,
            },
            () => { }
        );
    }

    /**
     * Get count of connected MQTT clients.
     */
    getClientCount(): number {
        return this.connectedClients.size;
    }
}
