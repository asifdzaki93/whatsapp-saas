import { Server as SocketIO } from "socket.io";
import { Server } from "http";
import AppError from "../errors/AppError";
import { logger } from "../utils/logger";
import User from "../models/User";

let io: SocketIO;

export const initIO = (httpServer: Server): SocketIO => {
  io = new SocketIO(httpServer, {
    cors: {
      origin: [process.env.FRONTEND_URL, "http://localhost:3000", "http://localhost:8080", "http://10.0.2.2:8080", "http://192.168.100.164:9003"],
      credentials: true
    }
  });

  io.on("connection", async socket => {
    logger.info("Client Connected");
    const { userId } = socket.handshake.query;

    if (userId && userId !== "undefined" && userId !== "null") {
      const user = await User.findByPk(userId);
      if (user) {
        user.online = true;
        await user.save();
      }
    }

    socket.on("joinChatBox", (ticketId: string) => {
      logger.info("A client joined a ticket channel");
      socket.join(ticketId);
    });

    socket.on("joinNotification", () => {
      logger.info("A client joined notification channel");
      socket.join("notification");
    });

    socket.on("joinTickets", (status: string) => {
      logger.info(`A client joined to ${status} tickets channel.`);
      socket.join(status);
    });
  });
  return io;
};

export const getIO = (): SocketIO => {
  if (!io) {
    throw new AppError("Socket IO not initialized");
  }
  return io;
};
