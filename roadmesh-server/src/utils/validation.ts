// ─── Input Validation Schemas (Zod) ─────────────────────────────────────────
//
// Validates all incoming WebSocket messages before they enter the system.

import { z } from 'zod';

// ─── Primitives ─────────────────────────────────────────────────────────────

const VehicleTypeSchema = z.enum([
    'CAR', 'TRUCK', 'MOTORCYCLE', 'BUS', 'AMBULANCE',
    'AUTO_RICKSHAW', 'BICYCLE', 'PEDESTRIAN', 'UNKNOWN',
]);

const LatSchema = z.number().min(-90).max(90);
const LngSchema = z.number().min(-180).max(180);
const SpeedSchema = z.number().min(0).max(400);      // km/h, max reasonable
const HeadingSchema = z.number().min(0).max(360);
const TimestampSchema = z.number().int().positive();

// ─── Position Update Payload ─────────────────────────────────────────────────

export const PositionUpdatePayloadSchema = z.object({
    lat: LatSchema,
    lng: LngSchema,
    speed: SpeedSchema,
    heading: HeadingSchema,
    vehicleType: VehicleTypeSchema.optional().default('UNKNOWN'),
    timestamp: TimestampSchema.optional(),
});

export type PositionUpdatePayload = z.infer<typeof PositionUpdatePayloadSchema>;

// ─── Heartbeat Payload ───────────────────────────────────────────────────────

export const HeartbeatPayloadSchema = z.object({
    id: z.string().uuid(),
});

// ─── Ping Payload ────────────────────────────────────────────────────────────

export const PingPayloadSchema = z.object({
    clientTime: TimestampSchema,
});

// ─── Incoming Message ────────────────────────────────────────────────────────

export const IncomingMessageSchema = z.object({
    type: z.enum(['POSITION_UPDATE', 'HEARTBEAT', 'PING']),
    timestamp: TimestampSchema.optional(),
    payload: z.record(z.string(), z.unknown()),
});

