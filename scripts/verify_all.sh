#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "== Backend checks =="
cd "$ROOT_DIR/backendEsModule"
npm test -- --runInBand
node --check controller/paypal/paypalPlanCheckout.js
node --check controller/plans-subscriptions/appleIapVerifyReceipt.js
node --check controller/plans-subscriptions/getSubscriptionStatus.js
node --check router/paypal.js

echo "== Mobile checks =="
cd "$ROOT_DIR/mobile_app"
flutter analyze --no-fatal-infos
flutter test

echo "== Frontend checks =="
cd "$ROOT_DIR/frontend"
npm run build
# Focused lint for payment-related files touched in this cycle.
npx eslint src/adminDash/pages/finance/Plans.jsx src/components/ErrorBoundary.jsx

echo "✅ verify_all.sh completed successfully"
