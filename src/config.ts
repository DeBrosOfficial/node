import path from 'path';

export const config = {
  env: {
    isDevelopment: process.env.NODE_ENV !== 'production',
    port: process.env.PORT || 7777,
    fingerprint: process.env.FINGERPRINT || 'default-fingerprint', // Fingerprint from .env
    nickname: process.env.NICKNAME,
    keyPath: process.env.KEY_PATH || '/var/lib/debros/keys',
    host: process.env.HOST || '',
  },
  features: {
    enableAnyone: process.env.ENABLE_ANYONE === 'true',
    enableLoadBalancing: process.env.ENABLE_LOAD_BALANCING !== 'false',
  },
  ipfs: {
    repo: './ipfs-repo',
    swarmKey: path.resolve(process.cwd(), 'swarm.key'),
    bootstrapNodes: process.env.BOOTSTRAP_NODES,
    blockstorePath: path.resolve(process.cwd(), 'blockstore'),
    serviceDiscovery: {
      topic: process.env.SERVICE_DISCOVERY_TOPIC || 'debros-service-discovery',
      heartbeatInterval: parseInt(process.env.HEARTBEAT_INTERVAL || '5000'),
      staleTimeout: parseInt(process.env.STALE_PEER_TIMEOUT || '30000'),
      logInterval: parseInt(process.env.PEER_LOG_INTERVAL || '60000'),
      publicAddress: process.env.NODE_PUBLIC_ADDRESS || `http://localhost:${process.env.PORT || 7777}`,
    },
  },
  orbitdb: {
    directory: path.resolve(process.cwd(), 'orbitdb/debros'),
  },
  loadBalancer: {
    maxConnections: parseInt(process.env.MAX_CONNECTIONS || '1000'),
    strategy: process.env.LOAD_BALANCING_STRATEGY || 'least-loaded',
  },
};
