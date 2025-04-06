// In a declaration file (e.g., types/express/index.d.ts)
declare namespace Express {
  export interface Request {
    user?: any; // Or define a more specific type for your user
  }
}
