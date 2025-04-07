import express from 'express';
import cors from 'cors';
import morgan from 'morgan';

/**
 * Applies express middleware to the application
 */
export const applyMiddleware = (app: express.Application) => {
  // CORS configuration
  app.use(
    cors({
      origin: (origin, callback) => {
        const allowedOrigins = ['http://localhost:4001'];
        if (!origin || allowedOrigins.includes(origin)) {
          callback(null, true);
        } else {
          callback(new Error('Not allowed by CORS'));
        }
      },
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: '*',
      credentials: true,
    })
  );

  // Apply HTTP request logging middleware
  app.use(morgan('dev')); // Standard HTTP logging
  app.use(loggingMiddleware); // Custom detailed logging

  // JSON parser middleware
  app.use(express.json());

  // Error handling middleware (must come after other middleware/routes)
  app.use(errorHandlingMiddleware);
};

/**
 * Custom logging middleware with detailed request/response tracking
 */
export const loggingMiddleware = (req: express.Request, res: express.Response, next: express.NextFunction) => {
  const start = Date.now();

  // Log request start
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url} - Request started`);

  // Function to log response
  const logResponse = () => {
    const duration = Date.now() - start;
    const statusCode = res.statusCode;
    const statusColor =
      statusCode >= 500
        ? '\x1b[31m' // Red
        : statusCode >= 400
          ? '\x1b[33m' // Yellow
          : statusCode >= 300
            ? '\x1b[36m' // Cyan
            : statusCode >= 200
              ? '\x1b[32m' // Green
              : '\x1b[0m'; // Default

    console.log(
      `${statusColor}[${new Date().toISOString()}] ${req.method} ${req.url} - ${statusCode} - ${duration}ms\x1b[0m`
    );
  };

  // Capture response finish event
  res.on('finish', logResponse);

  next();
};

/**
 * Global error handling middleware
 */
export const errorHandlingMiddleware = (
  err: any,
  _req: express.Request,
  res: express.Response,
  _next: express.NextFunction // Add the 'next' parameter
) => {
  console.error(err.stack);
  res.status(500).json({
    error: {
      message: 'An unexpected error occurred',
      detail: process.env.NODE_ENV === 'development' ? err.message : undefined,
    },
  });
  // Optionally call next(err) if you want to pass the error to another handler
};
