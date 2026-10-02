const express = require("express");
const router = express.Router();
const facultyController = require("../controllers/facultyController");
const { verifyAuth } = require("../middleware/authMiddleware");

// Enforce Faculty or Admin role
router.use(verifyAuth(["faculty", "admin"]));

router.get("/", facultyController.getFacultyOverview);
router.get("/students", facultyController.getFacultyStudents);
router.get("/assignments", facultyController.getFacultyAssignments);
router.post("/assignments", facultyController.createFacultyAssignment);
router.get("/assignments/:id/submissions", facultyController.getAssignmentSubmissions);
router.post("/assignments/:id/grade", facultyController.gradeStudentSubmission);
router.post("/assignments/:id/remind", facultyController.remindPendingStudents);
router.get("/attendance", facultyController.getFacultyAttendance);
router.post("/attendance", facultyController.saveFacultyAttendance);
router.post("/announcements", facultyController.createFacultyAnnouncement);

module.exports = router;
