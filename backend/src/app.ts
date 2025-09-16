import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
import path from 'path';
import { RequestLogger } from './middlewares/requestLogger';
import requestLoggerConfig, { isRequestLoggingEnabled } from './config/requestLogger';
import { log } from './utils/logger';

// Import routes
import authRoutes from './routes/auth';
import lineRoutes from './routes/lines';
import vehicleRoutes from './routes/vehicles';
import invitationRoutes from './routes/invitations';
import rideRoutes from './routes/rides';
import bookingRoutes from './routes/bookings';
import jobsRoutes from './routes/jobs';
import registrationRoutes from './routes/registrations';
import registrationRequestRoutes from './routes/registrationRequests';

// Load environment variables
dotenv.config();

const app = express();

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000', 'http://localhost:5173'],
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware (after body parsing to capture request body)
if (isRequestLoggingEnabled) {
  const requestLogger = new RequestLogger(log, requestLoggerConfig);
  app.use(requestLogger.middleware());
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'School Bus System API'
  });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/lines', lineRoutes);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/invitations', invitationRoutes);
app.use('/api/rides', rideRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/jobs', jobsRoutes);
app.use('/api/registrations', registrationRoutes);
app.use('/api/registration-requests', registrationRequestRoutes);

// Serve static files from the frontend build
const publicPath = path.join(__dirname, 'public');
app.use(express.static(publicPath));

// Catch-all handler: send back Vue's index.html file for any non-API routes
app.use((req, res, next) => {
  // Skip API routes
  if (req.path.startsWith('/api/') || req.path === '/health') {
    return res.status(404).json({ message: 'API endpoint not found' });
  }
  
  // Serve the frontend for all other routes (SPA routing)
  res.sendFile(path.join(publicPath, 'index.html'));
});



// Error handling middleware
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  res.status(500).json({ 
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

export default app;
