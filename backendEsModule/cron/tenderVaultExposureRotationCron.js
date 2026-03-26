import cron from "node-cron";
import { runTenderVaultExposureRotation } from "../services/tenderVaultExposureService.js";

export function registerTenderVaultExposureRotationCron() {
  cron.schedule("0 */12 * * *", async () => {
    try {
      const result = await runTenderVaultExposureRotation();
      if (result.skipped) {
        console.log(
          `[TenderVaultExposureRotation] skipped: eligible=${result.eligibleCount} (min=300)`
        );
        return;
      }
      console.log(
        `[TenderVaultExposureRotation] expired=${result.expiredCount} activated=${result.activatedCount} eligible=${result.eligibleCount}`
      );
    } catch (error) {
      console.error("[TenderVaultExposureRotation] Error:", error);
    }
  });

  console.log("✅ Tender Vault Exposure Cron started (every 12 hours)");
}
