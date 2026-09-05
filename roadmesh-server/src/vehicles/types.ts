// ─── Vehicle & Message Types ───────────────────────────────────────────────

export type VehicleType =
    | 'CAR'
    | 'TRUCK'
    | 'MOTORCYCLE'
    | 'BUS'
    | 'AMBULANCE'
    | 'AUTO_RICKSHAW'
    | 'BICYCLE'
    | 'PEDESTRIAN'
    | 'UNKNOWN';

export type RiskLevel = 'GREEN' | 'YELLOW' | 'RED';

export type AlertType =
    | 'HEAD_ON'
    | 'OVERTAKE'
    | 'BLIND_CORNER'
    | 'REAR_END'
    | 'LANE_MERGE'
    | 'WRONG_WAY'
    | 'STOPPED_VEHICLE'
    | 'EMERGENCY_VEHICLE'
    | 'VULNERABLE_ROAD_USER';

export type ConnectionSource = 'WS' | 'SIMULATOR';

export interface VehicleState {
    id: string;
    lat: number;
    lng: number;
    speed: number;       // km/h
    heading: number;     // degrees (0-360, 0=North)
    vehicleType: VehicleType;
    timestamp: number;   // Unix ms
    source?: ConnectionSource;
}

export interface CollisionAlert {
    vehicleId: string;
    riskLevel: RiskLevel;
    alertType: AlertType;
    timeToCollision: number;  // seconds
    distance: number;         // meters
    bearing: number;          // degrees from ego vehicle
}

// ─── WebSocket Message Protocol ────────────────────────────────────────────

export type MessageType =
    | 'POSITION_UPDATE'
    | 'NEARBY_VEHICLES'
    | 'COLLISION_WARNING'
    | 'HEARTBEAT'
    | 'REGISTER'
    | 'PING'
    | 'PONG'
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

export interface PingMessage extends BaseMessage {
    type: 'PING';
    payload: { clientTime: number };
}

export interface PongMessage extends BaseMessage {
    type: 'PONG';
    payload: { clientTime: number; serverTime: number };
}

export type RoadMeshMessage =
    | PositionUpdateMessage
    | NearbyVehiclesMessage
    | HeartbeatMessage
    | RegisterMessage
    | PingMessage
    | PongMessage;

// ─── Server Configuration ──────────────────────────────────────────────────

export interface ServerConfig {
    httpPort: number;
    nearbyRadiusMeters: number;
    positionUpdateIntervalMs: number;
    vehicleTimeoutMs: number;
    collisionPredictionHorizonSec: number;
    geohashPrecision: number;
    rateLimitWindowMs: number;
    rateLimitMax: number;
}

export const DEFAULT_CONFIG: ServerConfig = {
    httpPort: Number(process.env.HTTP_PORT) || 3000,
    nearbyRadiusMeters: Number(process.env.NEARBY_RADIUS_METERS) || 500,
    positionUpdateIntervalMs: 1000,
    vehicleTimeoutMs: Number(process.env.VEHICLE_TIMEOUT_MS) || 10000,
    collisionPredictionHorizonSec: Number(process.env.COLLISION_HORIZON_SEC) || 10,
    geohashPrecision: 6,
    rateLimitWindowMs: 60_000,
    rateLimitMax: 1000,
};
