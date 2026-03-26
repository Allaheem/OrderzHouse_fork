/**
 * DEPRECATED: Legacy tender rotation engine.
 * Exposure-based rotation is the only supported system.
 */

const deprecationMessage =
  "Legacy tenderRotationEngine is disabled. Use tenderVaultExposureService only.";

export async function expireActiveCycles() {
  return 0;
}

export async function countActiveCycles() {
  return 0;
}

export async function selectEligibleTenders() {
  return [];
}

export async function runTenderRotation() {
  console.warn(`[DEPRECATED] ${deprecationMessage}`);
  return { expired: 0, active: 0, created: 0, executionTimeMs: 0, skipped: true };
}
