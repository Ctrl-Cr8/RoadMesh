// ─── RoadMesh Operations Console Engine ─────────────────────────────────────────

document.addEventListener('DOMContentLoaded', () => {
    // ─── Theme Management (Light / Dark SaaS Tokens) ──────────────────────────
    const themeToggleBtn = document.getElementById('theme-toggle-btn');
    const themeIcon = document.getElementById('theme-icon');

    function applyTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('roadmesh-theme', theme);
        if (themeIcon) {
            themeIcon.setAttribute('data-lucide', theme === 'dark' ? 'sun' : 'moon');
        }
        if (window.lucide) {
            lucide.createIcons();
        }
    }

    const savedTheme = localStorage.getItem('roadmesh-theme') || 'dark';
    applyTheme(savedTheme);

    if (themeToggleBtn) {
        themeToggleBtn.addEventListener('click', () => {
            const currentTheme = document.documentElement.getAttribute('data-theme') || 'dark';
            const nextTheme = currentTheme === 'dark' ? 'light' : 'dark';
            applyTheme(nextTheme);
        });
    }

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
                gain.gain.setValueAtTime(0.25, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.25);
                osc.connect(gain);
                gain.connect(audioContext.destination);
                osc.start(now);
                osc.stop(now + 0.25);
            } else {
                osc.frequency.setValueAtTime(587, now);
                osc.frequency.exponentialRampToValueAtTime(880, now + 0.12);
                gain.gain.setValueAtTime(0.18, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.2);
                osc.connect(gain);
                gain.connect(audioContext.destination);
                osc.start(now);
                osc.stop(now + 0.2);
            }
        } catch (e) {
            // Browser autoplay policy blocked until user interaction
        }
    }

    // ─── Initialize Map with Google Maps Platform ─────────────────────────────
    const GOOGLE_MAPS_KEY = 'AIzaSyA4szxLy96ImPgQuv94X4gfbk6N76hcnD4';

    const map = L.map('map', {
        zoomControl: true,
        attributionControl: true
    }).setView([20.5937, 78.9629], 5);

    // 1. Google Maps Roadmap (Natural Colors)
    const googleRoadmap = L.tileLayer(`https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}&key=${GOOGLE_MAPS_KEY}`, {
        maxZoom: 20,
        subdomains: ['0', '1', '2', '3'],
        attribution: '© Google Maps'
    }).addTo(map);

    // 2. Google Maps Satellite Hybrid
    const googleHybrid = L.tileLayer(`https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}&key=${GOOGLE_MAPS_KEY}`, {
        maxZoom: 20,
        subdomains: ['0', '1', '2', '3'],
        attribution: '© Google Maps'
    });

    // Layer switcher (top-right)
    L.control.layers({
        'Roadmap': googleRoadmap,
        'Satellite Hybrid': googleHybrid
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
            <div style="position: relative; width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; background: #141416; border: 2px solid #F59E0B; border-radius: 50%; box-shadow: 0 2px 8px rgba(0,0,0,0.35);">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#F59E0B" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M4.9 19.1C1 15.2 1 8.8 4.9 4.9"/>
                    <path d="M7.8 16.2c-2.3-2.3-2.3-6.1 0-8.5"/>
                    <circle cx="12" cy="12" r="2"/>
                    <path d="M16.2 7.8c2.3 2.3 2.3 6.1 0 8.5"/>
                    <path d="M19.1 4.9C23 8.8 23 15.1 19.1 19"/>
                </svg>
            </div>
        `,
        iconSize: [32, 32],
        iconAnchor: [16, 16]
    });

    function setRsuBeaconLocation(lat, lng) {
        schoolCoords = [lat, lng];
        if (!schoolCircle) {
            schoolCircle = L.circle(schoolCoords, {
                color: '#F59E0B',
                fillColor: '#F59E0B',
                fillOpacity: 0.12,
                radius: 130,
                weight: 1.5,
                dashArray: '4, 4'
            }).addTo(map);
        } else {
            schoolCircle.setLatLng(schoolCoords);
        }

        if (!rsuMarker) {
            rsuMarker = L.marker(schoolCoords, { icon: rsuCustomIcon })
                .addTo(map)
                .bindPopup(`
                    <div style="color: var(--text-primary); font-family: var(--font-sans); font-size: 12px; line-height: 1.5; min-width: 170px;">
                        <strong style="color: #F59E0B; display: block; margin-bottom: 4px; border-bottom: 1px solid var(--border); padding-bottom: 4px;">Smart V2I RSU Beacon</strong>
                        <div>Zone: <b>Pedestrian Crossing</b></div>
                        <div>Hardware: <b>Arduino Uno (Pin 2 / LED 13)</b></div>
                        <div>Advisory Speed: <b>20 km/h</b></div>
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
    const wsDot = document.getElementById('ws-dot');
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

    if (audioToggleBtn) {
        audioToggleBtn.addEventListener('click', () => {
            initAudio();
            audioEnabled = !audioEnabled;
            if (audioIcon) {
                audioIcon.innerHTML = `<i data-lucide="${audioEnabled ? 'volume-2' : 'volume-x'}" class="btn-icon-svg"></i>`;
            }
            if (audioLabel) {
                audioLabel.textContent = `Audio: ${audioEnabled ? 'ON' : 'OFF'}`;
            }
            if (window.lucide) lucide.createIcons();
        });
    }

    let totalAlertsCount = 0;
    let cachedVehicles = [];

    // ─── Marker Icon Generator ────────────────────────────────────────────────
    function createVehicleDivIcon(vehicle, isThreat) {
        let haloClass = '';
        let color = '#3B82F6';

        if (isThreat) {
            haloClass = 'threat';
            color = '#EF4444';
        } else if (vehicle.vehicleType === 'EMERGENCY') {
            haloClass = 'emergency';
            color = '#A855F7';
        } else if (vehicle.vehicleType === 'PEDESTRIAN') {
            haloClass = 'pedestrian';
            color = '#F59E0B';
        }

        const heading = vehicle.heading || 0;
        const shortId = vehicle.id.slice(0, 8);

        return L.divIcon({
            className: 'custom-vehicle-icon',
            html: `
                <div class="vehicle-marker-wrapper ${haloClass}">
                    <div class="vehicle-radar-halo"></div>
                    <div class="vehicle-badge-label">${shortId} • ${Math.round(vehicle.speed)} km/h</div>
                    <svg class="vehicle-svg-chevron" style="transform: rotate(${heading}deg);" width="24" height="24" viewBox="0 0 24 24" fill="none">
                        <polygon points="12,2 21,21 12,17 3,21" fill="${color}" stroke="#FFFFFF" stroke-width="1.5" />
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

            if (schoolCoords && v.vehicleType === 'PEDESTRIAN' && Math.abs(v.lat - schoolCoords[0]) < 0.002 && Math.abs(v.lng - schoolCoords[1]) < 0.002) {
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
                    <div style="color: var(--text-primary); font-family: var(--font-sans); font-size: 12px; line-height: 1.5; min-width: 160px;">
                        <strong style="display: block; margin-bottom: 4px; border-bottom: 1px solid var(--border); padding-bottom: 4px;">Device: ${v.id}</strong>
                        <div>Classification: <b>${v.vehicleType}</b></div>
                        <div>Speed: <b>${Math.round(v.speed)} km/h</b></div>
                        <div>Heading: <b>${Math.round(v.heading)}°</b></div>
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
            if (schoolCircle) schoolCircle.setStyle({ color: '#EF4444', fillColor: '#EF4444', fillOpacity: 0.28 });
            if (rsuStatusVal) {
                rsuStatusVal.textContent = 'Active Hazard';
                rsuStatusVal.style.color = 'var(--status-danger)';
            }
            if (arduinoLed) arduinoLed.classList.add('active');
            if (arduinoStatusSub) arduinoStatusSub.textContent = 'Pedestrian Crossing Strobe (Pin 13)';
        } else {
            if (schoolCircle) schoolCircle.setStyle({ color: '#F59E0B', fillColor: '#F59E0B', fillOpacity: 0.12 });
            if (rsuStatusVal) {
                rsuStatusVal.textContent = 'Monitoring';
                rsuStatusVal.style.color = 'var(--status-warn)';
            }
            if (arduinoLed) arduinoLed.classList.remove('active');
            if (arduinoStatusSub) arduinoStatusSub.textContent = 'Arduino Pin 2 Active';
        }
    }

    // ─── Update Telemetry Table ───────────────────────────────────────────────
    function renderVehicleTable(vehicles) {
        const filter = vehicleSearch ? vehicleSearch.value.trim().toLowerCase() : '';
        const filtered = vehicles.filter(v => v.id.toLowerCase().includes(filter) || v.vehicleType.toLowerCase().includes(filter));

        if (filtered.length === 0) {
            vehicleTableBody.innerHTML = `
                <tr>
                    <td colspan="7" class="table-empty-row">
                        <div class="quiet-table-empty">
                            <i data-lucide="radio" class="empty-table-icon"></i>
                            <span>No active mobile devices connected. Open the Flutter app on your phone to stream live GPS.</span>
                        </div>
                    </td>
                </tr>
            `;
            if (window.lucide) lucide.createIcons();
            return;
        }

        vehicleTableBody.innerHTML = filtered.map(v => {
            const isThreat = Boolean(vehicleThreats[v.id]);
            const threatBadge = isThreat
                ? `<span class="risk-chip danger"><i data-lucide="alert-triangle" style="width:11px;height:11px;"></i> RISK</span>`
                : `<span class="risk-chip safe"><i data-lucide="check" style="width:11px;height:11px;"></i> NOMINAL</span>`;

            const accuracyText = v.accuracy ? `<br><small style="color:var(--text-muted);font-family:var(--font-mono);font-size:10px;">±${v.accuracy.toFixed(1)}m</small>` : '';

            return `
                <tr>
                    <td><strong>${v.id}</strong>${accuracyText}</td>
                    <td><span class="type-pill">${v.vehicleType}</span></td>
                    <td class="table-mono">${v.lat.toFixed(5)}, ${v.lng.toFixed(5)}</td>
                    <td class="table-mono">${v.speed.toFixed(0)} km/h</td>
                    <td class="table-mono">${v.heading.toFixed(0)}°</td>
                    <td>${threatBadge}</td>
                    <td><span class="source-chip"><span class="source-dot"></span>${v.source || 'MOBILE_APP'}</span></td>
                </tr>
            `;
        }).join('');

        if (window.lucide) lucide.createIcons();
    }

    if (vehicleSearch) {
        vehicleSearch.addEventListener('input', () => {
            renderVehicleTable(cachedVehicles);
        });
    }

    // ─── Add Alert to Hazard Stream ───────────────────────────────────────────
    function appendAlert(alert) {
        totalAlertsCount++;
        if (activeAlertsEl) activeAlertsEl.textContent = totalAlertsCount;
        if (alertBadgeCount) alertBadgeCount.textContent = totalAlertsCount;
        if (threatLevelText) {
            threatLevelText.textContent = 'Active Risk';
            threatLevelText.className = 'metric-status-chip danger';
        }

        if (alert.vehicleId) {
            vehicleThreats[alert.vehicleId] = true;
        }

        playHazardChime('critical');

        // Remove empty state
        const emptyState = alertsStream.querySelector('.quiet-empty-state') || alertsStream.querySelector('.empty-state');
        if (emptyState) emptyState.remove();

        const item = document.createElement('div');
        item.className = 'alert-card-item danger';
        const timeStr = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
        const ttcStr = alert.timeToCollisionSec != null ? `TTC: ${alert.timeToCollisionSec.toFixed(1)}s` : 'RADIUS WARNING';
        const rawTitle = alert.hazardType || alert.alertType || 'COLLISION IMMINENT';
        const hazardTitle = rawTitle.replace(/[🚨⚠️🚸⚡]/g, '').trim();

        item.innerHTML = `
            <div class="alert-header-row">
                <span class="alert-tag">
                    <i data-lucide="alert-triangle" style="width: 12px; height: 12px; color: var(--status-danger);"></i>
                    ${hazardTitle}
                </span>
                <span class="alert-time">${timeStr}</span>
            </div>
            <div class="alert-text">${alert.description || alert.message || 'Spatial conflict trajectory detected.'}</div>
            <div class="alert-meta">${ttcStr}</div>
        `;

        alertsStream.prepend(item);
        if (window.lucide) lucide.createIcons();

        // Keep last 30 alerts
        while (alertsStream.children.length > 30) {
            alertsStream.removeChild(alertsStream.lastChild);
        }
    }

    if (clearAlertsBtn) {
        clearAlertsBtn.addEventListener('click', () => {
            alertsStream.innerHTML = `
                <div class="quiet-empty-state">
                    <i data-lucide="shield-check" class="empty-icon-svg"></i>
                    <p class="empty-text">No active collision threats in perimeter</p>
                    <span class="empty-hint">Nearby vehicles within 500m are analyzed in real time</span>
                </div>
            `;
            if (window.lucide) lucide.createIcons();
            totalAlertsCount = 0;
            if (activeAlertsEl) activeAlertsEl.textContent = '0';
            if (alertBadgeCount) alertBadgeCount.textContent = '0';
            if (threatLevelText) {
                threatLevelText.textContent = 'Nominal';
                threatLevelText.className = 'metric-status-chip safe';
            }
            Object.keys(vehicleThreats).forEach(k => delete vehicleThreats[k]);
        });
    }

    // ─── WebSocket Real-Time Connection ───────────────────────────────────────
    let ws = null;
    function connectWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws`;

        try {
            ws = new WebSocket(wsUrl);

            ws.onopen = () => {
                if (wsStatusVal) wsStatusVal.textContent = 'Connected';
                if (wsDot) {
                    wsDot.style.backgroundColor = 'var(--status-safe)';
                    wsDot.style.boxShadow = '0 0 0 2px var(--status-safe-bg)';
                }
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
                if (wsStatusVal) wsStatusVal.textContent = 'Reconnecting';
                if (wsDot) {
                    wsDot.style.backgroundColor = 'var(--status-warn)';
                    wsDot.style.boxShadow = '0 0 0 2px var(--status-warn-bg)';
                }
                setTimeout(connectWebSocket, 3000);
            };

            ws.onerror = () => {
                if (wsStatusVal) wsStatusVal.textContent = 'Offline';
                if (wsDot) {
                    wsDot.style.backgroundColor = 'var(--status-danger)';
                    wsDot.style.boxShadow = '0 0 0 2px var(--status-danger-bg)';
                }
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
                if (activeVehiclesEl) activeVehiclesEl.textContent = data.totalVehicles || 0;
                if (telemetryCountBadge) telemetryCountBadge.textContent = `${data.totalVehicles || 0} Devices`;
            }

            const healthRes = await fetch('/health');
            if (healthRes.ok) {
                const data = await healthRes.json();
                const uptimeSec = Math.floor(data.uptime);
                const hrs = Math.floor(uptimeSec / 3600).toString().padStart(2, '0');
                const mins = Math.floor((uptimeSec % 3600) / 60).toString().padStart(2, '0');
                const secs = (uptimeSec % 60).toString().padStart(2, '0');
                if (serverUptimeEl) serverUptimeEl.textContent = `${hrs}:${mins}:${secs}`;
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
            if (wsEndpointUrlInput) wsEndpointUrlInput.value = `${protocol}//${window.location.host}/ws`;
            return;
        }

        try {
            const res = await fetch('/connect');
            if (res.ok) {
                const data = await res.json();
                if (data.wifiWsUrls && data.wifiWsUrls.length > 0) {
                    if (wsEndpointUrlInput) wsEndpointUrlInput.value = data.wifiWsUrls[0];
                } else if (data.usbTunnelWsUrl) {
                    if (wsEndpointUrlInput) wsEndpointUrlInput.value = data.usbTunnelWsUrl;
                } else {
                    if (wsEndpointUrlInput) wsEndpointUrlInput.value = `ws://${window.location.hostname}:3000/ws`;
                }
            }
        } catch (e) {
            if (wsEndpointUrlInput) wsEndpointUrlInput.value = `ws://${window.location.hostname || 'localhost'}:3000/ws`;
        }
    }
    fetchConnectionInfo();

    if (btnCopyWs) {
        btnCopyWs.addEventListener('click', () => {
            if (!wsEndpointUrlInput || !wsEndpointUrlInput.value) return;
            navigator.clipboard.writeText(wsEndpointUrlInput.value);
            btnCopyWs.innerHTML = `<i data-lucide="check" class="copy-svg" style="color: var(--status-safe);"></i>`;
            if (window.lucide) lucide.createIcons();
            setTimeout(() => {
                btnCopyWs.innerHTML = `<i data-lucide="copy" class="copy-svg"></i>`;
                if (window.lucide) lucide.createIcons();
            }, 1500);
        });
    }

    if (btnCopyAdb) {
        btnCopyAdb.addEventListener('click', () => {
            navigator.clipboard.writeText('adb reverse tcp:3000 tcp:3000');
            btnCopyAdb.innerHTML = `<i data-lucide="check" class="copy-svg-sm" style="color: var(--status-safe);"></i>`;
            if (window.lucide) lucide.createIcons();
            setTimeout(() => {
                btnCopyAdb.innerHTML = `<i data-lucide="copy" class="copy-svg-sm"></i>`;
                if (window.lucide) lucide.createIcons();
            }, 1500);
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
    if (btnTriggerArduino) {
        btnTriggerArduino.addEventListener('click', async () => {
            initAudio();
            btnTriggerArduino.disabled = true;
            if (arduinoLed) arduinoLed.classList.add('active');
            if (arduinoStatusSub) arduinoStatusSub.textContent = 'Active Pedestrian Strobe (Pin 13)';

            try {
                const center = map.getCenter();
                const rsuLat = center.lat;
                const rsuLng = center.lng;
                setRsuBeaconLocation(rsuLat, rsuLng);

                // Post pedestrian crossing to spatial engine
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
                    hazardType: 'V2I School Crossing Beacon',
                    description: 'Arduino Uno detected pedestrian button press on Pin 2. Warning beacon active. Advisory: 20 km/h.',
                    timeToCollisionSec: 2.0,
                    vehicleId: 'arduino-uno-crossing-1'
                });

                setTimeout(() => {
                    btnTriggerArduino.disabled = false;
                    if (arduinoLed) arduinoLed.classList.remove('active');
                    if (arduinoStatusSub) arduinoStatusSub.textContent = 'Arduino Pin 2 Active';
                }, 8000);
            } catch (e) {
                btnTriggerArduino.disabled = false;
            }
        });
    }

    // ─── Startup ──────────────────────────────────────────────────────────────
    if (window.lucide) {
        lucide.createIcons();
    }
    connectWebSocket();
    fetchStats();
    fetchVehicles();
    setInterval(fetchStats, 3000);
    setInterval(fetchVehicles, 1500);
});
