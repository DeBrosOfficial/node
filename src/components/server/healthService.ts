import express from 'express';
import { getConnectedPeers } from '@debros/network';
import { config } from '../../config';

/**
 * Registers health check endpoints
 */
export const registerHealthEndpoints = (app: express.Application) => {
  // Health check endpoint that also reports node load and peers
  app.get('/health', (req, res) => {
    const connectedPeers = getConnectedPeers();
    const peerCount = connectedPeers.size;

    res.json({
      status: 'healthy',
      load: `10%`,
      peerCount,
      fingerprint: config.env.fingerprint || 'unknown',
    });
  });
};

/**
 * Reports status information periodically
 */
export const startStatusReporting = (interval = 600000) => {
  // 10 minutes by default
  // Schedule a status report every 10 minutes
  return setInterval(() => {
    const connectedPeers = getConnectedPeers();
    const peerCount = connectedPeers.size;

    console.log('==== DEBROS STATUS REPORT ====');
    console.log(`📊 Fingerprint: ${config.env.fingerprint}`);
    console.log(`📊 Active connections: 0`);
    console.log(`📊 Current load: 10%`);
    console.log(`📊 Connected P2P peers: ${peerCount}`);
    console.log('==================================');

    // Enhance with peer details if there are peers connected
    if (peerCount > 0) {
      console.log('CONNECTED PEERS:');
      connectedPeers.forEach((peer, i) => {
        // Adjust based on your peer structure from the new @debros/network
        const peerId = peer.fingerprint || peer.toString();
        const load = peer.load || 'unknown';
        console.log(`${i + 1}. ${peerId.substring(0, 15)}... - Load: ${load}%`);
      });
      console.log('==================================');
    }
  }, interval);
};
