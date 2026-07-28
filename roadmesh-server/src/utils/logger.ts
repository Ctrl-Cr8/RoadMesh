// ─── Simple Logger ─────────────────────────────────────────────────────────

type LogLevel = 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';

const LOG_COLORS: Record<LogLevel, string> = {
    DEBUG: '\x1b[36m',   // Cyan
    INFO: '\x1b[32m',    // Green
    WARN: '\x1b[33m',    // Yellow
    ERROR: '\x1b[31m',   // Red
};

const RESET = '\x1b[0m';

class Logger {
    private context: string;

    constructor(context: string) {
        this.context = context;
    }

    private log(level: LogLevel, message: string, data?: unknown): void {
        const timestamp = new Date().toISOString();
        const color = LOG_COLORS[level];
        const prefix = `${color}[${level}]${RESET} ${timestamp} [${this.context}]`;

        if (data !== undefined) {
            console.log(`${prefix} ${message}`, data);
        } else {
            console.log(`${prefix} ${message}`);
        }
    }

    debug(message: string, data?: unknown): void {
        this.log('DEBUG', message, data);
    }

    info(message: string, data?: unknown): void {
        this.log('INFO', message, data);
    }

    warn(message: string, data?: unknown): void {
        this.log('WARN', message, data);
    }

    error(message: string, data?: unknown): void {
        this.log('ERROR', message, data);
    }
}

export function createLogger(context: string): Logger {
    return new Logger(context);
}
