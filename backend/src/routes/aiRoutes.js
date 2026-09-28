const express = require("express");
const router = express.Router();
const { generateAcademicAdvice } = require("../services/geminiService");

// POST /api/ai/chat
router.post("/chat", async (req, res) => {
    try {
        const { query, role, rollNo, attendance } = req.body;
        if (!query || typeof query !== "string") {
            return res.status(400).json({ error: "Query string is required" });
        }

        const reply = await generateAcademicAdvice({
            query: query.trim(),
            role: role || "student",
            rollNo: rollNo || "Student",
            attendance: Array.isArray(attendance) ? attendance : []
        });

        return res.json({
            reply,
            timestamp: new Date().toISOString()
        });
    } catch (err) {
        console.error("Error in /api/ai/chat:", err);
        return res.status(500).json({ error: "Failed to process AI request" });
    }
});

module.exports = router;
