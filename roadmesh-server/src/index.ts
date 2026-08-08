// ─── RoadMesh Server Entry Point ────────────────────────────────────────────

import { RoadMeshServer } from './server';
import { createLogger } from './utils/logger';

const log = createLogger('Main');

const server = new RoadMeshServer();

// ─── Graceful Shutdown ───────────────────────────────────────────────────────

async function shutdown(signal: string): Promise<void> {
    log.info(`Received ${signal}. Gracefully shutting down...`);
    try {
        await server.stop();
        process.exit(0);
    } catch (err) {
        log.error('Error during shutdown:', err);
        process.exit(1);
    }
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

// ─── Unhandled Rejections ────────────────────────────────────────────────────

process.on('unhandledRejection', (reason) => {
    log.error('Unhandled Promise Rejection:', reason);
});

process.on('uncaughtException', (err) => {
    log.error('Uncaught Exception:', err);
    process.exit(1);
});

// ─── Start ───────────────────────────────────────────────────────────────────

server.start();
