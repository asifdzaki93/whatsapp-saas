import { Router } from "express";
import isAuth from "../middleware/isAuth";
import * as SubscriptionController from "../controllers/SubscriptionController";

const subscriptionRoutes = Router();

subscriptionRoutes.get("/subscription", isAuth, SubscriptionController.index);
subscriptionRoutes.post("/subscription/payment", isAuth, SubscriptionController.createPayment);
subscriptionRoutes.post("/subscription/webhook", SubscriptionController.webhook);

export default subscriptionRoutes; 