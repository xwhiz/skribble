import type { Request, Response, NextFunction } from "express";

export function logging(logger = console.log) {
  return function (req: Request, res: Response, next: NextFunction) {
    logger(`Received: [${req.method}] ${req.originalUrl}`);

    let start = Date.now();
    res.on("finish", function onRequestFinish() {
      let duration = Date.now() - start;
      let log = `[${new Date().toISOString()}] ${req.method} ${
        req.originalUrl
      } ${res.statusCode} - ${duration}ms`;

      logger(log);
    });

    next();
  };
}
