#!/usr/bin/env node
// ─── RoadMesh Vehicle Simulator ─────────────────────────────────────────────
//
// Simulates multiple vehicles moving along predefined routes.
// Connects to the RoadMesh server via WebSocket.
// Usage: node tools/simulator.js [--vehicles N] [--server ws://localhost:3000/ws]

const WebSocket = require('ws');

// ─── Configuration ─────────────────────────────────────────────────────────

const SERVER_URL = process.argv.find(a => a.startsWith('--server='))?.split('=')[1] || 'ws://localhost:3000/ws';
const NUM_VEHICLES = parseInt(process.argv.find(a => a.startsWith('--vehicles='))?.split('=')[1] || '4', 10);
const UPDATE_INTERVAL_MS = 1000;

// ─── Predefined Routes (Kochi area for demo) ──────────────────────────────

const SCENARIOS = {
    // Two vehicles approaching each other on a straight road
    headOn: [
        {
            name: 'Vehicle A (Northbound)',
            vehicleType: 'CAR',
            waypoints: [
                { lat: 10.0200, lng: 76.3100 },
                { lat: 10.0210, lng: 76.3100 },
                { lat: 10.0220, lng: 76.3100 },
                { lat: 10.0230, lng: 76.3100 },
                { lat: 10.0240, lng: 76.3100 },
                { lat: 10.0250, lng: 76.3100 },
            ],
            speed: 40,
        },
        {
            name: 'Vehicle B (Southbound)',
            vehicleType: 'CAR',
            waypoints: [
                { lat: 10.0250, lng: 76.3100 },
                { lat: 10.0240, lng: 76.3100 },
                { lat: 10.0230, lng: 76.3100 },
                { lat: 10.0220, lng: 76.3100 },
                { lat: 10.0210, lng: 76.3100 },
                { lat: 10.0200, lng: 76.3100 },
            ],
            speed: 45,
        },
    ],

    // Blind corner scenario
    blindCorner: [
        {
            name: 'Vehicle C (Eastbound)',
            vehicleType: 'TRUCK',
            waypoints: [
                { lat: 10.0300, lng: 76.3080 },
                { lat: 10.0300, lng: 76.3090 },
                { lat: 10.0300, lng: 76.3100 },
                { lat: 10.0300, lng: 76.3110 },
            ],
            speed: 35,
        },
        {
            name: 'Vehicle D (Southbound turning)',
            vehicleType: 'MOTORCYCLE',
            waypoints: [
                { lat: 10.0320, lng: 76.3100 },
                { lat: 10.0315, lng: 76.3100 },
                { lat: 10.0310, lng: 76.3100 },
                { lat: 10.0305, lng: 76.3100 },
                { lat: 10.0300, lng: 76.3100 },
            ],
            speed: 50,
        },
    ],

    // Overtaking scenario
    overtaking: [
        {
            name: 'Slow Truck',
            vehicleType: 'TRUCK',
            waypoints: [
                { lat: 10.0400, lng: 76.3100 },
                { lat: 10.0405, lng: 76.3100 },
                { lat: 10.0410, lng: 76.3100 },
                { lat: 10.0415, lng: 76.3100 },
                { lat: 10.0420, lng: 76.3100 },
                { lat: 10.0425, lng: 76.3100 },
                { lat: 10.0430, lng: 76.3100 },
            ],
            speed: 20,
        },
        {
            name: 'Fast Car (overtaking)',
            vehicleType: 'CAR',
            waypoints: [
                { lat: 10.0398, lng: 76.3099 },
                { lat: 10.0405, lng: 76.3098 },
                { lat: 10.0412, lng: 76.3098 },
                { lat: 10.0420, lng: 76.3099 },
                { lat: 10.0425, lng: 76.3100 },
                { lat: 10.0430, lng: 76.3100 },
                { lat: 10.0435, lng: 76.3100 },
            ],
            speed: 60,
        },
    ],

    // Emergency vehicle
    emergency: [
        {
            name: 'Regular Car',
            vehicleType: 'CAR',
            waypoints: [
                { lat: 10.0500, lng: 76.3100 },
                { lat: 10.0505, lng: 76.3100 },
                { lat: 10.0510, lng: 76.3100 },
                { lat: 10.0515, lng: 76.3100 },
                { lat: 10.0520, lng: 76.3100 },
            ],
            speed: 40,
        },
        {
            name: 'Ambulance',
            vehicleType: 'AMBULANCE',
            waypoints: [
                { lat: 10.0490, lng: 76.3100 },
                { lat: 10.0500, lng: 76.3100 },
                { lat: 10.0510, lng: 76.3100 },
                { lat: 10.0520, lng: 76.3100 },
                { lat: 10.0530, lng: 76.3100 },
            ],
            speed: 80,
        },
    ],
};

// ─── Simulator ─────────────────────────────────────────────────────────────

class VehicleSimulator {
    constructor(config) {
        this.name = config.name;
        this.vehicleType = config.vehicleType;
        this.waypoints = config.waypoints;
        this.speed = config.speed;
        this.waypointIndex = 0;
        this.ws = null;
        this.vehicleId = null;
        this.intervalId = null;
    }

    connect() {
        return new Promise((resolve, reject) => {
            this.ws = new WebSocket(SERVER_URL);

            this.ws.on('open', () => {
                console.log(`✅ ${this.name} connected`);
                resolve();
            });

            this.ws.on('message', (data) => {
                const msg = JSON.parse(data.toString());

                if (msg.type === 'REGISTER') {
                    this.vehicleId = msg.payload.id;
                    console.log(`🆔 ${this.name} registered as ${this.vehicleId.substring(0, 8)}...`);
                }

                if (msg.type === 'NEARBY_VEHICLES') {
                    const { vehicles, alerts } = msg.payload;
                    if (alerts.length > 0) {
                        for (const alert of alerts) {
                            const icon = alert.riskLevel === 'RED' ? '🔴' : '🟡';
                            console.log(
                                `${icon} ${this.name}: ${alert.alertType} — ${alert.distance}m away, ${alert.timeToCollision}s to collision`
                            );
                        }
                    }
                    if (vehicles.length > 0) {
                        console.log(`📍 ${this.name}: ${vehicles.length} nearby vehicle(s)`);
                    }
                }
            });

            this.ws.on('error', (err) => {
                console.error(`❌ ${this.name} error:`, err.message);
                reject(err);
            });

            this.ws.on('close', () => {
                console.log(`🔌 ${this.name} disconnected`);
                this.stop();
            });
        });
    }

    start() {
        this.intervalId = setInterval(() => {
            if (this.ws.readyState !== WebSocket.OPEN) return;

            const wp = this.waypoints[this.waypointIndex];
            const nextWp = this.waypoints[Math.min(this.waypointIndex + 1, this.waypoints.length - 1)];

            // Calculate heading from current to next waypoint
            const heading = calculateBearing(wp.lat, wp.lng, nextWp.lat, nextWp.lng);

            const message = {
                type: 'POSITION_UPDATE',
                timestamp: Date.now(),
                payload: {
                    lat: wp.lat,
                    lng: wp.lng,
                    speed: this.speed,
                    heading: heading,
                    vehicleType: this.vehicleType,
                    timestamp: Date.now(),
                },
            };

            this.ws.send(JSON.stringify(message));

            // Advance to next waypoint (loop back)
            this.waypointIndex = (this.waypointIndex + 1) % this.waypoints.length;
        }, UPDATE_INTERVAL_MS);
    }

    stop() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
        }
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.close();
        }
    }
}

// ─── Utility ───────────────────────────────────────────────────────────────

function calculateBearing(lat1, lng1, lat2, lng2) {
    const toRad = (d) => (d * Math.PI) / 180;
    const toDeg = (r) => (r * 180) / Math.PI;

    const φ1 = toRad(lat1);
    const φ2 = toRad(lat2);
    const Δλ = toRad(lng2 - lng1);

    const y = Math.sin(Δλ) * Math.cos(φ2);
    const x = Math.cos(φ1) * Math.sin(φ2) - Math.sin(φ1) * Math.cos(φ2) * Math.cos(Δλ);

    return ((toDeg(Math.atan2(y, x)) + 360) % 360);
}

// ─── Main ──────────────────────────────────────────────────────────────────

async function main() {
    console.log(`
╔══════════════════════════════════════════════════════╗
║     🚗  RoadMesh Vehicle Simulator                   ║
║     Server: ${SERVER_URL.padEnd(40)}║
╚══════════════════════════════════════════════════════╝
  `);

    // Collect all vehicles from all scenarios
    const allVehicles = [];
    for (const [scenarioName, vehicles] of Object.entries(SCENARIOS)) {
        console.log(`📋 Loading scenario: ${scenarioName}`);
        for (const config of vehicles) {
            allVehicles.push(config);
        }
    }

    // Limit to requested number
    const vehiclesToSimulate = allVehicles.slice(0, NUM_VEHICLES);

    console.log(`\n🏁 Starting ${vehiclesToSimulate.length} simulated vehicles...\n`);

    const simulators = vehiclesToSimulate.map((config) => new VehicleSimulator(config));

    // Connect all vehicles
    try {
        await Promise.all(simulators.map((sim) => sim.connect()));
    } catch (err) {
        console.error('Failed to connect simulators. Is the server running?');
        process.exit(1);
    }

    // Start all simulators
    simulators.forEach((sim) => sim.start());

    console.log('\n🟢 All vehicles running. Press Ctrl+C to stop.\n');

    // Graceful shutdown
    process.on('SIGINT', () => {
        console.log('\n🛑 Stopping simulators...');
        simulators.forEach((sim) => sim.stop());
        setTimeout(() => process.exit(0), 500);
    });
}

main().catch(console.error);
