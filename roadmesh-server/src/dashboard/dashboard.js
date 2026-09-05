// ─── RoadMesh Autonomous V2X Operations Console Engine ──────────────────────────

document.addEventListener('DOMContentLoaded', () => {
    // ─── Sound Synthesizer (Web Audio API) ────────────────────────────────────
    let audioContext = null;
    let audioEnabled = true;

    function initAudio() {
        if (!audioContext) {
            const AudioContextClass = window.AudioContext || window.webkitAudioContext;
            if (AudioContextClass) audioContext = new AudioContextClass();
        }
        if (audioContext && audioContext.state === 'suspended') {
            audioContext.resume();
        }
    }

    function playHazardChime(severity = 'critical') {
        if (!audioEnabled) return;
        try {
            initAudio();
            if (!audioContext) return;

            const osc = audioContext.createOscillator();
            const gain = audioContext.createGain();
            osc.type = severity === 'critical' ? 'sawtooth' : 'sine';
            
            const now = audioContext.currentTime;
            if (severity === 'critical') {
                osc.frequency.setValueAtTime(880, now);
                osc.frequency.exponentialRampToValueAtTime(440, now + 0.15);
                gain.gain.setValueAtTime(0.3, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.25);
                osc.connect(gain);
                gain.connect(audioContext.destination);
                osc.start(now);
                osc.stop(now + 0.25);
            } else {
                osc.frequency.setValueAtTime(587, now);
                osc.frequency.exponentialRampToValueAtTime(880, now + 0.12);
                gain.gain.setValueAtTime(0.2, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.2);
                osc.connect(gain);
                gain.connect(audioContext.destination);
                osc.start(now);
                osc.stop(now + 0.2);
            }
        } catch (e) {
            // Audio policy blocked until user gesture
        }
    }

    // ─── Initialize Leaflet Dark Map ──────────────────────────────────────────
    // Default center at Kochi, Kerala demo coordinates
    const map = L.map('map', {
        zoomControl: true,
        attributionControl: false
    }).setView([10.0261, 76.3125], 15);

    // CartoDB Dark Matter Tiles (High-contrast, dark mode road vector tiles)
    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
        maxZoom: 19,
        subdomains: 'abcd'
    }).addTo(map);

    const vehicleMarkers = {};
    const vehicleThreats = {};

    // ─── Arduino Smart School Crossing Node (V2I RSU) ─────────────────────────
    const schoolCoords = [10.0261, 76.3125];

    const schoolCircle = L.circle(schoolCoords, {
        color: '#FFB300',
        fillColor: '#FFB300',
        fillOpacity: 0.12,
        radius: 130,
        weight: 1.5,
        dashArray: '4, 4'
    }).addTo(map);

    const rsuCustomIcon = L.divIcon({
        className: 'rsu-marker',
        html: `
            <div style="position: relative; width: 34px; height: 34px; display: flex; align-items: center; justify-content: center;">
                <div style="position: absolute; width: 32px; height: 32px; border-radius: 50%; background: rgba(255,179,0,0.2); border: 2px solid #FFB300; box-shadow: 0 0 14px #FFB300;"></div>
                <span style="font-size: 16px; position: relative; z-index: 2;">🚸</span>
            </div>
        `,
        iconSize: [34, 34],
        iconAnchor: [17, 17]
    });

    const rsuMarker = L.marker(schoolCoords, { icon: rsuCustomIcon })
        .addTo(map)
        .bindPopup(`
            <div style="color: #10172A; font-family: sans-serif; min-width: 180px;">
                <strong style="color: #FF8F00;">🚸 ARDUINO SMART RSU</strong><br>
                <span>Model Public School Zone</span><br>
                <small>Hardware: Arduino Uno (Pin 2 / LED 13)</small><br>
                <b style="color: #0288D1;">Advisory Speed: 20 km/h</b>
            </div>
        `);

    // ─── DOM References ───────────────────────────────────────────────────────
    const activeVehiclesEl = document.getElementById('active-vehicles-count');
    const activeAlertsEl = document.getElementById('active-alerts-count');
    const wsStatusVal = document.getElementById('ws-status-val');
    const rsuStatusVal = document.getElementById('rsu-status-val');
    const threatLevelText = document.getElementById('threat-level-text');
    const alertBadgeCount = document.getElementById('alert-badge-count');
    const telemetryCountBadge = document.getElementById('telemetry-count-badge');
    const vehicleTableBody = document.getElementById('vehicle-table-body');
    const alertsStream = document.getElementById('alerts-stream-container');
    const serverUptimeEl = document.getElementById('server-uptime');
    const clearAlertsBtn = document.getElementById('clear-alerts-btn');
    const vehicleSearch = document.getElementById('vehicle-search');

    // Scenario Controls
    const scenarioSelect = document.getElementById('scenario-select');
    const btnLaunchScenario = document.getElementById('btn-launch-scenario');
    const btnStopScenario = document.getElementById('btn-stop-scenario');
    const btnTriggerArduino = document.getElementById('btn-trigger-arduino');
    const arduinoStatusSub = document.getElementById('arduino-status-sub');
    const arduinoLed = document.getElementById('arduino-led-indicator');

    // Audio Controls
    const audioToggleBtn = document.getElementById('audio-toggle-btn');
    const audioIcon = document.getElementById('audio-icon');
    const audioLabel = document.getElementById('audio-label');

    audioToggleBtn.addEventListener('click', () => {
        initAudio();
        audioEnabled = !audioEnabled;
        audioIcon.textContent = audioEnabled ? '🔊' : '🔇';
        audioLabel.textContent = `Radar Audio: ${audioEnabled ? 'ON' : 'OFF'}`;
    });

    let totalAlertsCount = 0;
    let cachedVehicles = [];

    // ─── Marker Icon Generator ────────────────────────────────────────────────
    function createVehicleDivIcon(vehicle, isThreat) {
        let haloClass = '';
        let color = '#00E5FF';

        if (isThreat) {
            haloClass = 'threat';
            color = '#FF1744';
        } else if (vehicle.vehicleType === 'EMERGENCY') {
            haloClass = 'emergency';
            color = '#D500F9';
        } else if (vehicle.vehicleType === 'PEDESTRIAN') {
            haloClass = 'pedestrian';
            color = '#FFB300';
        }

        const heading = vehicle.heading || 0;
        const shortId = vehicle.id.slice(0, 7);

        return L.divIcon({
            className: 'custom-vehicle-icon',
            html: `
                <div class="vehicle-marker-wrapper ${haloClass}">
                    <div class="vehicle-radar-halo"></div>
                    <div class="vehicle-badge-label">${shortId} • ${Math.round(vehicle.speed)} km/h</div>
                    <svg class="vehicle-svg-chevron" style="transform: rotate(${heading}deg);" width="26" height="26" viewBox="0 0 24 24" fill="none">
                        <polygon points="12,2 22,22 12,17 2,22" fill="${color}" stroke="#FFFFFF" stroke-width="1.5" />
                    </svg>
                </div>
            `,
            iconSize: [44, 44],
            iconAnchor: [22, 22]
        });
    }

    // ─── Update Map Markers ───────────────────────────────────────────────────
    function updateMapMarkers(vehicles) {
        let hasPedestrianCross = false;
        const currentIds = new Set();

        vehicles.forEach(v => {
            currentIds.add(v.id);
            const isThreat = Boolean(vehicleThreats[v.id]);

            if (v.vehicleType === 'PEDESTRIAN' && Math.abs(v.lat - schoolCoords[0]) < 0.002 && Math.abs(v.lng - schoolCoords[1]) < 0.002) {
                hasPedestrianCross = true;
            }

            if (vehicleMarkers[v.id]) {
                const marker = vehicleMarkers[v.id];
                marker.setLatLng([v.lat, v.lng]);
                marker.setIcon(createVehicleDivIcon(v, isThreat));
            } else {
                const marker = L.marker([v.lat, v.lng], {
                    icon: createVehicleDivIcon(v, isThreat)
                }).addTo(map);

                marker.bindPopup(`
                    <div style="color: #10172A; font-family: sans-serif;">
                        <strong>🚗 ID: ${v.id}</strong><br>
                        <span>Class: <b>${v.vehicleType}</b></span><br>
                        <span>Speed: <b>${Math.round(v.speed)} km/h</b></span><br>
                        <span>Heading: <b>${Math.round(v.heading)}°</b></span>
                    </div>
                `);

                vehicleMarkers[v.id] = marker;
            }
        });

        // Prune inactive markers
        Object.keys(vehicleMarkers).forEach(id => {
            if (!currentIds.has(id)) {
                map.removeLayer(vehicleMarkers[id]);
                delete vehicleMarkers[id];
                delete vehicleThreats[id];
            }
        });

        // Auto pan if vehicles exist
        if (vehicles.length > 0 && map.getZoom() < 14) {
            map.panTo([vehicles[0].lat, vehicles[0].lng]);
        }

        // Arduino RSU Visual State
        if (hasPedestrianCross) {
            schoolCircle.setStyle({ color: '#FF1744', fillColor: '#FF1744', fillOpacity: 0.35 });
            rsuStatusVal.textContent = 'PEDESTRIAN HAZARD';
            rsuStatusVal.style.color = '#FF1744';
            arduinoLed.classList.add('active');
            arduinoStatusSub.textContent = 'ACTIVE STROBE (CROSSING)';
        } else {
            schoolCircle.setStyle({ color: '#FFB300', fillColor: '#FFB300', fillOpacity: 0.12 });
            rsuStatusVal.textContent = 'MONITORING';
            rsuStatusVal.style.color = '#FFB300';
            arduinoLed.classList.remove('active');
            arduinoStatusSub.textContent = 'BEACON IDLE (PIN 2)';
        }
    }

    // ─── Update Telemetry Table ───────────────────────────────────────────────
    function renderVehicleTable(vehicles) {
        const filter = vehicleSearch.value.trim().toLowerCase();
        const filtered = vehicles.filter(v => v.id.toLowerCase().includes(filter) || v.vehicleType.toLowerCase().includes(filter));

        if (filtered.length === 0) {
            vehicleTableBody.innerHTML = `<tr><td colspan="7" class="empty-row">No active vehicle nodes match criteria.</td></tr>`;
            return;
        }

        vehicleTableBody.innerHTML = filtered.map(v => {
            const isThreat = Boolean(vehicleThreats[v.id]);
            const threatBadge = isThreat
                ? `<span class="threat-high">⚠️ IMMINENT RISK</span>`
                : `<span class="threat-safe">✓ NOMINAL</span>`;

            return `
                <tr>
                    <td><strong>${v.id}</strong></td>
                    <td><span class="type-chip">${v.vehicleType}</span></td>
                    <td>${v.lat.toFixed(5)}, ${v.lng.toFixed(5)}</td>
                    <td>${v.speed.toFixed(0)} km/h</td>
                    <td>${v.heading.toFixed(0)}°</td>
                    <td>${threatBadge}</td>
                    <td><span class="status-online">● ACTIVE</span></td>
                </tr>
            `;
        }).join('');
    }

    vehicleSearch.addEventListener('input', () => {
        renderVehicleTable(cachedVehicles);
    });

    // ─── Add Alert to Hazard Stream ───────────────────────────────────────────
    function appendAlert(alert) {
        totalAlertsCount++;
        activeAlertsEl.textContent = totalAlertsCount;
        alertBadgeCount.textContent = `${totalAlertsCount} EVENTS`;
        threatLevelText.textContent = `ALERT: ${alert.hazardType || alert.alertType}`;
        threatLevelText.style.color = '#FF1744';

        if (alert.vehicleId) {
            vehicleThreats[alert.vehicleId] = true;
        }

        // Sound chime
        playHazardChime('critical');

        // Remove empty state
        const emptyState = alertsStream.querySelector('.empty-state');
        if (emptyState) emptyState.remove();

        const item = document.createElement('div');
        item.className = 'alert-item';
        const timeStr = new Date().toLocaleTimeString();
        const ttcStr = alert.timeToCollisionSec != null ? `TTC: ${alert.timeToCollisionSec.toFixed(1)}s` : 'RADIUS WARNING';

        item.innerHTML = `
            <div class="alert-top-row">
                <span class="alert-hazard-type">🚨 ${alert.hazardType || alert.alertType || 'COLLISION IMMINENT'}</span>
                <span class="alert-time">${timeStr}</span>
            </div>
            <div class="alert-desc">${alert.description || alert.message || 'Spatial conflict trajectory detected.'}</div>
            <div class="alert-ttc">⚡ ${ttcStr}</div>
        `;

        alertsStream.prepend(item);

        // Keep last 30 alerts
        while (alertsStream.children.length > 30) {
            alertsStream.removeChild(alertsStream.lastChild);
        }
    }

    clearAlertsBtn.addEventListener('click', () => {
        alertsStream.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">🛡️</div>
                <div class="empty-text">No active collision threats in monitored perimeter.</div>
            </div>
        `;
        totalAlertsCount = 0;
        activeAlertsEl.textContent = '0';
        alertBadgeCount.textContent = '0 EVENTS';
        threatLevelText.textContent = 'Status: Clear';
        threatLevelText.style.color = 'var(--text-secondary)';
        Object.keys(vehicleThreats).forEach(k => delete vehicleThreats[k]);
    });

    // ─── WebSocket Real-Time Connection ───────────────────────────────────────
    let ws = null;
    function connectWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws`;

        try {
            ws = new WebSocket(wsUrl);

            ws.onopen = () => {
                wsStatusVal.textContent = 'CONNECTED';
                wsStatusVal.style.color = '#00E676';
            };

            ws.onmessage = (event) => {
                try {
                    const msg = JSON.parse(event.data);

                    if (msg.type === 'alerts' && Array.isArray(msg.data)) {
                        msg.data.forEach(appendAlert);
                    } else if (msg.type === 'alert' && msg.data) {
                        appendAlert(msg.data);
                    } else if (msg.type === 'nearbyVehicles' && Array.isArray(msg.data)) {
                        cachedVehicles = msg.data;
                        updateMapMarkers(cachedVehicles);
                        renderVehicleTable(cachedVehicles);
                    }
                } catch (e) {
                    console.error('Error parsing WS message', e);
                }
            };

            ws.onclose = () => {
                wsStatusVal.textContent = 'RECONNECTING';
                wsStatusVal.style.color = '#FFB300';
                setTimeout(connectWebSocket, 3000);
            };

            ws.onerror = () => {
                wsStatusVal.textContent = 'OFFLINE';
                wsStatusVal.style.color = '#FF1744';
            };
        } catch (err) {
            console.warn('WS not available, falling back to polling');
        }
    }

    // ─── REST Polling Fallback & Server Stats ──────────────────────────────────
    async function fetchStats() {
        try {
            const res = await fetch('/stats');
            if (res.ok) {
                const data = await res.json();
                activeVehiclesEl.textContent = data.totalVehicles || 0;
                telemetryCountBadge.textContent = `${data.totalVehicles || 0} NODES`;
            }

            const healthRes = await fetch('/health');
            if (healthRes.ok) {
                const data = await healthRes.json();
                const uptimeSec = Math.floor(data.uptime);
                const hrs = Math.floor(uptimeSec / 3600).toString().padStart(2, '0');
                const mins = Math.floor((uptimeSec % 3600) / 60).toString().padStart(2, '0');
                const secs = (uptimeSec % 60).toString().padStart(2, '0');
                serverUptimeEl.textContent = `Uptime: ${hrs}:${mins}:${secs}`;
            }
        } catch (e) {}
    }

    async function fetchVehicles() {
        try {
            const res = await fetch('/vehicles');
            if (!res.ok) return;

            const data = await res.json();
            cachedVehicles = data.vehicles || [];
            updateMapMarkers(cachedVehicles);
            renderVehicleTable(cachedVehicles);
        } catch (e) {}
    }

    // ─── Scenario Actions ─────────────────────────────────────────────────────
    btnLaunchScenario.addEventListener('click', async () => {
        initAudio();
        const scenario = scenarioSelect.value;
        btnLaunchScenario.disabled = true;
        btnLaunchScenario.textContent = 'LAUNCHING...';

        try {
            const res = await fetch('http://localhost:3001/api/start', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ scenario, speed: 1.0 })
            });

            if (res.ok) {
                const data = await res.json();
                btnLaunchScenario.innerHTML = `<span>ACTIVE (${data.vehicleCount} CARS)</span>`;
                playHazardChime('info');
            } else {
                alert('Simulator engine on port 3001 not responding. Run: ./run.sh simulator');
                btnLaunchScenario.innerHTML = '<span>▶ LAUNCH</span>';
            }
        } catch (e) {
            alert('Simulator engine on port 3001 is offline. Start it with: ./run.sh simulator');
            btnLaunchScenario.innerHTML = '<span>▶ LAUNCH</span>';
        } finally {
            btnLaunchScenario.disabled = false;
        }
    });

    btnStopScenario.addEventListener('click', async () => {
        try {
            await fetch('http://localhost:3001/api/stop', { method: 'POST' });
            btnLaunchScenario.innerHTML = '<span>▶ LAUNCH</span>';
            fetchVehicles();
        } catch (e) {}
    });

    // ─── Arduino Pedestrian Button Simulation ─────────────────────────────────
    btnTriggerArduino.addEventListener('click', async () => {
        initAudio();
        btnTriggerArduino.disabled = true;
        arduinoLed.classList.add('active');
        arduinoStatusSub.textContent = 'PEDESTRIAN CROSSING ACTIVE (PIN 13 STROBE)';

        try {
            // Post an active pedestrian crossing to the spatial engine
            await fetch('/vehicles', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    id: 'arduino-uno-crossing-1',
                    vehicleType: 'PEDESTRIAN',
                    lat: schoolCoords[0],
                    lng: schoolCoords[1],
                    speed: 1.4,
                    heading: 90,
                    timestamp: Date.now()
                })
            });

            appendAlert({
                hazardType: '🚸 V2I SCHOOL CROSSING BEACON',
                description: 'Arduino Uno detected pedestrian button press on Pin 2. Strobe active. Speed advisory: 20 km/h.',
                timeToCollisionSec: 2.0,
                vehicleId: 'arduino-uno-crossing-1'
            });

            setTimeout(() => {
                btnTriggerArduino.disabled = false;
                arduinoLed.classList.remove('active');
                arduinoStatusSub.textContent = 'BEACON IDLE (PIN 2)';
            }, 8000);
        } catch (e) {
            btnTriggerArduino.disabled = false;
        }
    });

    // ─── Startup ──────────────────────────────────────────────────────────────
    connectWebSocket();
    fetchStats();
    fetchVehicles();
    setInterval(fetchStats, 3000);
    setInterval(fetchVehicles, 1500);
});
