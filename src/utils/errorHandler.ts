import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { createServiceLogger } from './logger';

const logger = createServiceLogger('ERROR');

// Error types for different HTTP status codes
export class HttpError extends Error {
  status: number;

  constructor(message: string, status: number = 500) {
    super(message);
    this.name = this.constructor.name;
    this.status = status;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class BadRequestError extends HttpError {
  constructor(message: string) {
    super(message, 400);
  }
}

export class UnauthorizedError extends HttpError {
  constructor(message: string = 'Unauthorized') {
    super(message, 401);
  }
}

export class ForbiddenError extends HttpError {
  constructor(message: string = 'Forbidden') {
    super(message, 403);
  }
}

export class NotFoundError extends HttpError {
  constructor(message: string = 'Resource not found') {
    super(message, 404);
  }
}

export class ValidationError extends BadRequestError {
  errors: any[];

  constructor(message: string, errors: any[]) {
    super(message);
    this.errors = errors;
  }
}

// Error handler middleware
export const errorHandler = (err: Error, req: Request, res: Response, _next: NextFunction) => {
  logger.error(`Error processing ${req.method} ${req.url}:`, err);

  if (err instanceof HttpError) {
    // Handle custom HTTP errors
    const response: any = {
      error: {
        message: err.message,
        status: err.status,
      },
    };

    // Add validation errors if present
    if (err instanceof ValidationError) {
      response.error.details = err.errors;
    }

    return res.status(err.status).json(response);
  } else if (err instanceof z.ZodError) {
    // Handle Zod validation errors
    return res.status(400).json({
      error: {
        message: 'Validation failed',
        status: 400,
        details: err.errors.map((e) => ({
          path: e.path.join('.'),
          message: e.message,
        })),
      },
    });
  }

  // Handle unexpected errors
  const statusCode = 500;
  const isProduction = process.env.NODE_ENV === 'production';

  return res.status(statusCode).json({
    error: {
      message: isProduction ? 'Internal server error' : err.message,
      status: statusCode,
      stack: isProduction ? undefined : err.stack,
    },
  });
};

// Async route handler to catch promise rejections
export const asyncHandler = (fn: (req: Request, res: Response, next: NextFunction) => Promise<any>) => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// Function to handle validation with Zod
export const validateRequest = (schema: z.ZodTypeAny) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      schema.parse(req.body);
      next();
    } catch (error) {
      if (error instanceof z.ZodError) {
        next(new ValidationError('Validation failed', error.errors));
      } else {
        next(error);
      }
    }
  };
};
