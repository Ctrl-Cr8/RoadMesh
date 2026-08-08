// ─── Simulator REST API Server ───────────────────────────────────────────────
//
// Express REST API controlling the simulator process.
// Used by the browser simulator control dashboard.

const express = require('express');
const cors = require('cors');
const path = require('path');
const { SCENARIOS, VehicleSimulator } = require('./simulator');

const app = express();
const PORT = process.env.SIMULATOR_PORT || 3001;
const SERVER_URL = process.env.WS_SERVER_URL || 'ws://localhost:3000/ws';

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'simulator-ui')));

let activeSimulators = [];
let currentScenario = null;
let speedMultiplier = 1.0;

// GET /api/scenarios — List available scenarios
app.get('/api/scenarios', (req, res) => {
    res.json({
        scenarios: Object.keys(SCENARIOS),
        current: currentScenario,
        activeCount: activeSimulators.length,
        speedMultiplier,
    });
});

// POST /api/start — Start a scenario
app.post('/api/start', async (req, res) => {
    const { scenario = 'headOn', speed = 1.0 } = req.body;

    // Stop existing
    stopActiveSimulators();

    const target = SCENARIOS[scenario];
    if (!target) {
        return res.status(400).json({ error: `Unknown scenario '${scenario}'` });
    }

    try {
        currentScenario = scenario;
        speedMultiplier = speed;
        activeSimulators = target.map(c => new VehicleSimulator({
            ...c,
            speed: c.speed * speedMultiplier,
        }));

        await Promise.all(activeSimulators.map(s => s.connect()));
        activeSimulators.forEach(s => s.start());

        res.json({
            status: 'started',
            scenario,
            vehicleCount: activeSimulators.length,
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST /api/stop — Stop all running simulators
app.post('/api/stop', (req, res) => {
    stopActiveSimulators();
    res.json({ status: 'stopped' });
});

function stopActiveSimulators() {
    activeSimulators.forEach(s => s.stop());
    activeSimulators = [];
    currentScenario = null;
}

app.listen(PORT, () => {
    console.log(`🎮 Simulator API & Web UI running at http://localhost:${PORT}`);
});
