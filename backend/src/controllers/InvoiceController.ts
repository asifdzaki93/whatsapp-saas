import { Request, Response } from "express";
import * as Yup from "yup";
import AppError from "../errors/AppError";
import Invoices from "../models/Invoices";
import { Op } from "sequelize";

export const index = async (req: Request, res: Response): Promise<Response> => {
  const { searchParam, pageNumber } = req.query as { searchParam: string; pageNumber: string | number };

  const whereCondition = {
    companyId: req.user.companyId
  };

  const limit = 20;
  const offset = (Number(pageNumber) - 1) * limit;

  const { count, rows: invoices } = await Invoices.findAndCountAll({
    where: whereCondition,
    limit,
    offset,
    order: [["createdAt", "DESC"]]
  });

  return res.json({
    invoices,
    count,
    hasMore: count > offset + invoices.length
  });
};

export const store = async (req: Request, res: Response): Promise<Response> => {
  const schema = Yup.object().shape({
    companyId: Yup.number().required(),
    detail: Yup.string().required(),
    value: Yup.number().required(),
    dueDate: Yup.string().required(),
    status: Yup.string().required()
  });

  if (!(await schema.isValid(req.body))) {
    throw new AppError("Validation fails", 400);
  }

  const { companyId, detail, value, dueDate, status } = req.body;

  // Cek invoice yang sudah ada dengan detail yang sama
  const existingInvoice = await Invoices.findOne({
    where: {
      companyId,
      detail,
      status: "pending",
      dueDate: {
        [Op.gte]: new Date(Date.now() - 24 * 60 * 60 * 1000) // Cek invoice dalam 24 jam terakhir
      }
    }
  });

  if (existingInvoice) {
    throw new AppError("Invoice dengan detail yang sama sudah ada", 400);
  }

  const invoice = await Invoices.create({
    companyId,
    detail,
    value,
    dueDate,
    status
  });

  return res.json(invoice);
};

export const show = async (req: Request, res: Response): Promise<Response> => {
  const { id } = req.params;

  const invoice = await Invoices.findByPk(id);

  if (!invoice) {
    throw new AppError("Invoice not found", 404);
  }

  return res.json(invoice);
};

export const update = async (req: Request, res: Response): Promise<Response> => {
  const schema = Yup.object().shape({
    detail: Yup.string(),
    value: Yup.number(),
    dueDate: Yup.string(),
    status: Yup.string()
  });

  if (!(await schema.isValid(req.body))) {
    throw new AppError("Validation fails", 400);
  }

  const { id } = req.params;
  const { detail, value, dueDate, status } = req.body;

  const invoice = await Invoices.findByPk(id);

  if (!invoice) {
    throw new AppError("Invoice not found", 404);
  }

  await invoice.update({
    detail,
    value,
    dueDate,
    status
  });

  return res.json(invoice);
};

export const remove = async (req: Request, res: Response): Promise<Response> => {
  const { id } = req.params;

  const invoice = await Invoices.findByPk(id);

  if (!invoice) {
    throw new AppError("Invoice not found", 404);
  }

  await invoice.destroy();

  return res.status(204).send();
}; 