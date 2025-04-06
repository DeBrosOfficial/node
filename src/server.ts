import dotenv from 'dotenv';
import { config } from './config';
import { startServer } from './components/server/serverService';
import { createServiceLogger } from './utils/logger';

const logger = createServiceLogger('SERVER');

// Load environment variables from .env file
dotenv.config();

// Update config with environment variables
config.env.isDevelopment = process.env.NODE_ENV !== 'production';
config.env.port = parseInt(process.env.PORT || '7777');
config.features.enableAnyone = process.env.ENABLE_ANYONE === 'true' || process.env.NODE_ENV === 'production';

// Export default function to be called from CLI
export default startServer;

// If this script is run directly (not imported)
if (import.meta.url === `file://${process.argv[1]}`) {
  startServer().catch((error) => {
    logger.error('Failed to start server:', error);
    process.exit(1);
  });
}
