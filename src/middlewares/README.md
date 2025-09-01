# Request Logger Middleware

A comprehensive HTTP request/response logging middleware with configurable redaction capabilities.

## Features

- ✅ Logs all HTTP requests and responses with structured JSON
- ✅ Configurable per-endpoint redaction using JSON paths
- ✅ Automatic header filtering (excludes sensitive headers like authorization)
- ✅ Request/response body logging with size limits
- ✅ Client IP detection (handles proxies)
- ✅ Request duration tracking
- ✅ Runtime redaction rule management
- ✅ Environment-specific configuration

## Configuration

### Basic Setup

```typescript
import { RequestLogger } from './middlewares/requestLogger';
import requestLoggerConfig from './config/requestLogger';
import { log } from './utils/logger';

const requestLogger = new RequestLogger(log, requestLoggerConfig);
app.use(requestLogger.middleware());
```

### Environment Variables

```env
# Disable request logging entirely
DISABLE_REQUEST_LOGGING=true

# Set service version for metadata
SERVICE_VERSION=1.2.0

# Set log level
LOG_LEVEL=debug
```

## Redaction Rules

### JSON Path Examples

```typescript
{
  method: 'POST',
  path: '/api/auth/login',
  request: {
    paths: ['password'],           // Simple path
    replaceWith: '[REDACTED]'
  }
}

{
  method: 'GET', 
  path: '/api/users',
  response: {
    paths: [
      'users.*.email',             // Wildcard for arrays
      'users.*.personalInfo.ssn'   // Nested object path
    ],
    replaceWith: '[HIDDEN]'
  }
}
```

### Path Pattern Matching

The middleware supports Express-style path parameters:

```typescript
{
  method: 'POST',
  path: '/api/invitations/:token/accept',  // :token matches any value
  request: {
    paths: ['password']
  }
}
```

### Complex Redaction Example

```typescript
{
  method: 'POST',
  path: '/api/students/bulk-create',
  request: {
    paths: [
      'students.*.ssn',            // Redact SSN for all students
      'students.*.parentContact.email',  // Redact parent emails
      'metadata.adminKey'          // Redact admin key
    ],
    replaceWith: '[SENSITIVE]'
  },
  response: {
    paths: [
      'created.*.internalId'       // Hide internal IDs from response
    ],
    replaceWith: '[ID_HIDDEN]'
  }
}
```

## Dependency Injection

The RequestLogger accepts a logger instance that implements this interface:

```typescript
interface Logger {
  info(message: string, parameters?: object, meta?: object): void;
  warn(message: string, parameters?: object, meta?: object): void;
  error(message: string, parameters?: object, meta?: object): void;
  debug(message: string, parameters?: object, meta?: object): void;
}
```

### Custom Logger Example

```typescript
import { RequestLogger, Logger } from './middlewares/requestLogger';

// Custom logger implementation
class CustomLogger implements Logger {
  info(message: string, parameters?: object) {
    console.log(`[INFO] ${message}`, parameters);
  }
  
  warn(message: string, parameters?: object) {
    console.warn(`[WARN] ${message}`, parameters);
  }
  
  error(message: string, parameters?: object) {
    console.error(`[ERROR] ${message}`, parameters);
  }
  
  debug(message: string, parameters?: object) {
    console.debug(`[DEBUG] ${message}`, parameters);
  }
}

const customLogger = new CustomLogger();
const requestLogger = new RequestLogger(customLogger, config);
```

## Runtime Rule Management

```typescript
// Add new redaction rule
requestLogger.addRedactionRule({
  method: 'POST',
  path: '/api/payments/process',
  request: {
    paths: ['creditCard.number', 'creditCard.cvv'],
    replaceWith: '[PAYMENT_INFO_REDACTED]'
  }
});

// Remove redaction rule
requestLogger.removeRedactionRule('POST', '/api/payments/process');

// Update configuration
requestLogger.updateConfig({
  maxBodySize: 20000,
  logResponseBody: false
});
```

## Log Output Format

### Request Log

```json
{
  "timestamp": "2025-01-15T10:30:45.123Z",
  "level": "info",
  "message": "HTTP Request",
  "parameters": {
    "requestId": "abc123def",
    "method": "POST",
    "url": "/api/auth/login?remember=true",
    "path": "/api/auth/login",
    "query": { "remember": "true" },
    "ip": "192.168.1.100",
    "userAgent": "Mozilla/5.0...",
    "headers": {
      "content-type": "application/json",
      "accept": "application/json"
      // authorization header excluded
    },
    "body": {
      "email": "user@example.com",
      "password": "[REDACTED]"
    },
    "timestamp": "2025-01-15T10:30:45.123Z"
  },
  "metadata": {
    "service": "school-bus-system",
    "version": "1.0.0"
  }
}
```

### Response Log

```json
{
  "timestamp": "2025-01-15T10:30:45.150Z",
  "level": "info", 
  "message": "HTTP Response",
  "parameters": {
    "requestId": "abc123def",
    "method": "POST",
    "url": "/api/auth/login?remember=true",
    "path": "/api/auth/login",
    "statusCode": 200,
    "statusMessage": "OK",
    "duration": 27,
    "contentLength": "256",
    "responseBody": {
      "message": "Login successful",
      "token": "eyJ...",
      "user": {
        "id": "507f1f77bcf86cd799439011",
        "email": "user@example.com"
      }
    },
    "timestamp": "2025-01-15T10:30:45.150Z"
  },
  "metadata": {
    "service": "school-bus-system",
    "version": "1.0.0"
  }
}
```

## Security Features

### Automatic Header Filtering

These headers are automatically excluded from logs:
- `authorization`
- `cookie` 
- `x-api-key`
- `x-auth-token`
- `set-cookie`

### Body Size Limits

- Default: 10KB per request/response body
- Larger bodies are truncated with size indicator
- Configurable per environment

### IP Detection

Handles various proxy configurations:
- `x-forwarded-for` header
- `x-real-ip` header  
- Direct connection IP
- Fallback to 'unknown'

## Environment-Specific Behavior

### Development
- Logs both request and response bodies
- Higher body size limit (50KB)
- More verbose logging

### Production  
- Response bodies disabled by default
- Lower body size limit (5KB)
- Focused on security

## Performance Considerations

- Request/response bodies are only read once
- JSON parsing is done lazily
- Redaction is applied to cloned objects
- Minimal overhead when logging is disabled

## Troubleshooting

### Common Issues

1. **Rules not matching**: Check path patterns and HTTP methods
2. **Redaction not working**: Verify JSON paths are correct
3. **Missing request body**: Ensure middleware is after body parsing
4. **Performance issues**: Reduce `maxBodySize` or disable body logging

### Debug Mode

Set `LOG_LEVEL=debug` to see additional information:

```json
{
  "level": "debug",
  "message": "Redaction rule matched",
  "parameters": {
    "method": "POST",
    "path": "/api/auth/login", 
    "rulePath": "/api/auth/login",
    "redactedPaths": ["password"]
  }
}
```