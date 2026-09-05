const express = require('express');
const path = require('path');

const app = express();
const PORT = 8080;

// Set no-cache on index.html so browser never serves stale versions
app.use((req, res, next) => {
    if (req.path === '/' || req.path === '/index.html') {
        res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
        res.setHeader('Pragma', 'no-cache');
        res.setHeader('Expires', '0');
    }
    next();
});

app.use(express.static(path.join(__dirname, 'build', 'web')));

app.get('*', (req, res) => {
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.sendFile(path.join(__dirname, 'build', 'web', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚗 RoadMesh Mobile App live at: http://0.0.0.0:${PORT}`);
});
