// ─── Collision Prediction Engine ────────────────────────────────────────────
//
// Projects vehicle trajectories forward in time and calculates
// minimum approach distances to detect potential collisions.

import {
    VehicleState,
    CollisionAlert,
    RiskLevel,
    AlertType,
    ServerConfig,
    DEFAULT_CONFIG,
} from '../vehicles/types';
import {
    haversineDistance,
    predictPosition,
    calculateBearing,
    angleDifference,
} from '../utils/geo';
import { createLogger } from '../utils/logger';

const log = createLogger('CollisionPredictor');

// ─── Thresholds ────────────────────────────────────────────────────────────

const RED_DISTANCE_METERS = 15;      // Immediate danger — cars nearly touching
const YELLOW_DISTANCE_METERS = 20;   // Close proximity warning zone
const MIN_SPEED_KMH = 5;            // Ignore nearly-stationary vehicles
const TIME_STEPS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]; // seconds to project

/**
 * Predict potential collisions between an ego vehicle and nearby vehicles.
 */
export function predictCollisions(
    ego: VehicleState,
    nearbyVehicles: VehicleState[],
    config: Partial<ServerConfig> = {}
): CollisionAlert[] {
    const alerts: CollisionAlert[] = [];
    const horizonSec =
        config.collisionPredictionHorizonSec ??
        DEFAULT_CONFIG.collisionPredictionHorizonSec;

    for (const other of nearbyVehicles) {
        const alert = analyzeVehiclePair(ego, other, horizonSec);
        if (alert) {
            alerts.push(alert);
        }
    }

    // Sort by risk level (RED first) then by time to collision
    alerts.sort((a, b) => {
        const riskOrder: Record<RiskLevel, number> = { RED: 0, YELLOW: 1, GREEN: 2 };
        const riskDiff = riskOrder[a.riskLevel] - riskOrder[b.riskLevel];
        if (riskDiff !== 0) return riskDiff;
        return a.timeToCollision - b.timeToCollision;
    });

    return alerts;
}

/**
 * Analyze a pair of vehicles for potential collision.
 */
function analyzeVehiclePair(
    ego: VehicleState,
    other: VehicleState,
    horizonSec: number
): CollisionAlert | null {
    const currentDistance = haversineDistance(ego.lat, ego.lng, other.lat, other.lng);
    const bearing = calculateBearing(ego.lat, ego.lng, other.lat, other.lng);

    // Find minimum projected distance across time steps
    let minDistance = currentDistance;
    let minTimeStep = 0;

    for (const t of TIME_STEPS) {
        if (t > horizonSec) break;

        const egoFuture = predictPosition(ego.lat, ego.lng, ego.speed, ego.heading, t);
        const otherFuture = predictPosition(
            other.lat,
            other.lng,
            other.speed,
            other.heading,
            t
        );

        const futureDistance = haversineDistance(
            egoFuture.lat,
            egoFuture.lng,
            otherFuture.lat,
            otherFuture.lng
        );

        if (futureDistance < minDistance) {
            minDistance = futureDistance;
            minTimeStep = t;
        }
    }

    // Determine risk level based on minimum projected distance
    let riskLevel: RiskLevel;
    if (minDistance < RED_DISTANCE_METERS) {
        riskLevel = 'RED';
    } else if (minDistance < YELLOW_DISTANCE_METERS) {
        riskLevel = 'YELLOW';
    } else {
        // No significant risk
        return null;
    }

    // Classify the alert type
    const alertType = classifyAlert(ego, other, bearing);

    return {
        vehicleId: other.id,
        riskLevel,
        alertType,
        timeToCollision: minTimeStep,
        distance: Math.round(currentDistance),
        bearing: Math.round(bearing),
    };
}

/**
 * Classify the type of collision scenario based on relative positions
 * and headings of two vehicles.
 */
function classifyAlert(
    ego: VehicleState,
    other: VehicleState,
    bearing: number
): AlertType {
    const headingDiff = angleDifference(ego.heading, other.heading);
    const bearingDiff = angleDifference(ego.heading, bearing);

    // Emergency vehicle detection
    if (other.vehicleType === 'AMBULANCE') {
        return 'EMERGENCY_VEHICLE';
    }

    // Stopped vehicle ahead
    if (other.speed < MIN_SPEED_KMH && bearingDiff < 30) {
        return 'STOPPED_VEHICLE';
    }

    // Head-on: vehicles facing each other (heading diff ~180°) and approaching
    if (headingDiff > 140 && bearingDiff < 45) {
        return 'HEAD_ON';
    }

    // Wrong way: vehicle heading opposite on the same road
    if (headingDiff > 150 && bearingDiff < 20) {
        return 'WRONG_WAY';
    }

    // Rear-end: same heading, other vehicle is ahead
    if (headingDiff < 30 && bearingDiff < 20) {
        return 'REAR_END';
    }

    // Overtake: similar heading but offset laterally
    if (headingDiff < 40 && bearingDiff > 10 && bearingDiff < 60) {
        return 'OVERTAKE';
    }

    // Lane merge: moderate heading difference, converging paths
    if (headingDiff > 20 && headingDiff < 90) {
        return 'LANE_MERGE';
    }

    // Blind corner: large bearing difference with moderate heading difference
    if (bearingDiff > 60 && bearingDiff < 150) {
        return 'BLIND_CORNER';
    }

    return 'BLIND_CORNER'; // Default fallback
}
