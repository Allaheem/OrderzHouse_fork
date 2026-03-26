import express from "express";
import authentication from "../middleware/authentication.js";
import requireTenderVaultPermission from "../middleware/requireTenderVaultPermission.js";
import {
  testRunTenderVaultRotation,
  testExpireCurrentTenderVaultBatch,
} from "../controller/tenderVault/tenderVault.js";

const router = express.Router();

router.use(authentication);
router.use(requireTenderVaultPermission);

router.post("/test-run-rotation", testRunTenderVaultRotation);
router.post("/test-expire-current-batch", testExpireCurrentTenderVaultBatch);

export default router;
