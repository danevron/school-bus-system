import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';

// Import routes
import authRoutes from './routes/auth';
import lineRoutes from './routes/lines';
import bookingRoutes from './routes/bookings';
import routeRoutes from './routes/routes';
import vehicleRoutes from './routes/vehicles';
import rideRoutes from './routes/rides';
import invitationRoutes from './routes/invitations';

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
app.use('/api/bookings', bookingRoutes);
app.use('/api/routes', routeRoutes);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/rides', rideRoutes);
app.use('/api/invitations', invitationRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'School Bus System API is running',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      lines: '/api/lines',
      bookings: '/api/bookings',
      routes: '/api/routes',
      vehicles: '/api/vehicles',
      rides: '/api/rides',
      invitations: '/api/invitations'
    }
  });
});

// 404 handler
// app.use(':wildcard(*)', (req, res) => {
//   res.status(404).json({ message: 'Endpoint not found' });
// });


// Error handling middleware
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  res.status(500).json({ 
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

export default app;
