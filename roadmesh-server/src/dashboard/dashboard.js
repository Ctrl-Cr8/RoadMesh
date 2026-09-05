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

    // ─── Initialize Map with Google Maps Platform ─────────────────────────────
    const GOOGLE_MAPS_KEY = 'AIzaSyA4szxLy96ImPgQuv94X4gfbk6N76hcnD4';

    // Default view: Starts with general view, then immediately zooms to user's real GPS
    const map = L.map('map', {
        zoomControl: true,
        attributionControl: true
    }).setView([20.5937, 78.9629], 5);

    // 1. Google Maps Roadmap (Full Natural Colors: streets, parks, terrain, water)
    const googleRoadmap = L.tileLayer(`https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}&key=${GOOGLE_MAPS_KEY}`, {
        maxZoom: 20,
        subdomains: ['0', '1', '2', '3'],
        attribution: '© Google Maps'
    }).addTo(map);

    // 2. Google Maps Satellite Hybrid (Satellite Imagery + Street Overlays)
    const googleHybrid = L.tileLayer(`https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}&key=${GOOGLE_MAPS_KEY}`, {
        maxZoom: 20,
        subdomains: ['0', '1', '2', '3'],
        attribution: '© Google Maps'
    });

    // Layer switcher (top-right)
    L.control.layers({
        '🗺️ Google Roadmap (Full Color)': googleRoadmap,
        '🛰️ Google Satellite': googleHybrid
    }, null, { position: 'topright' }).addTo(map);

    // Auto-center on browser host location
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
            (pos) => {
                map.setView([pos.coords.latitude, pos.coords.longitude], 16);
            },
            () => {
                // Will auto-center on incoming smartphone GPS
            },
            { enableHighAccuracy: true, timeout: 5000 }
        );
    }

    const vehicleMarkers = {};
    const vehicleThreats = {};

    // ─── Dynamic Arduino V2I RSU Beacon ───────────────────────────────────────
    let schoolCoords = null;
    let schoolCircle = null;
    let rsuMarker = null;

    const rsuCustomIcon = L.divIcon({
        className: 'rsu-marker',
        html: `
            <div style="position: relative; width: 34px; height: 34px; display: flex; align-items: center; justify-content: center;">
                <div style="position: absolute; width: 32px; height: 32px; border-radius: 50%; background: rgba(255,179,0,0.25); border: 2px solid #FFB300; box-shadow: 0 0 14px #FFB300;"></div>
                <span style="font-size: 16px; position: relative; z-index: 2;">🚸</span>
            </div>
        `,
        iconSize: [34, 34],
        iconAnchor: [17, 17]
    });

    function setRsuBeaconLocation(lat, lng) {
        schoolCoords = [lat, lng];
        if (!schoolCircle) {
            schoolCircle = L.circle(schoolCoords, {
                color: '#FFB300',
                fillColor: '#FFB300',
                fillOpacity: 0.15,
                radius: 130,
                weight: 2,
                dashArray: '4, 4'
            }).addTo(map);
        } else {
            schoolCircle.setLatLng(schoolCoords);
        }

        if (!rsuMarker) {
            rsuMarker = L.marker(schoolCoords, { icon: rsuCustomIcon })
                .addTo(map)
                .bindPopup(`
                    <div style="color: #10172A; font-family: sans-serif; min-width: 180px;">
                        <strong style="color: #FF8F00;">🚸 ARDUINO SMART RSU</strong><br>
                        <span>Pedestrian Crossing Zone</span><br>
                        <small>Hardware: Arduino Uno (Pin 2 / LED 13)</small><br>
                        <b style="color: #0288D1;">Advisory Speed: 20 km/h</b>
                    </div>
                `);
        } else {
            rsuMarker.setLatLng(schoolCoords);
        }
    }

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

    // Mobile Hub Controls
    const wsEndpointUrlInput = document.getElementById('ws-endpoint-url');
    const btnCopyWs = document.getElementById('btn-copy-ws');
    const btnCopyAdb = document.getElementById('btn-copy-adb');
    const btnFocusDevices = document.getElementById('btn-focus-devices');
    const btnTriggerArduino = document.getElementById('btn-trigger-arduino');
    const arduinoStatusSub = document.getElementById('arduino-status-sub');
    const arduinoLed = document.getElementById('arduino-led-indicator');
    let hasAutoFramed = false;

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

        // Auto pan & fit bounds on active mobile devices
        if (vehicles.length > 0 && !hasAutoFramed) {
            focusOnActiveVehicles();
            hasAutoFramed = true;
        }

        // Arduino RSU Visual State
        if (hasPedestrianCross) {
            if (schoolCircle) schoolCircle.setStyle({ color: '#FF1744', fillColor: '#FF1744', fillOpacity: 0.35 });
            rsuStatusVal.textContent = 'PEDESTRIAN HAZARD';
            rsuStatusVal.style.color = '#FF1744';
            arduinoLed.classList.add('active');
            arduinoStatusSub.textContent = 'ACTIVE STROBE (CROSSING)';
        } else {
            if (schoolCircle) schoolCircle.setStyle({ color: '#FFB300', fillColor: '#FFB300', fillOpacity: 0.12 });
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
            vehicleTableBody.innerHTML = `<tr><td colspan="7" class="empty-row">No active mobile devices connected. Open the Flutter app on your phone to stream live GPS.</td></tr>`;
            return;
        }

        vehicleTableBody.innerHTML = filtered.map(v => {
            const isThreat = Boolean(vehicleThreats[v.id]);
            const threatBadge = isThreat
                ? `<span class="threat-high">⚠️ IMMINENT RISK</span>`
                : `<span class="threat-safe">✓ NOMINAL</span>`;

            const accuracyText = v.accuracy ? `<br><small style="color:#64748B;">GPS: ±${v.accuracy.toFixed(1)}m</small>` : '';

            return `
                <tr>
                    <td><strong>${v.id}</strong>${accuracyText}</td>
                    <td><span class="type-chip">${v.vehicleType}</span></td>
                    <td>${v.lat.toFixed(5)}, ${v.lng.toFixed(5)}</td>
                    <td>${v.speed.toFixed(0)} km/h</td>
                    <td>${v.heading.toFixed(0)}°</td>
                    <td>${threatBadge}</td>
                    <td><span class="status-online">● ${v.source || 'MOBILE_APP'}</span></td>
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

    // ─── Mobile Pairing & Tactical Controls ──────────────────────────────────
    async function fetchConnectionInfo() {
        const isCloudHost = window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1';
        if (isCloudHost) {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            wsEndpointUrlInput.value = `${protocol}//${window.location.host}/ws`;
            return;
        }

        try {
            const res = await fetch('/connect');
            if (res.ok) {
                const data = await res.json();
                if (data.wifiWsUrls && data.wifiWsUrls.length > 0) {
                    wsEndpointUrlInput.value = data.wifiWsUrls[0];
                } else if (data.usbTunnelWsUrl) {
                    wsEndpointUrlInput.value = data.usbTunnelWsUrl;
                } else {
                    wsEndpointUrlInput.value = `ws://${window.location.hostname}:3000/ws`;
                }
            }
        } catch (e) {
            wsEndpointUrlInput.value = `ws://${window.location.hostname || 'localhost'}:3000/ws`;
        }
    }
    fetchConnectionInfo();

    if (btnCopyWs) {
        btnCopyWs.addEventListener('click', () => {
            if (!wsEndpointUrlInput.value) return;
            navigator.clipboard.writeText(wsEndpointUrlInput.value);
            btnCopyWs.textContent = '✓';
            setTimeout(() => { btnCopyWs.textContent = '📋'; }, 1500);
        });
    }

    if (btnCopyAdb) {
        btnCopyAdb.addEventListener('click', () => {
            navigator.clipboard.writeText('adb reverse tcp:3000 tcp:3000');
            btnCopyAdb.textContent = '✓';
            setTimeout(() => { btnCopyAdb.textContent = '📋'; }, 1500);
        });
    }

    function focusOnActiveVehicles() {
        const markers = Object.values(vehicleMarkers);
        if (markers.length === 1) {
            map.flyTo(markers[0].getLatLng(), 16, { animate: true, duration: 1.0 });
        } else if (markers.length > 1) {
            const group = L.featureGroup(markers);
            map.fitBounds(group.getBounds(), { padding: [60, 60], maxZoom: 17, animate: true });
        }
    }

    if (btnFocusDevices) {
        btnFocusDevices.addEventListener('click', () => {
            initAudio();
            focusOnActiveVehicles();
        });
    }

    // ─── Arduino Pedestrian Button Simulation ─────────────────────────────────
    btnTriggerArduino.addEventListener('click', async () => {
        initAudio();
        btnTriggerArduino.disabled = true;
        arduinoLed.classList.add('active');
        arduinoStatusSub.textContent = 'PEDESTRIAN CROSSING ACTIVE (PIN 13 STROBE)';

        try {
            const center = map.getCenter();
            const rsuLat = center.lat;
            const rsuLng = center.lng;
            setRsuBeaconLocation(rsuLat, rsuLng);

            // Post an active pedestrian crossing to the spatial engine
            await fetch('/vehicles', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    id: 'arduino-uno-crossing-1',
                    vehicleType: 'PEDESTRIAN',
                    lat: rsuLat,
                    lng: rsuLng,
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
