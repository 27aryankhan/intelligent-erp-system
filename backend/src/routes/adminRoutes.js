const express = require("express");
const router = express.Router();
const adminController = require("../controllers/adminController");
const { verifyAuth } = require("../middleware/authMiddleware");

// Enforce Admin role for all administrative endpoints
router.use(verifyAuth(["admin"]));

router.get("/summary", adminController.getAdminSummary);
router.get("/students", adminController.getAdminStudents);
router.post("/students", adminController.addAdminStudent);
router.delete("/students/:id", adminController.deleteAdminStudent);
router.get("/faculty", adminController.getAdminFaculty);
router.post("/announcements", adminController.createAdminAnnouncement);

module.exports = router;
