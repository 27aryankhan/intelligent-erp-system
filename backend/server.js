const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, ".env") });

const { isConfigured, supabase } = require("./src/config/supabase");

// Route Imports
const studentRoutes = require("./src/routes/studentRoutes");
const facultyRoutes = require("./src/routes/facultyRoutes");
const parentRoutes = require("./src/routes/parentRoutes");
const adminRoutes = require("./src/routes/adminRoutes");
const announcementRoutes = require("./src/routes/announcementRoutes");
const notificationRoutes = require("./src/routes/notificationRoutes");
const authRoutes = require("./src/routes/authRoutes");
const aiRoutes = require("./src/routes/aiRoutes");
const { authRateLimiter, generalApiLimiter } = require("./src/middleware/authMiddleware");

const app = express();
const PORT = process.env.PORT || 5050;

// Security & Middleware
app.use(helmet());
app.use(cors());
app.use(morgan("dev"));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Apply rate limiting to protect API routes
app.use("/api/", generalApiLimiter);
app.use("/api/auth/login", authRateLimiter);

// Health / Status Route
app.get("/", (req, res) => {
    res.json({
        name: "Intelligent ERP API Gateway",
        institution: "Hyderabad Institute of Technology and Management (HITAM)",
        version: "2.0.0",
        status: "Online",
        database: isConfigured ? "Supabase PostgreSQL (Connected)" : "Local In-Memory Cache (Fallback)",
        supabaseUrl: process.env.SUPABASE_URL || "Not configured",
        endpoints: {
            auth: "/api/auth/login",
            student: "/api/student",
            faculty: "/api/faculty",
            parent: "/api/parent",
            admin: "/api/admin/summary",
            announcements: "/api/announcements",
            notifications: "/api/notifications",
            aiChat: "/api/ai/chat"
        }
    });
});

app.get("/health", (req, res) => {
    res.json({ status: "healthy", timestamp: new Date().toISOString() });
});

// API Routes
app.use("/api/auth", authRoutes);
app.use("/api/student", studentRoutes);
app.use("/api/faculty", facultyRoutes);
app.use("/api/parent", parentRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/announcements", announcementRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/ai", aiRoutes);

// Global Error Handler
app.use((err, req, res, next) => {
    console.error("Internal Server Error:", err);
    res.status(500).json({
        error: "Internal Server Error",
        message: err.message || "An unexpected error occurred."
    });
});

// Start Server
app.listen(PORT, "0.0.0.0", () => {
    console.log(`=======================================================`);
    console.log(`🚀 Intelligent ERP Backend Server running on port ${PORT}`);
    console.log(`📡 Local URL: http://localhost:${PORT}`);
    console.log(`📱 Android Emulator URL: http://10.0.2.2:${PORT}`);
    console.log(`🗄️  Database Mode: ${isConfigured ? "Live Supabase PostgreSQL" : "Mock In-Memory Store"}`);
    console.log(`=======================================================`);
});

module.exports = app;
