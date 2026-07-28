// ─── Alert Message Formatting ───────────────────────────────────────────────

import { CollisionAlert, AlertType, RiskLevel } from '../vehicles/types';

/**
 * Human-readable descriptions for alert types.
 */
const ALERT_DESCRIPTIONS: Record<AlertType, string> = {
    HEAD_ON: 'Vehicle approaching head-on',
    OVERTAKE: 'Vehicle overtaking nearby',
    BLIND_CORNER: 'Vehicle approaching from blind corner',
    REAR_END: 'Vehicle approaching from behind',
    LANE_MERGE: 'Vehicle merging into your lane',
    WRONG_WAY: 'Wrong-way vehicle detected',
    STOPPED_VEHICLE: 'Stopped vehicle ahead',
    EMERGENCY_VEHICLE: 'Emergency vehicle approaching',
};

/**
 * Get a human-readable description for an alert.
 */
export function getAlertDescription(alert: CollisionAlert): string {
    const base = ALERT_DESCRIPTIONS[alert.alertType] || 'Vehicle nearby';
    const distance = `${alert.distance}m away`;
    const time = alert.timeToCollision > 0
        ? `${alert.timeToCollision}s to contact`
        : 'imminent';
    return `${base} — ${distance}, ${time}`;
}

/**
 * Get voice alert text (for TTS on mobile app).
 */
export function getVoiceAlert(alert: CollisionAlert): string | null {
    // Only voice alerts for YELLOW and RED
    if (alert.riskLevel === 'GREEN') return null;

    switch (alert.alertType) {
        case 'HEAD_ON':
            return alert.riskLevel === 'RED'
                ? 'Warning! Head-on collision imminent!'
                : 'Caution. Vehicle approaching head-on.';
        case 'OVERTAKE':
            return 'Caution. Vehicle overtaking nearby.';
        case 'BLIND_CORNER':
            return alert.riskLevel === 'RED'
                ? 'Warning! Vehicle approaching from blind corner!'
                : 'Caution. Vehicle around the corner.';
        case 'REAR_END':
            return 'Caution. Vehicle approaching from behind.';
        case 'LANE_MERGE':
            return 'Caution. Vehicle merging into your lane.';
        case 'WRONG_WAY':
            return 'Danger! Wrong-way vehicle approaching!';
        case 'STOPPED_VEHICLE':
            return 'Caution. Stopped vehicle ahead.';
        case 'EMERGENCY_VEHICLE':
            return 'Emergency vehicle approaching. Please yield.';
        default:
            return 'Caution. Vehicle nearby.';
    }
}

/**
 * Determine if this alert should trigger a buzzer (for IoT node).
 */
export function shouldBuzz(alert: CollisionAlert): boolean {
    return alert.riskLevel === 'RED';
}
