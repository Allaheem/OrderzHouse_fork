/**
 * DEPRECATED: Legacy tender pool rotation service.
 * Exposure-based rotation is the only supported system.
 */

const deprecationMessage =
  "Legacy tenderPoolRotation service is disabled. Use tenderVaultExposureService only.";

export async function expireRotatedTenders() {
  console.warn(`[DEPRECATED] ${deprecationMessage}`);
  return 0;
}

export async function countVisibleInPool() {
  return 0;
}

export async function selectEligibleTenders() {
  return [];
}

export async function activateBatch() {
  return 0;
}

export async function countPublishedTenders() {
  return 0;
}

export async function runRotation() {
  console.warn(`[DEPRECATED] ${deprecationMessage}`);
  return { expired: 0, activated: 0, visible: 0, skipped: true, totalPublished: 0 };
}
