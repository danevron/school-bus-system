import { RequestLoggerConfig } from '../middlewares/requestLogger';

export const requestLoggerConfig: RequestLoggerConfig = {
  redactionRules: [
    // Authentication endpoints - redact passwords
    {
      method: 'POST',
      path: '/api/auth/login',
      request: {
        paths: ['password'],
        replaceWith: '[REDACTED]'
      }
    },
    {
      method: 'POST',
      path: '/api/auth/register',
      request: {
        paths: ['password'],
        replaceWith: '[REDACTED]'
      }
    },
    {
      method: 'POST',
      path: '/api/invitations/:token/accept',
      request: {
        paths: ['password'],
        replaceWith: '[REDACTED]'
      }
    },
    
    // User management - redact sensitive fields in responses
    {
      method: 'GET',
      path: '/api/auth/users',
      response: {
        paths: ['users.*.email'], // Redact email addresses in user lists
        replaceWith: '[REDACTED]'
      }
    },
    
    // Example of nested redaction for student/parent connections
    {
      method: 'POST',
      path: '/api/auth/students/connect-parents',
      request: {
        paths: ['parentIds'], // Could redact parent IDs for privacy
        replaceWith: '[REDACTED]'
      }
    }
  ],
  
  defaultRedaction: '[REDACTED]',
  
  // Headers to exclude from logs (case-insensitive)
  excludeHeaders: [
    'authorization',
    'cookie',
    'x-api-key',
    'x-auth-token',
    'set-cookie'
  ],
  
  // Logging configuration
  logBody: true,
  logResponseBody: true,
  maxBodySize: 10000, // 10KB - truncate larger bodies
};

// Environment-specific overrides
if (process.env.NODE_ENV === 'production') {
  // In production, be more restrictive
  requestLoggerConfig.logResponseBody = false; // Don't log response bodies in production
  requestLoggerConfig.maxBodySize = 5000; // Smaller limit in production
}

if (process.env.NODE_ENV === 'development') {
  // In development, log more for debugging
  requestLoggerConfig.logBody = true;
  requestLoggerConfig.logResponseBody = true;
  requestLoggerConfig.maxBodySize = 50000; // Larger limit in development
}

// Allow disabling request logging via environment variable
export const isRequestLoggingEnabled = process.env.DISABLE_REQUEST_LOGGING !== 'true';

export default requestLoggerConfig;