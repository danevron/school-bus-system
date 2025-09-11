import { Request, Response, NextFunction } from 'express';
import get from 'lodash.get';
import set from 'lodash.set';
import unset from 'lodash.unset';

export interface Logger {
  info(message: string, parameters?: object, meta?: object): void;
  warn(message: string, parameters?: object, meta?: object): void;
  error(message: string, parameters?: object, meta?: object): void;
  debug(message: string, parameters?: object, meta?: object): void;
}

export interface RedactionRule {
  paths: string[];
  replaceWith?: string;
}

export interface EndpointRedactionConfig {
  method: string;
  path: string;
  request?: RedactionRule;
  response?: RedactionRule;
}

export interface RequestLoggerConfig {
  redactionRules: EndpointRedactionConfig[];
  defaultRedaction: string;
  excludeHeaders: string[];
  logBody: boolean;
  logResponseBody: boolean;
  maxBodySize: number;
}

const defaultConfig: RequestLoggerConfig = {
  redactionRules: [
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
    }
  ],
  defaultRedaction: '[REDACTED]',
  excludeHeaders: ['authorization', 'cookie', 'x-api-key'],
  logBody: true,
  logResponseBody: true,
  maxBodySize: 10000 // 10KB limit
};

class RequestLogger {
  private config: RequestLoggerConfig;
  private logger: Logger;

  constructor(logger: Logger, config: Partial<RequestLoggerConfig> = {}) {
    this.logger = logger;
    this.config = { ...defaultConfig, ...config };
  }

  private redactData(data: any, paths: string[], replaceWith: string = '[REDACTED]'): any {
    if (!data || typeof data !== 'object') return data;
    
    const cloned = JSON.parse(JSON.stringify(data));
    
    paths.forEach(path => {
      if (get(cloned, path) !== undefined) {
        set(cloned, path, replaceWith);
      }
    });
    
    return cloned;
  }

  private findRedactionRule(method: string, path: string): EndpointRedactionConfig | undefined {
    return this.config.redactionRules.find(rule => {
      const methodMatch = rule.method.toLowerCase() === method.toLowerCase();
      
      // Simple pattern matching - convert express params to regex
      const pattern = rule.path.replace(/:[\w]+/g, '[^/]+');
      const regex = new RegExp(`^${pattern}$`);
      const pathMatch = regex.test(path);
      
      return methodMatch && pathMatch;
    });
  }

  private filterHeaders(headers: any): any {
    const filtered = { ...headers };
    
    this.config.excludeHeaders.forEach(header => {
      const lowerHeader = header.toLowerCase();
      Object.keys(filtered).forEach(key => {
        if (key.toLowerCase() === lowerHeader) {
          delete filtered[key];
        }
      });
    });
    
    return filtered;
  }

  private truncateBody(body: any): any {
    if (!body) return body;
    
    const bodyStr = typeof body === 'string' ? body : JSON.stringify(body);
    if (bodyStr.length > this.config.maxBodySize) {
      return `[TRUNCATED - ${bodyStr.length} bytes, showing first ${this.config.maxBodySize}]${bodyStr.substring(0, this.config.maxBodySize)}`;
    }
    
    return body;
  }

  private getClientIp(req: Request): string {
    return (req.headers['x-forwarded-for'] as string)?.split(',')[0] || 
           req.headers['x-real-ip'] as string ||
           req.connection.remoteAddress ||
           req.socket.remoteAddress ||
           'unknown';
  }

  middleware() {
    return (req: Request, res: Response, next: NextFunction) => {
      const startTime = Date.now();
      const requestId = Math.random().toString(36).substr(2, 9);
      
      // Store original res.json and res.send to capture response body
      const originalJson = res.json.bind(res);
      const originalSend = res.send.bind(res);
      let responseBody: any;

      // Override res.json to capture response
      res.json = function(body: any) {
        responseBody = body;
        return originalJson(body);
      };

      // Override res.send to capture response
      res.send = function(body: any) {
        if (!responseBody) {
          responseBody = body;
        }
        return originalSend(body);
      };

      // Log request
      const redactionRule = this.findRedactionRule(req.method, req.path);
      
      let requestBody = this.config.logBody ? this.truncateBody(req.body) : undefined;
      if (redactionRule?.request) {
        requestBody = this.redactData(requestBody, redactionRule.request.paths, redactionRule.request.replaceWith);
      }

      if (req.path !== '/health') { // Skip logging for health checks
        this.logger.info('HTTP Request', {
          requestId,
          method: req.method,
          url: req.originalUrl,
          path: req.path,
          query: req.query,
          ip: this.getClientIp(req),
          userAgent: req.headers['user-agent'],
          headers: this.filterHeaders(req.headers),
          body: requestBody,
          timestamp: new Date().toISOString()
        });
      }

      // Log response when request finishes
      res.on('finish', () => {
        const duration = Date.now() - startTime;
        
        let logResponseBody = this.config.logResponseBody ? this.truncateBody(responseBody) : undefined;
        if (redactionRule?.response) {
          logResponseBody = this.redactData(logResponseBody, redactionRule.response.paths, redactionRule.response.replaceWith);
        }

        if (req.path !== '/health') { // Skip logging for health checks
          this.logger.info('HTTP Response', {
            requestId,
            method: req.method,
            url: req.originalUrl,
            path: req.path,
            statusCode: res.statusCode,
            statusMessage: res.statusMessage,
            duration,
            contentLength: res.get('content-length'),
            responseBody: logResponseBody,
            timestamp: new Date().toISOString()
          });
        }
      });

      next();
    };
  }

  // Method to update redaction rules at runtime
  addRedactionRule(rule: EndpointRedactionConfig) {
    this.config.redactionRules.push(rule);
  }

  removeRedactionRule(method: string, path: string) {
    this.config.redactionRules = this.config.redactionRules.filter(
      rule => !(rule.method.toLowerCase() === method.toLowerCase() && rule.path === path)
    );
  }

  updateConfig(newConfig: Partial<RequestLoggerConfig>) {
    this.config = { ...this.config, ...newConfig };
  }
}

export { RequestLogger };