import { Router } from "express";
import isAuth from "../middleware/isAuth";
import * as InvoiceController from "../controllers/InvoiceController";

const invoiceRoutes = Router();

invoiceRoutes.get("/invoices", isAuth, InvoiceController.index);
invoiceRoutes.post("/invoices", isAuth, InvoiceController.store);
invoiceRoutes.get("/invoices/:id", isAuth, InvoiceController.show);
invoiceRoutes.put("/invoices/:id", isAuth, InvoiceController.update);
invoiceRoutes.delete("/invoices/:id", isAuth, InvoiceController.remove);

export default invoiceRoutes; 