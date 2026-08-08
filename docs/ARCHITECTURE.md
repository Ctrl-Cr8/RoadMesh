# RoadMesh System Architecture

This document describes the core algorithms and data structures powering **RoadMesh**.

---

## 🗺️ Spatial Indexing with Geohashing

To compute collision risks for thousands of vehicles in sub-millisecond time, RoadMesh uses **Geohash spatial indexing**:

- Earth is divided into hierarchical grid cells.
- Precision **6** geohashes (~1.2km × 0.6km) are used for cell grouping.
- Spatial lookup checks the vehicle's cell **plus all 8 neighboring cells** (`getNeighborhood()`).
- This guarantees boundary overlap detection without requiring an expensive $O(N^2)$ distance matrix.

```
┌───────┬───────┬───────┐
│ N-W   │ NORTH │ N-E   │
├───────┼───────┼───────┤
│ WEST  │ EGO   │ EAST  │  <-- 9 Geohash Cells Evaluated
├───────┼───────┼───────┤
│ S-W   │ SOUTH │ S-E   │
└───────┴───────┴───────┘
```

---

## ⚡ Collision Prediction Algorithm

The collision engine in `predictor.ts` evaluates risk in two steps:

### Step 1: Linear Trajectory Projection
Vehicle positions are projected forward across time steps $t \in \{1s, 2s, \dots, 10s\}$ using spherical trigonometry (`predictPosition`):
$$\text{distance} = \text{speed} \times t$$

### Step 2: Time of Closest Approach (TCA)
Using relative position vectors $\vec{r} = \vec{r}_1 - \vec{r}_2$ and relative velocity vectors $\vec{v} = \vec{v}_1 - \vec{v}_2$, the time of closest approach is computed via dot product:
$$\text{TCA} = -\frac{\vec{r} \cdot \vec{v}}{\|\vec{v}\|^2}$$

If predicted distance at TCA is $< 15m$, a **RED** alert is raised; if $< 40m$, a **YELLOW** alert is raised.
