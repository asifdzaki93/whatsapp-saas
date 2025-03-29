import "./bootstrap";
import "reflect-metadata";
import "express-async-errors";
import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import cookieParser from "cookie-parser";
import * as Sentry from "@sentry/node";

import "./database";
import uploadConfig from "./config/upload";
import AppError from "./errors/AppError";
import routes from "./routes";
import invoiceRoutes from "./routes/invoiceRoutes";
import { logger } from "./utils/logger";
import { messageQueue, sendScheduledMessages } from "./queues";

Sentry.init({ dsn: process.env.SENTRY_DSN });

const app = express();

app.set("queues", {
  messageQueue,
  sendScheduledMessages
});

app.use(
  cors({
    credentials: true,
    origin: [process.env.FRONTEND_URL, "http://localhost:3000", "http://localhost:8080", "http://10.0.2.2:8080", "http://192.168.100.164:9003"]
  })
);
app.use(cookieParser());
app.use(express.json());
app.use(Sentry.Handlers.requestHandler());
app.use("/public", express.static(uploadConfig.directory));
app.use(routes);
app.use(invoiceRoutes);

app.use(Sentry.Handlers.errorHandler());

app.use(async (err: Error, req: Request, res: Response, _: NextFunction) => {
  if (err instanceof AppError) {
    logger.warn("Error aplikasi:", err);
    return res.status(err.statusCode).json({ error: err.message });
  }

  logger.error("Error server internal:", err);
  return res.status(500).json({ error: "Terjadi kesalahan pada server. Silakan coba lagi nanti." });
});

export default app;
