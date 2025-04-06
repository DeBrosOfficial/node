import { createLogger, format, transports } from 'winston';
import fs from 'fs';
import path from 'path';

// Create logs directory if it doesn't exist
const logsDir = path.join(process.cwd(), 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir);
}

// Define colors for different service types
const colors: any = {
  error: '\x1b[31m', // red
  warn: '\x1b[33m', // yellow
  info: '\x1b[32m', // green
  debug: '\x1b[36m', // cyan
  reset: '\x1b[0m', // reset

  // Service specific colors
  IPFS: '\x1b[36m', // cyan
  HEARTBEAT: '\x1b[33m', // yellow
  SOCKET: '\x1b[34m', // blue
  'LOAD-BALANCER': '\x1b[35m', // magenta
  DEFAULT: '\x1b[37m', // white
};

// Custom format for console output with colors
const customConsoleFormat = format.printf(({ level, message, timestamp, service }: any) => {
  // Truncate error messages
  if (level === 'error' && typeof message === 'string' && message.length > 300) {
    message = message.substring(0, 300) + '... [truncated]';
  }

  // Handle objects and errors
  if (typeof message === 'object' && message !== null) {
    if (message instanceof Error) {
      message = message.message;
      // Truncate error messages
      if (message.length > 300) {
        message = message.substring(0, 300) + '... [truncated]';
      }
    } else {
      try {
        message = JSON.stringify(message, null, 2);
      } catch (_e) {
        message = '[Object]';
      }
    }
  }

  const serviceColor = service && colors[service] ? colors[service] : colors.DEFAULT;
  const levelColor = colors[level] || colors.DEFAULT;
  const serviceTag = service ? `[${service}]` : '';

  return `${timestamp} ${levelColor}${level}${colors.reset}: ${serviceColor}${serviceTag}${colors.reset} ${message}`;
});

// Custom format for file output (no colors)
const customFileFormat = format.printf(({ level, message, timestamp, service }) => {
  // Handle objects and errors
  if (typeof message === 'object' && message !== null) {
    if (message instanceof Error) {
      message = message.message;
    } else {
      try {
        message = JSON.stringify(message);
      } catch (_e) {
        message = '[Object]';
      }
    }
  }

  const serviceTag = service ? `[${service}]` : '';
  return `${timestamp} ${level}: ${serviceTag} ${message}`;
});

// Create the logger
const logger = createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: format.combine(format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }), format.splat()),
  defaultMeta: { service: 'DEFAULT' },
  transports: [
    // Console transport
    new transports.Console({
      format: format.combine(format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }), customConsoleFormat),
    }),
    // Combined log file
    new transports.File({
      filename: path.join(logsDir, 'app.log'),
      format: format.combine(format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }), customFileFormat),
    }),
    // Error log file
    new transports.File({
      filename: path.join(logsDir, 'error.log'),
      level: 'error',
      format: format.combine(format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }), customFileFormat),
    }),
  ],
});

// Helper function to create a logger for a specific service
export const createServiceLogger = (serviceName: string) => {
  return {
    error: (message: any, ...meta: any[]) => logger.error(message, { service: serviceName, ...meta }),
    warn: (message: any, ...meta: any[]) => logger.warn(message, { service: serviceName, ...meta }),
    info: (message: any, ...meta: any[]) => logger.info(message, { service: serviceName, ...meta }),
    debug: (message: any, ...meta: any[]) => logger.debug(message, { service: serviceName, ...meta }),
  };
};

export default logger;
