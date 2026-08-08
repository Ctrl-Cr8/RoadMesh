// ─── RoadMesh Admin Dashboard Script ─────────────────────────────────────────

document.addEventListener('DOMContentLoaded', () => {
    // ─── Initialize Map (Leaflet) ─────────────────────────────────────────────
    // Default centered at Kochi, Kerala
    const map = L.map('map').setView([10.0261, 76.3125], 14);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '© OpenStreetMap'
    }).addTo(map);

    const vehicleMarkers = {};

    // ─── Elements ────────────────────────────────────────────────────────────
    const activeVehiclesEl = document.getElementById('active-vehicles-count');
    const activeAlertsEl = document.getElementById('active-alerts-count');
    const wsClientsEl = document.getElementById('ws-clients-count');
    const mqttClientsEl = document.getElementById('mqtt-clients-count');
    const vehicleTableBody = document.getElementById('vehicle-table-body');
    const alertsStream = document.getElementById('alerts-stream-container');
    const serverUptimeEl = document.getElementById('server-uptime');
    const clearAlertsBtn = document.getElementById('clear-alerts-btn');

    let totalAlertsCount = 0;

    // ─── Fetch Stats via REST API ─────────────────────────────────────────────
    async function fetchStats() {
        try {
            const res = await fetch('/stats');
            if (res.ok) {
                const data = await res.json();
                activeVehiclesEl.textContent = data.totalVehicles || 0;
                wsClientsEl.textContent = data.wsClients || 0;
                mqttClientsEl.textContent = data.mqttClients || 0;
            }

            const healthRes = await fetch('/health');
            if (healthRes.ok) {
                const data = await healthRes.json();
                const uptimeSec = Math.floor(data.uptime);
                const hrs = Math.floor(uptimeSec / 3600).toString().padLeft(2, '0');
                const mins = Math.floor((uptimeSec % 3600) / 60).toString().padLeft(2, '0');
                const secs = (uptimeSec % 60).toString().padLeft(2, '0');
                serverUptimeEl.textContent = `Uptime: ${hrs}:${mins}:${secs}`;
            }
        } catch (e) {
            console.error('Failed to fetch stats', e);
        }
    }

    // ─── Fetch Active Vehicles ────────────────────────────────────────────────
    async function fetchVehicles() {
        try {
            const res = await fetch('/vehicles');
            if (!res.ok) return;

            const data = await res.json();
            const vehicles = data.vehicles || [];

            updateVehicleTable(vehicles);
            updateMapMarkers(vehicles);
        } catch (e) {
            console.error('Failed to fetch vehicles', e);
        }
    }

    function updateVehicleTable(vehicles) {
        if (vehicles.length === 0) {
            vehicleTableBody.innerHTML = `<tr><td colspan="7" class="empty-row">No active vehicles registered.</td></tr>`;
            return;
        }

        vehicleTableBody.innerHTML = vehicles.map(v => `
            <tr>
                <td><strong>${v.id}</strong></td>
                <td><span class="chip">${v.vehicleType}</span></td>
                <td>${v.lat.toFixed(5)}, ${v.lng.toFixed(5)}</td>
                <td>${v.speed.toFixed(0)} km/h</td>
                <td>${v.heading.toFixed(0)}°</td>
                <td>${new Date(v.timestamp).toLocaleTimeString()}</td>
                <td><span class="status-online">● ACTIVE</span></td>
            </tr>
        `).join('');
    }

    function updateMapMarkers(vehicles) {
        vehicles.forEach(v => {
            if (vehicleMarkers[v.id]) {
                vehicleMarkers[v.id].setLatLng([v.lat, v.lng]);
            } else {
                const marker = L.marker([v.lat, v.lng])
                    .addTo(map)
                    .bindPopup(`<b>${v.id}</b><br>Type: ${v.vehicleType}<br>Speed: ${v.speed} km/h`);
                vehicleMarkers[v.id] = marker;
            }
        });
    }

    clearAlertsBtn.addEventListener('click', () => {
        alertsStream.innerHTML = `<div class="empty-state">No collision warnings recorded.</div>`;
        totalAlertsCount = 0;
        activeAlertsEl.textContent = '0';
    });

    // Initial load + periodic poll
    fetchStats();
    fetchVehicles();
    setInterval(fetchStats, 3000);
    setInterval(fetchVehicles, 2000);
});
