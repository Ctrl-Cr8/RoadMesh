# ☁️ RoadMesh Cloud Deployment & Production Guide

This guide details how to deploy the **RoadMesh Zero-Hardware Smartphone V2X Platform** to cloud infrastructure (**Render** and **Vercel**) for live real-world vehicle testing and public demonstrations.

---

## 🌟 Production Architecture

RoadMesh supports two production deployment architectures:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ARCHITECTURE OPTIONS                               │
├──────────────────────────────────────┬──────────────────────────────────────┤
│  Option A: Unified Render Cloud     │  Option B: Decoupled Edge CDN        │
│  (Recommended — Simplest Setup)      │  (High Scale Dashboard Traffic)      │
├──────────────────────────────────────┼──────────────────────────────────────┤
│  • Backend + WS + Dashboard hosted   │  • Backend: Render Web Service       │
│    together on Render.               │    (Node 20, WebSockets, Spatial AI) │
│  • Single domain:                    │  • Dashboard: Vercel Edge CDN        │
│    https://roadmesh.onrender.com     │    (Global ultra-low-latency UI)     │
│  • WebSockets:                       │  • Dashboard connects to Render      │
│    wss://roadmesh.onrender.com/ws    │    WebSocket over secure WSS         │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

---

## 🚀 Option A: Deploying Backend to Render (`render.yaml`)

RoadMesh includes a pre-configured `render.yaml` blueprint at the repository root for seamless 1-click deployment.

### Step 1: Push Repository to GitHub
Ensure your repository is pushed to your GitHub or GitLab account:
```bash
git add .
git commit -m "feat: complete master orchestrator and cloud deployment specs"
git push origin main
```

### Step 2: Deploy on Render
1. Log in to your [Render Dashboard](https://dashboard.render.com/).
2. Click **New +** and select **Blueprint**.
3. Connect your RoadMesh Git repository.
4. Render automatically parses `render.yaml` and initializes the `roadmesh-server` web service:
   - **Runtime**: Node 20
   - **Build Command**: `npm install --include=dev && npm run build`
   - **Start Command**: `npm start`
   - **Plan**: Free (or Starter for 24/7 keepalive without sleep)
5. Click **Apply**. Render will build the TypeScript project, package the dashboard assets, and launch the server.

### Step 3: Verify Render Endpoints
Once deployed, Render provides an HTTPS domain (e.g. `https://roadmesh-server.onrender.com`).
- **Tactical Map Dashboard**: `https://roadmesh-server.onrender.com/dashboard/`
- **WebSocket Endpoint**: `wss://roadmesh-server.onrender.com/ws`
- **Health Check**: `https://roadmesh-server.onrender.com/health`

---

## ⚡ Option B: Deploying Dashboard to Vercel (`vercel.json`)

If you want the Tactical Geospatial Operations Map Dashboard served with sub-50ms latency across global edge points, you can deploy it to Vercel:

### Step 1: Deploy with Vercel CLI or Dashboard
Using the [Vercel CLI](https://vercel.com/cli):
```bash
npm install -g vercel
vercel
```
Or via the [Vercel Web Dashboard](https://vercel.com/new):
1. Import your RoadMesh Git repository.
2. The included `vercel.json` automatically configures the output directory (`roadmesh-server/src/dashboard`) and routes.
3. Click **Deploy**.

### Step 2: Connect Vercel Dashboard to Render Backend
When you open your Vercel URL (e.g. `https://roadmesh-dashboard.vercel.app/`):
1. The dashboard has a built-in **Backend Switcher** in the top navigation bar.
2. Click the **Server Button** (labeled `Local:3000` or `Remote`).
3. Enter your Render backend URL:
   ```
   https://roadmesh-server.onrender.com
   ```
4. The dashboard will automatically switch its REST endpoints and connect to `wss://roadmesh-server.onrender.com/ws`!
5. You can also bookmark the URL with query parameter:
   ```
   https://roadmesh-dashboard.vercel.app/?backend=https://roadmesh-server.onrender.com
   ```

---

## 📱 Connecting the Smartphone App to the Live Cloud Product

When testing in moving vehicles outdoors, your smartphone uses cellular 4G/5G data instead of a local USB cable or home Wi-Fi.

### Method 1: Using the Master Script (One Command)
Run the master script specifying your Render Cloud WebSocket URL:
```bash
./master.sh --cloud wss://roadmesh-server.onrender.com/ws
```
This builds the Flutter APK with `--dart-define="ROAD_MESH_WS_URL=wss://roadmesh-server.onrender.com/ws"`, installs it to the connected phone, grants GPS permissions, and launches the app!

### Method 2: Manual Flutter Build
```bash
cd roadmesh-app
flutter build apk --release --dart-define="ROAD_MESH_WS_URL=wss://roadmesh-server.onrender.com/ws"
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Method 3: In-App Runtime Switching
1. Launch the RoadMesh app on your smartphone.
2. On the home screen, tap the **Connection Settings** icon (gear/server icon).
3. Tap the **☁️ Render Cloud** preset chip (or type in your custom `wss://...` URL).
4. Tap **Connect & Start Driving**.

---

## 🛠️ Environment Variables Reference

When configuring services on Render or Docker:

| Variable | Default | Description |
|---|---|---|
| `PORT` / `HTTP_PORT` | `3000` | HTTP and WebSocket listener port |
| `NEARBY_RADIUS_METERS` | `500` | Geohash spatial query radius in meters |
| `COLLISION_HORIZON_SEC` | `10` | Lookahead trajectory prediction time |
| `VEHICLE_TIMEOUT_MS` | `10000` | Eviction threshold for inactive vehicles |
| `RATE_LIMIT_MAX` | `1000` | Max REST requests per window |
| `ROAD_MESH_WS_URL` | *(None)* | Mobile build-time WebSocket override |

---

## 🏎️ Production Checklist

- [x] Backend TypeScript builds cleanly with zero errors (`npm run build`).
- [x] Vitest verification test suite passes 100% (`npm test`).
- [x] Static dashboard assets bundle into `dist/dashboard`.
- [x] Mobile app passes `flutter analyze` and `flutter test`.
- [x] Dynamic backend URL resolution supported on both desktop and mobile.
- [x] Reverse tunnel port forwarding active for USB development (`adb reverse tcp:3000 tcp:3000`).
