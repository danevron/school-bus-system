import winston from 'winston';

// Get service version from environment variable
const SERVICE_VERSION = process.env.SERVICE_VERSION || '1.0.0';

// Define log format with metadata
const logFormat = winston.format.combine(
  winston.format.timestamp(),
  winston.format.errors({ stack: true }),
  winston.format.json(),
  winston.format.printf(({ timestamp, level, message, parameters = {}, ...meta }) => {
    return JSON.stringify({
      timestamp,
      level,
      message,
      parameters,
      metadata: {
        service: 'school-bus-system',
        version: SERVICE_VERSION,
        ...meta
      }
    });
  })
);

// Create logger instance
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: logFormat,
  transports: [
    new winston.transports.Console()
  ],
  exceptionHandlers: [
    new winston.transports.Console()
  ],
  rejectionHandlers: [
    new winston.transports.Console()
  ]
});

// Wrapper functions for structured logging
export const log = {
  error: (message: string, parameters: object = {}, meta: object = {}) => {
    logger.error(message, { parameters, ...meta });
  },
  warn: (message: string, parameters: object = {}, meta: object = {}) => {
    logger.warn(message, { parameters, ...meta });
  },
  info: (message: string, parameters: object = {}, meta: object = {}) => {
    logger.info(message, { parameters, ...meta });
  },
  debug: (message: string, parameters: object = {}, meta: object = {}) => {
    logger.debug(message, { parameters, ...meta });
  }
};

export default logger;