/**
 * DEPRECATED: Legacy tender vault rotation service.
 * Exposure-based rotation is the only supported system.
 */

const deprecationMessage =
  "Legacy tenderVaultRotation service is disabled. Use tenderVaultExposureService only.";

export function generateTemporaryClientId() {
  return null;
}

export async function performDailyRotation() {
  console.warn(`[DEPRECATED] ${deprecationMessage}`);
  return { success: false, activated: 0, deprecated: true };
}

export async function checkAndExpireActiveTenders() {
  console.warn(`[DEPRECATED] ${deprecationMessage}`);
  return { success: false, expired: 0, deprecated: true };
}

export async function convertTenderToOrder() {
  throw new Error(
    "Legacy convertTenderToOrder() is disabled; Tender Vault exposures are non-actionable."
  );
}
