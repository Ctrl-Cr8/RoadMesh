// ─── Vehicle & Message Types ───────────────────────────────────────────────

export type VehicleType = 'CAR' | 'TRUCK' | 'MOTORCYCLE' | 'BUS' | 'AMBULANCE' | 'UNKNOWN';

export type RiskLevel = 'GREEN' | 'YELLOW' | 'RED';

export type AlertType =
    | 'HEAD_ON'
    | 'OVERTAKE'
    | 'BLIND_CORNER'
    | 'REAR_END'
    | 'LANE_MERGE'
    | 'WRONG_WAY'
    | 'STOPPED_VEHICLE'
    | 'EMERGENCY_VEHICLE';

export interface VehicleState {
    id: string;
    lat: number;
    lng: number;
    speed: number;       // km/h
    heading: number;     // degrees (0-360, 0=North)
    vehicleType: VehicleType;
    timestamp: number;   // Unix ms
}

export interface CollisionAlert {
    vehicleId: string;
    riskLevel: RiskLevel;
    alertType: AlertType;
    timeToCollision: number;  // seconds
    distance: number;         // meters
    bearing: number;          // degrees from ego vehicle
}

// ─── WebSocket / MQTT Message Protocol ─────────────────────────────────────

export type MessageType =
    | 'POSITION_UPDATE'
    | 'NEARBY_VEHICLES'
    | 'COLLISION_WARNING'
    | 'HEARTBEAT'
    | 'REGISTER'
    | 'DISCONNECT';

export interface BaseMessage {
    type: MessageType;
    timestamp: number;
}

export interface PositionUpdateMessage extends BaseMessage {
    type: 'POSITION_UPDATE';
    payload: Omit<VehicleState, 'id'> & { id?: string };
}

export interface NearbyVehiclesMessage extends BaseMessage {
    type: 'NEARBY_VEHICLES';
    payload: {
        vehicles: VehicleState[];
        alerts: CollisionAlert[];
    };
}

export interface HeartbeatMessage extends BaseMessage {
    type: 'HEARTBEAT';
    payload: { id: string };
}

export interface RegisterMessage extends BaseMessage {
    type: 'REGISTER';
    payload: {
        id: string;
        vehicleType: VehicleType;
    };
}

export type RoadMeshMessage =
    | PositionUpdateMessage
    | NearbyVehiclesMessage
    | HeartbeatMessage
    | RegisterMessage;

// ─── Server Configuration ──────────────────────────────────────────────────

export interface ServerConfig {
    httpPort: number;
    mqttPort: number;
    nearbyRadiusMeters: number;
    positionUpdateIntervalMs: number;
    vehicleTimeoutMs: number;
    collisionPredictionHorizonSec: number;
    geohashPrecision: number;
}

export const DEFAULT_CONFIG: ServerConfig = {
    httpPort: 3000,
    mqttPort: 1883,
    nearbyRadiusMeters: 500,
    positionUpdateIntervalMs: 1000,
    vehicleTimeoutMs: 10000,
    collisionPredictionHorizonSec: 10,
    geohashPrecision: 6,
};
