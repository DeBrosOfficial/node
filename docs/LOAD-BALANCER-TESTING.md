# Load Balancer Testing Guide

This guide describes how to test the IPFS service discovery and load balancing system implemented in the DeBros Relay.

## Prerequisites

- Node.js and pnpm installed
- DeBros Relay codebase
- Multiple terminal windows

## Setting Up the Test Environment

### 1. Install Dependencies

First, make sure all required dependencies are installed:

```bash
pnpm install
```

### 2. Start Multiple Nodes

To test load balancing, you need to start multiple relay nodes with different configurations. Open separate terminal windows for each node.

**Node 1 (Primary):**

```bash
FINGERPRINT=node-1 PORT=7777 pnpm run dev
```

**Node 2:**

```bash
FINGERPRINT=node-2 PORT=6002 pnpm run dev
```

**Node 3:**

```bash
FINGERPRINT=node-3 PORT=6003 pnpm run dev
```

### 3. Verify Node Discovery

After starting the nodes, they should automatically discover each other via IPFS pubsub. Check the logs to verify that the nodes are discovering each other:

```
[SERVICE-DISCOVERY] New peer discovered: k51qzi5uqu5dl... (node-2)
[IPFS] Connected to peer: k51qzi5uqu5dl...
```

You should see periodic status reports showing connected peers:

```
==== DeBros RELAY STATUS REPORT ====
📊 Fingerprint: node-1
📊 Active connections: 3
📊 Current load: 1%
📊 Connected P2P peers: 2
==================================
CONNECTED PEERS:
1. k51qzi5uqu5dl... - Load: 5%
2. k51qzi5uqu5aa... - Load: 15%
==================================
```

## Testing Load Balancing

### 1. Using HTTP Requests

You can use the provided `load-balancer.http` file with tools like Visual Studio Code's REST Client extension or curl to test the API endpoints.

**Check Node Info:**

```
GET http://localhost:7777/api/discovery/node-info
```

**Get Optimal Peer:**

```
GET http://localhost:7777/api/discovery/optimal-peer
```

**Get All Peers:**

```
GET http://localhost:7777/api/discovery/peers
```

**Health Check:**

```
GET http://localhost:7777/health
```

### 2. Testing Different Load Balancing Strategies

You can test different load balancing strategies by changing the environment variable:

```bash
LOAD_BALANCING_STRATEGY=round-robin FINGERPRINT=node-1 PORT=7777 pnpm run dev
```

Available strategies:

- `least-loaded` (default): Chooses the node with the lowest load
- `round-robin`: Cycles through all available nodes
- `random`: Randomly selects a node

### 3. Simulating Load

To properly test load balancing, you need to simulate different loads on the nodes. You can do this by establishing WebSocket connections to different nodes:

**Simple WebSocket test script:**

```javascript
// save as test-connections.js
const { io } = require('socket.io-client');

const NUM_CONNECTIONS = 50; // Number of connections to create
const TARGET_PORT = 7777; // Port of the node to connect to

const connections = [];

function connect() {
  for (let i = 0; i < NUM_CONNECTIONS; i++) {
    const socket = io(`http://localhost:${TARGET_PORT}`, {
      auth: {
        walletAddress: `0x${i.toString(16).padStart(40, '0')}`,
        signature: 'dummy-signature-for-testing',
      },
    });

    socket.on('connect', () => {
      console.log(`Connection ${i} established`);
    });

    connections.push(socket);
  }
}

connect();

// Keep the script running
process.stdin.resume();

// Clean up on exit
process.on('SIGINT', () => {
  console.log('Closing all connections...');
  connections.forEach((socket) => socket.disconnect());
  process.exit();
});
```

Run this script to create connections to one of your nodes:

```bash
node test-connections.js
```

You can modify the script to target different nodes and create varying levels of load.

### 4. Monitoring Results

As you create connections, each node should update its load metrics and broadcast this information to other nodes via pubsub. You should see log messages indicating updates to the load:

```
[LOAD-BALANCER] Current load: 30% (300 connections)
```

Then, when querying the optimal peer endpoint, you should see responses directing clients to the node with the lowest load:

```json
{
  "useThisNode": false,
  "optimalPeer": {
    "peerId": "k51qzi5uqu5dllthquketj8ds6vf0s5kkm7p3ybmzz32vr46tgqcm2sic0pxwk",
    "load": 10
  },
  "message": "Found optimal peer"
}
```

## Integrating with Client Applications

To integrate load balancing with client applications, the client should:

1. Initially connect to any known relay node
2. Query the `/api/discovery/optimal-peer` endpoint
3. If `useThisNode` is `false`, disconnect and connect to the optimal peer
4. Periodically check for better nodes (every few minutes)

**Example Client Integration:**

```javascript
async function connectToOptimalRelay() {
  // Start with a known relay
  const initialRelay = 'http://localhost:7777';

  try {
    // Query for optimal peer
    const response = await fetch(`${initialRelay}/api/discovery/optimal-peer`);
    const data = await response.json();

    if (data.useThisNode) {
      console.log(`Using initial relay: ${initialRelay}`);
      return initialRelay;
    } else {
      // Convert peer ID to a URL (implementation depends on your setup)
      const optimalRelayUrl = peerIdToUrl(data.optimalPeer.peerId);
      console.log(`Switching to optimal relay: ${optimalRelayUrl}`);
      return optimalRelayUrl;
    }
  } catch (error) {
    console.error('Error finding optimal relay:', error);
    return initialRelay; // Fall back to initial relay
  }
}

// Connect to the best relay
const relayUrl = await connectToOptimalRelay();
const socket = io(relayUrl, {
  auth: {
    walletAddress: userWalletAddress,
    signature: signature,
  },
});
```

## Troubleshooting

### Nodes Not Discovering Each Other

1. Check that the PubSub service is properly initialized
2. Verify that all nodes are using the same service discovery topic
3. Check if there are any network restrictions preventing P2P communication
4. Try setting explicit bootstrap nodes in the configuration

### High CPU/Memory Usage

1. Adjust the heartbeat interval to a higher value
2. Reduce the verbosity of logging in a production environment
3. Consider optimizing the peer discovery mechanism for larger deployments

### Load Balancing Not Working as Expected

1. Check the logs to see if load metrics are being calculated and broadcasted correctly
2. Ensure that the stale peer timeout is set appropriately
3. Try different load balancing strategies to see which works best for your use case
