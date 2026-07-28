// ─── RoadMesh Server Entry Point ────────────────────────────────────────────

import { RoadMeshServer } from './server';

const server = new RoadMeshServer({
    httpPort: parseInt(process.env.HTTP_PORT || '3000', 10),
    mqttPort: parseInt(process.env.MQTT_PORT || '1883', 10),
    nearbyRadiusMeters: parseInt(process.env.NEARBY_RADIUS || '500', 10),
    vehicleTimeoutMs: parseInt(process.env.VEHICLE_TIMEOUT || '10000', 10),
    collisionPredictionHorizonSec: parseInt(process.env.COLLISION_HORIZON || '10', 10),
});

// Graceful shutdown
process.on('SIGINT', () => {
    server.stop();
    process.exit(0);
});

process.on('SIGTERM', () => {
    server.stop();
    process.exit(0);
});

server.start();
