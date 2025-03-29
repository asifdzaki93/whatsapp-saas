import {
  WASocket,
  BinaryNode,
  Contact as BContact
} from "@whiskeysockets/baileys";
import * as Sentry from "@sentry/node";

import { Op } from "sequelize";
// import { getIO } from "../../libs/socket";
import { Store } from "../../libs/store";
import Contact from "../../models/Contact";
import Setting from "../../models/Setting";
import Ticket from "../../models/Ticket";
import Whatsapp from "../../models/Whatsapp";
import { logger } from "../../utils/logger";
import createOrUpdateBaileysService from "../BaileysServices/CreateOrUpdateBaileysService";
import CreateMessageService from "../MessageServices/CreateMessageService";
import { debounce } from "../../helpers/Debounce";

type Session = WASocket & {
  id?: number;
  store?: Store;
};

interface IContact {
  contacts: BContact[];
}

const wbotMonitor = async (
  wbot: Session,
  whatsapp: Whatsapp,
  companyId: number
): Promise<void> => {
  try {
    if (!whatsapp || !whatsapp.id) {
      logger.error("Koneksi WhatsApp tidak ditemukan");
      return;
    }

    wbot.ev.on("call", async call => {
      try {
        for (const c of call) {
          if (c.status === "offer") {
            const msg = await wbot.sendMessage(c.from, {
              text: "Maaf, kami tidak menerima panggilan suara. Silakan kirim pesan teks."
            });
          }
        }
      } catch (error) {
        logger.error("Error saat menangani panggilan:", error);
      }
    });

    wbot.ev.on("contacts.upsert", async (contacts: BContact[]) => {
      await createOrUpdateBaileysService({
        whatsappId: whatsapp.id,
        contacts
      });
    });
  } catch (err) {
    Sentry.captureException(err);
    logger.error("Error pada wbotMonitor:", err);
  }
};

export default wbotMonitor;
