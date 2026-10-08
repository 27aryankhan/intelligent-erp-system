const express = require("express");
const router = express.Router();
const updateController = require("../controllers/updateController");

// Check update status (/api/update or /api/update/check)
router.get("/", updateController.checkUpdate);
router.get("/check", updateController.checkUpdate);

// Get version.json metadata (/api/update/version)
router.get("/version", updateController.getVersionJson);

// Direct download latest APK (/api/update/download)
router.get("/download", updateController.downloadLatestApk);

module.exports = router;
