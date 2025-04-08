import express from 'express';
import { createServer } from 'http';
import network, { createServiceLogger, logPeersStatus } from '@debros/network'; // Import from the new package
import mainRouter from '../../routes/api';
import { applyMiddleware } from './middleware';
import { registerHealthEndpoints, startStatusReporting } from './healthService';
import { initAnyone } from '../anyone/setup';
import { config } from '../../config';

// Create loggers for different service types
const serverLogger = createServiceLogger('SERVER');

export const createApp: any = () => {
  const app = express();

  applyMiddleware(app);
  registerHealthEndpoints(app);
  app.use('/api', mainRouter);

  return app;
};

export const startServer = async () => {
  let anonInstance: any = null;
  let statusReportInterval: NodeJS.Timeout;
  let peerStatusInterval: NodeJS.Timeout;
  let orbitdbInstance: any;

  try {
    showModeBanner();

    // Initialize Anyone service
    const { anon } = await initAnyone();
    anonInstance = anon;

    // Initialize IPFS with the new package

    // Initialize OrbitDB with the new package
    orbitdbInstance = await network.db.init()

    // Create and configure Express app
    const app = createApp();
    const httpServer = createServer(app);

    // Start the HTTP server
    const port = config.env.port;
    httpServer.listen(port, () => {
      serverLogger.info(`Server running on port ${port}`);

      // Start periodic peer status logging
      peerStatusInterval = setInterval(() => {
        logPeersStatus();
      }, 60000); // Log status every minute

      // Start status reporting
      statusReportInterval = startStatusReporting();

      // Setup shutdown handler after all intervals are defined
      setupShutdownHandler(anonInstance, orbitdbInstance, {
        statusReportInterval,
        peerStatusInterval,
      });
    });
  } catch (error) {
    serverLogger.error('Failed to initialize services:', error);
    if (anonInstance) await anonInstance.stop();
    throw error;
  }
};

/**
 * Displays the mode banner with environment information
 */
function showModeBanner() {
  if (config.env.isDevelopment) {
    serverLogger.info('========================================');
    serverLogger.info('🚀 Running in DEVELOPMENT MODE');
    serverLogger.info(`🔑 Anyone Protocol: ${config.features.enableAnyone ? 'ENABLED' : 'DISABLED'}`);
    serverLogger.info(`🔖 Fingerprint: ${config.env.fingerprint}`);
    serverLogger.info('========================================');
  } else {
    serverLogger.info('========================================');
    serverLogger.info('🚀 Running in PRODUCTION MODE');
    serverLogger.info(`🔑 Anyone Protocol: ${config.features.enableAnyone ? 'ENABLED' : 'DISABLED'}`);
    serverLogger.info(`🔖 Fingerprint: ${config.env.fingerprint}`);
    serverLogger.info('========================================');
  }
}

function setupShutdownHandler(
  anonInstance: any,
  orbitdbInstance: any,
  intervals: {
    statusReportInterval: NodeJS.Timeout;
    peerStatusInterval: NodeJS.Timeout;
  }
) {
  process.on('SIGINT', async () => {
    serverLogger.info('Shutting down...');

    // Clear intervals
    clearInterval(intervals.statusReportInterval);
    clearInterval(intervals.peerStatusInterval);

    // Stop IPFS
    serverLogger.info('Stopping Network...');
    await network.db.stop();
    serverLogger.info('Network stopped.');

    // Stop Anyone
    if (anonInstance) {
      serverLogger.info('Stopping Anyone Protocol...');
      await anonInstance.stop();
      serverLogger.info('Anyone Protocol stopped.');
    }

    process.exit(0);
  });
}
