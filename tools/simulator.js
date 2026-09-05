#!/usr/bin/env node
// ─── RoadMesh Vehicle Simulator ─────────────────────────────────────────────
//
// Simulates multiple vehicles moving along predefined routes.
// Connects to the RoadMesh server via WebSocket.
// Usage: node tools/simulator.js [--scenario=name] [--server=ws://localhost:3000/ws] [--speed=1.0]

const WebSocket = require('ws');

// ─── CLI Args ───────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const SERVER_URL = args.find(a => a.startsWith('--server='))?.split('=')[1] || 'ws://localhost:3000/ws';
const SCENARIO_NAME = args.find(a => a.startsWith('--scenario='))?.split('=')[1] || 'all';
const SPEED_MULT = parseFloat(args.find(a => a.startsWith('--speed='))?.split('=')[1] || '1.0');
const UPDATE_INTERVAL_MS = 1000;

// ─── Predefined Scenarios (Kochi area for demo) ──────────────────────────────

const SCENARIOS = {
    kothamangalamTraffic: [
        {
            name: 'Auto Rickshaw (Kozhippilly Rd)',
            vehicleType: 'AUTO_RICKSHAW',
            waypoints: [
                { lat: 10.0520, lng: 76.6180 },
                { lat: 10.0532, lng: 76.6188 },
                { lat: 10.0544, lng: 76.6198 },
                { lat: 10.0556, lng: 76.6208 },
            ],
            speed: 34,
        },
        {
            name: 'Pulsar 220 (MA College Rd)',
            vehicleType: 'MOTORCYCLE',
            waypoints: [
                { lat: 10.0558, lng: 76.6202 },
                { lat: 10.0545, lng: 76.6195 },
                { lat: 10.0532, lng: 76.6186 },
                { lat: 10.0520, lng: 76.6178 },
            ],
            speed: 48,
        },
        {
            name: 'Swift Dzire Taxi',
            vehicleType: 'CAR',
            waypoints: [
                { lat: 10.0515, lng: 76.6190 },
                { lat: 10.0530, lng: 76.6192 },
                { lat: 10.0545, lng: 76.6196 },
                { lat: 10.0558, lng: 76.6200 },
            ],
            speed: 42,
        },
        {
            name: 'KSRTC Swift Bus',
            vehicleType: 'BUS',
            waypoints: [
                { lat: 10.0510, lng: 76.6175 },
                { lat: 10.0530, lng: 76.6188 },
                { lat: 10.0550, lng: 76.6202 },
                { lat: 10.0570, lng: 76.6215 },
            ],
            speed: 38,
        },
        {
            name: 'EMS Kerala Ambulance',
            vehicleType: 'AMBULANCE',
            waypoints: [
                { lat: 10.0505, lng: 76.6168 },
                { lat: 10.0535, lng: 76.6190 },
                { lat: 10.0565, lng: 76.6212 },
            ],
            speed: 75,
        },
        {
            name: 'Campus Crossing Pedestrian',
            vehicleType: 'PEDESTRIAN',
            waypoints: [
                { lat: 10.0538, lng: 76.6190 },
                { lat: 10.0538, lng: 76.6198 },
            ],
            speed: 4,
        },
    ],
    kochiIndianTraffic: [
        {
            name: 'Auto Rickshaw (3-Wheeler)',
            vehicleType: 'AUTO_RICKSHAW',
            waypoints: [
                { lat: 10.0210, lng: 76.3115 },
                { lat: 10.0235, lng: 76.3118 },
                { lat: 10.0260, lng: 76.3122 },
                { lat: 10.0285, lng: 76.3120 },
            ],
            speed: 36,
        },
        {
            name: 'Pulsar 220 (Two-Wheeler)',
            vehicleType: 'MOTORCYCLE',
            waypoints: [
                { lat: 10.0280, lng: 76.3130 },
                { lat: 10.0255, lng: 76.3122 },
                { lat: 10.0230, lng: 76.3115 },
            ],
            speed: 52,
        },
        {
            name: 'KSRTC Swift Bus',
            vehicleType: 'BUS',
            waypoints: [
                { lat: 10.0200, lng: 76.3110 },
                { lat: 10.0245, lng: 76.3118 },
                { lat: 10.0290, lng: 76.3125 },
            ],
            speed: 42,
        },
        {
            name: 'EMS Kerala Ambulance',
            vehicleType: 'AMBULANCE',
            waypoints: [
                { lat: 10.0180, lng: 76.3110 },
                { lat: 10.0230, lng: 76.3115 },
                { lat: 10.0280, lng: 76.3120 },
            ],
            speed: 80,
        },
        {
            name: 'Heavy Freight Truck',
            vehicleType: 'TRUCK',
            waypoints: [
                { lat: 10.0270, lng: 76.3105 },
                { lat: 10.0250, lng: 76.3110 },
                { lat: 10.0220, lng: 76.3115 },
            ],
            speed: 32,
        },
        {
            name: 'School Crossing Pedestrian',
            vehicleType: 'PEDESTRIAN',
            waypoints: [
                { lat: 10.0261, lng: 76.3120 },
                { lat: 10.0261, lng: 76.3130 },
            ],
            speed: 4,
        },
    ],
    headOn: [
        {
            name: 'Vehicle A (Northbound)',
            vehicleType: 'CAR',
            waypoints: [
                { lat: 10.0200, lng: 76.3100 },
                { lat: 10.0220, lng: 76.3100 },
                { lat: 10.0240, lng: 76.3100 },
                { lat: 10.0260, lng: 76.3100 },
            ],
            speed: 50,
        },
        {
            name: 'Vehicle B (Southbound)',
            vehicleType: 'CAR',
            waypoints: [
                { lat: 10.0260, lng: 76.3100 },
                { lat: 10.0240, lng: 76.3100 },
                { lat: 10.0220, lng: 76.3100 },
                { lat: 10.0200, lng: 76.3100 },
            ],
            speed: 50,
        },
    ],

    blindCorner: [
        {
            name: 'Truck C (Eastbound)',
            vehicleType: 'TRUCK',
            waypoints: [
                { lat: 10.0300, lng: 76.3080 },
                { lat: 10.0300, lng: 76.3095 },
                { lat: 10.0300, lng: 76.3110 },
            ],
            speed: 35,
        },
        {
            name: 'Bike D (Southbound turning)',
            vehicleType: 'MOTORCYCLE',
            waypoints: [
                { lat: 10.0320, lng: 76.3095 },
                { lat: 10.0310, lng: 76.3095 },
                { lat: 10.0300, lng: 76.3095 },
            ],
            speed: 55,
        },
    ],

    overtaking: [
        {
            name: 'Slow Truck',
            vehicleType: 'TRUCK',
            waypoints: [
                { lat: 10.0400, lng: 76.3100 },
                { lat: 10.0410, lng: 76.3100 },
                { lat: 10.0420, lng: 76.3100 },
                { lat: 10.0430, lng: 76.3100 },
            ],
            speed: 25,
        },
        {
            name: 'Fast Car (overtaking)',
            vehicleType: 'CAR',
            waypoints: [
                { lat: 10.0395, lng: 76.3099 },
                { lat: 10.0410, lng: 76.3098 },
                { lat: 10.0425, lng: 76.3100 },
                { lat: 10.0435, lng: 76.3100 },
            ],
            speed: 65,
        },
    ],

    emergency: [
        {
            name: 'Commuter Car',
            vehicleType: 'CAR',
            waypoints: [
                { lat: 10.0500, lng: 76.3100 },
                { lat: 10.0510, lng: 76.3100 },
                { lat: 10.0520, lng: 76.3100 },
            ],
            speed: 40,
        },
        {
            name: 'Ambulance (High Speed)',
            vehicleType: 'AMBULANCE',
            waypoints: [
                { lat: 10.0480, lng: 76.3100 },
                { lat: 10.0500, lng: 76.3100 },
                { lat: 10.0520, lng: 76.3100 },
            ],
            speed: 85,
        },
    ],

    intersection: [
        {
            name: 'North Approach',
            vehicleType: 'CAR',
            waypoints: [
                { lat: 10.0620, lng: 76.3100 },
                { lat: 10.0600, lng: 76.3100 },
            ],
            speed: 50,
        },
        {
            name: 'East Approach',
            vehicleType: 'BUS',
            waypoints: [
                { lat: 10.0600, lng: 76.3120 },
                { lat: 10.0600, lng: 76.3100 },
            ],
            speed: 40,
        },
        {
            name: 'South Approach',
            vehicleType: 'MOTORCYCLE',
            waypoints: [
                { lat: 10.0580, lng: 76.3100 },
                { lat: 10.0600, lng: 76.3100 },
            ],
            speed: 60,
        },
        {
            name: 'West Approach',
            vehicleType: 'CAR',
            waypoints: [
                { lat: 10.0600, lng: 76.3080 },
                { lat: 10.0600, lng: 76.3100 },
            ],
            speed: 45,
        },
    ],

    schoolZone: [
        {
            name: 'School Bus',
            vehicleType: 'BUS',
            waypoints: [
                { lat: 10.0700, lng: 76.3100 },
                { lat: 10.0710, lng: 76.3100 },
            ],
            speed: 20,
        },
        {
            name: 'Pedestrian A',
            vehicleType: 'PEDESTRIAN',
            waypoints: [
                { lat: 10.0708, lng: 76.3095 },
                { lat: 10.0708, lng: 76.3105 },
            ],
            speed: 5,
        },
        {
            name: 'Bicycle Rider',
            vehicleType: 'BICYCLE',
            waypoints: [
                { lat: 10.0700, lng: 76.3102 },
                { lat: 10.0715, lng: 76.3102 },
            ],
            speed: 15,
        },
    ],

    highwayMerge: [
        {
            name: 'Highway Traffic A',
            vehicleType: 'TRUCK',
            waypoints: [
                { lat: 10.0800, lng: 76.3100 },
                { lat: 10.0830, lng: 76.3100 },
            ],
            speed: 80,
        },
        {
            name: 'Merging Car B',
            vehicleType: 'CAR',
            waypoints: [
                { lat: 10.0805, lng: 76.3090 },
                { lat: 10.0820, lng: 76.3100 },
            ],
            speed: 75,
        },
    ],
};

// ─── Simulator Class ─────────────────────────────────────────────────────────

class VehicleSimulator {
    constructor(config) {
        this.name = config.name;
        this.vehicleType = config.vehicleType;
        this.waypoints = config.waypoints;
        this.baseSpeed = config.speed;
        this.speed = config.speed * SPEED_MULT;
        this.waypointIndex = 0;
        this.progress = 0;
        this.ws = null;
        this.vehicleId = null;
        this.intervalId = null;
    }

    connect() {
        return new Promise((resolve, reject) => {
            this.ws = new WebSocket(SERVER_URL);

            this.ws.on('open', () => {
                console.log(`✅ ${this.name} (${this.vehicleType}) connected`);
                resolve();
            });

            this.ws.on('message', (data) => {
                const msg = JSON.parse(data.toString());

                if (msg.type === 'REGISTER') {
                    this.vehicleId = msg.payload.id;
                    console.log(`🆔 ${this.name} -> ID: ${this.vehicleId.substring(0, 8)}`);
                }

                if (msg.type === 'NEARBY_VEHICLES') {
                    const { alerts } = msg.payload;
                    for (const alert of alerts) {
                        const icon = alert.riskLevel === 'RED' ? '🔴' : '🟡';
                        console.log(
                            `${icon} [ALERT] ${this.name}: ${alert.alertType} (${alert.distance}m, ${alert.timeToCollision}s)`
                        );
                    }
                }
            });

            this.ws.on('error', (err) => {
                console.error(`❌ ${this.name} error:`, err.message);
                reject(err);
            });

            this.ws.on('close', () => {
                this.stop();
            });
        });
    }

    start() {
        this.intervalId = setInterval(() => {
            if (this.ws.readyState !== WebSocket.OPEN) return;

            const currWp = this.waypoints[this.waypointIndex];
            const nextWp = this.waypoints[(this.waypointIndex + 1) % this.waypoints.length];

            // Linear interpolation
            const lat = currWp.lat + (nextWp.lat - currWp.lat) * this.progress;
            const lng = currWp.lng + (nextWp.lng - currWp.lng) * this.progress;
            const heading = calculateBearing(currWp.lat, currWp.lng, nextWp.lat, nextWp.lng);

            const message = {
                type: 'POSITION_UPDATE',
                timestamp: Date.now(),
                payload: {
                    lat,
                    lng,
                    speed: this.speed,
                    heading,
                    vehicleType: this.vehicleType,
                    timestamp: Date.now(),
                },
            };

            this.ws.send(JSON.stringify(message));

            this.progress += 0.25;
            if (this.progress >= 1.0) {
                this.progress = 0;
                this.waypointIndex = (this.waypointIndex + 1) % this.waypoints.length;
            }
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
║     Scenario: ${(SCENARIO_NAME.toUpperCase()).padEnd(39)}║
║     Server:   ${SERVER_URL.padEnd(39)}║
║     Speed:    ${(SPEED_MULT + 'x').padEnd(39)}║
╚══════════════════════════════════════════════════════╝
    `);

    let targetVehicles = [];
    if (SCENARIO_NAME === 'all') {
        Object.values(SCENARIOS).forEach(list => targetVehicles.push(...list));
    } else if (SCENARIOS[SCENARIO_NAME]) {
        targetVehicles = SCENARIOS[SCENARIO_NAME];
    } else {
        console.error(`Unknown scenario '${SCENARIO_NAME}'. Options: all, ${Object.keys(SCENARIOS).join(', ')}`);
        process.exit(1);
    }

    console.log(`🏁 Starting ${targetVehicles.length} vehicles...\n`);
    const simulators = targetVehicles.map(c => new VehicleSimulator(c));

    try {
        await Promise.all(simulators.map(s => s.connect()));
    } catch (err) {
        console.error('Failed to connect simulators. Is the server running?');
        process.exit(1);
    }

    simulators.forEach(s => s.start());

    process.on('SIGINT', () => {
        console.log('\n🛑 Stopping simulators...');
        simulators.forEach(s => s.stop());
        setTimeout(() => process.exit(0), 300);
    });
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = { SCENARIOS, VehicleSimulator };
