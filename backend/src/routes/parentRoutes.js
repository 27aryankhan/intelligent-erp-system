const express = require("express");
const router = express.Router();
const parentController = require("../controllers/parentController");
const { verifyAuth } = require("../middleware/authMiddleware");

// Enforce Parent or Admin role
router.use(verifyAuth(["parent", "admin"]));

router.get("/", parentController.getParentOverview);
router.get("/fees", parentController.getParentFees);

module.exports = router;
