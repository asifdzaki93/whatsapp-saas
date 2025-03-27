import { Request, Response } from "express";
import express from "express";
import * as Yup from "yup";
import Gerencianet from "gn-api-sdk-typescript";
import AppError from "../errors/AppError";
import { snap } from "../config/midtrans";
import { Op } from "sequelize";

import options from "../config/Gn";
import Company from "../models/Company";
import Invoices from "../models/Invoices";
import { getIO } from "../libs/socket";

interface User {
  id: string;
  profile: string;
  companyId: number;
  email?: string;
  name?: string;
  phone?: string;
}

interface RequestWithUser extends Request {
  user: User;
}

const app = express();

export const index = async (req: Request, res: Response): Promise<Response> => {
  const gerencianet = Gerencianet(options);
  return res.json(gerencianet.getSubscriptions());
};

export const createPayment = async (
  req: RequestWithUser,
  res: Response
): Promise<Response> => {
  const { companyId } = req.user;

  const schema = Yup.object().shape({
    planId: Yup.string().required(),
    price: Yup.number().required(),
    users: Yup.number().required(),
    connections: Yup.number().required(),
    queues: Yup.number().required(),
    email: Yup.string().email(),
    name: Yup.string(),
    phone: Yup.string()
  });

  try {
    // Log request body untuk debugging
    console.log('Request body:', req.body);

    // Validasi request body
    const validatedData = await schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true
    });

    // Log validated data untuk debugging
    console.log('Validated data:', validatedData);

    const { planId, price, users, connections, queues, email, name, phone } = validatedData;

    // Cek apakah sudah ada subscription aktif
    const company = await Company.findByPk(companyId);
    if (!company) {
      throw new AppError("Company not found", 404);
    }

    if (company.dueDate && new Date(company.dueDate) > new Date()) {
      throw new AppError("Anda masih memiliki subscription aktif", 400);
    }

    // Buat order ID unik
    const orderId = `SUB-${companyId}-${Date.now()}`;
    
    // Parameter transaksi Midtrans
    const parameter = {
      transaction_details: {
        order_id: orderId,
        gross_amount: parseInt(price.toString())
      },
      item_details: [{
        id: planId,
        price: parseInt(price.toString()),
        quantity: 1,
        name: `Subscription - ${users} Pengguna, ${connections} Koneksi, ${queues} Antrian`
      }],
      customer_details: {
        email: email || req.user.email || "customer@example.com",
        first_name: name || req.user.name || "Customer",
        phone: phone || req.user.phone || "08111222333"
      },
      callbacks: {
        finish: `${process.env.FRONTEND_URL}/subscription/success`,
        error: `${process.env.FRONTEND_URL}/subscription/error`,
        pending: `${process.env.FRONTEND_URL}/subscription/pending`
      }
    };

    // Log parameter untuk debugging
    console.log('Midtrans parameter:', parameter);

    // Buat transaksi di Midtrans
    const transaction = await snap.createTransaction(parameter);

    return res.json({
      token: transaction.token,
      redirect_url: transaction.redirect_url,
      order_id: orderId
    });

  } catch (err) {
    console.error('Payment error:', err);
    if (err instanceof Yup.ValidationError) {
      throw new AppError(err.message, 400);
    }
    throw new AppError(err.message || "Error creating payment", 500);
  }
};

export const webhook = async (
  req: Request,
  res: Response
): Promise<Response> => {
  try {
    const notification = await snap.transaction.notification(req.body);
    
    const orderId = notification.order_id;
    const transactionStatus = notification.transaction_status;
    const fraudStatus = notification.fraud_status;
    const companyId = orderId.split('-')[1];

    console.log(`Transaction notification received. Order ID: ${orderId}. Status: ${transactionStatus}`);

    // Cari company
    const company = await Company.findByPk(companyId);
    if (!company) {
      throw new AppError("Company not found", 404);
    }

    // Process the transaction status
    if (transactionStatus === 'capture' || transactionStatus === 'settlement') {
      // Payment success
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 30);

      // Update company due date
      await company.update({
        dueDate: expiresAt
      });

      // Broadcast update via websocket
      const io = getIO();
      io.emit(`company-${company.id}-payment`, {
        action: transactionStatus,
        company: await Company.findByPk(company.id)
      });
    }

    return res.status(200).json({ status: 'ok' });
  } catch (error) {
    console.error('Webhook error:', error);
    return res.status(400).json({ status: 'error' });
  }
};
