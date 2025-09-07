import app from './app';
import { connectDB } from './config/database';
import { log } from './utils/logger';

const PORT = process.env.PORT || 3000;

// Connect to database before starting server
const startServer = async () => {
  try {
    await connectDB();
    
    app.listen(PORT, () => {
      log.info('School Bus System API started successfully', { 
        port: PORT,
        endpoints: {
          health: `http://localhost:${PORT}/health`,
          docs: `http://localhost:${PORT}/`
        }
      });
    });
  } catch (error) {
    log.error('Failed to start server', { error: error instanceof Error ? error.message : error });
    process.exit(1);
  }
};

startServer();

// Graceful shutdown
process.on('SIGTERM', () => {
  log.info('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  log.info('SIGINT received, shutting down gracefully');
  process.exit(0);
});
