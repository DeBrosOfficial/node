import express, { Router, Request, Response } from 'express';
import { loadBalancerController } from '@debros/network';

const mainRouter: Router = express.Router();

// Load balancer routes (no auth required for discovery)
mainRouter.get('/discovery/node-info', loadBalancerController.getNodeInfo);
mainRouter.get('/discovery/optimal-peer', loadBalancerController.getOptimalPeer);
mainRouter.get('/discovery/peers', loadBalancerController.getAllPeers);

// Global error handler
mainRouter.use((err: any, req: Request, res: Response) => {
  console.error('API Error:', err);
  const statusCode = err.status || 500;
  const errorResponse: any = {
    error: {
      message: err.message || 'Internal Server Error',
      status: statusCode,
    },
  };

  // Add validation details if available
  if (err.errors) {
    errorResponse.error.details = err.errors;
  }

  // In production, don't send the stack trace
  if (process.env.NODE_ENV !== 'production' && err.stack) {
    errorResponse.error.stack = err.stack;
  }

  res.status(statusCode).json(errorResponse);
});

export default mainRouter;
