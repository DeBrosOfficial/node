import { Request, Response, NextFunction } from 'express';
import { ethers } from 'ethers';

export const authMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const walletAddress = req.headers['wallet-address'] as string;
  const signature = req.headers['signature'] as string;
  const message = 'Sign this message to authenticate';

  try {
    const recoveredAddress = ethers.verifyMessage(message, signature);
    if (recoveredAddress.toLowerCase() === walletAddress.toLowerCase()) {
      next(); // Το request είναι έγκυρο, συνεχίζουμε
    } else {
      res.status(401).json({ error: 'Unauthorized' });
    }
  } catch (_error) {
    res.status(401).json({ error: 'Invalid signature' });
  }
};
