import { Anon, AnonSocksClient } from '@anyone-protocol/anyone-client';
import { HttpsProxyAgent } from 'https-proxy-agent';
import { config } from '../../config';

interface InitAnyoneResponse {
  socksClient: AnonSocksClient | null;
  proxyAgent: any;
  anon: Anon | null; // Expose anon instance for later cleanup
}

export const initAnyone = async (): Promise<InitAnyoneResponse> => {
  // Check if Anyone protocol is disabled in development mode
  if (!config.features.enableAnyone) {
    console.log('🚫 Anyone Network disabled in development mode.');
    // Return mock objects to avoid errors in dependent code
    return {
      socksClient: null,
      proxyAgent: null,
      anon: null,
    };
  }

  const anon = new Anon({
    displayLog: true,
    socksPort: 9060,
  });
  let socksClient: any;
  let proxyAgent: any;

  try {
    await anon.start();
    console.log('✅ Anyone Network connected.');

    socksClient = new AnonSocksClient(anon);
    proxyAgent = new HttpsProxyAgent(`socks5h://127.0.0.1:${socksClient.socksPort}`);
    console.log('✅ Proxy agent initialized on port:', socksClient.socksPort);

    // Do NOT stop anon here; keep it running for the proxy
  } catch (err: unknown) {
    console.error('❌ Error starting Anyone client:', err);
    throw err; // Propagate the error to handle it upstream
  }

  return { socksClient, proxyAgent, anon };
};
