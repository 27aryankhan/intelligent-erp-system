const fs = require("fs");
const path = require("path");

// Resolve version.json from backend/version.json or root ../version.json
function getVersionData() {
    const candidates = [
        path.resolve(__dirname, "../../version.json"),
        path.resolve(__dirname, "../../../version.json")
    ];

    for (const filePath of candidates) {
        try {
            if (fs.existsSync(filePath)) {
                const raw = fs.readFileSync(filePath, "utf8");
                return JSON.parse(raw);
            }
        } catch (_) {}
    }

    // Default fallback if files are not on disk
    return {
        latest_version: "1.2.0",
        version_code: 13,
        min_supported_version_code: 11,
        download_url: "https://github.com/27aryankhan/intelligent-erp-system/releases/latest/download/Intelligent.ERP.apk",
        file_size: "40 MB",
        release_notes: [
            "Autonomous Background & Killed-App Notifications: Receive updates even when the app is closed or minimized",
            "Faculty-Specific Real-Time Attendance Alerts: Details Subject, Faculty Name, and Present/Absent status with live percentage",
            "Daily Evening Attendance Summary: End-of-day report with classes conducted, attended, missed, and aggregate percentage",
            "Timetable Period & Class Reminders: 10-minute alerts before each scheduled lecture with timing and faculty info",
            "Persistent User Session: Safe credential storage keeps users logged in until explicit logout",
            "Pixel Run Mini-Game: Autonomous continuous runner integrated directly on the student dashboard",
            "Optimized mobile APK build (~40 MB) for physical devices (armeabi-v7a & arm64-v8a)"
        ],
        is_critical: false
    };
}

/**
 * GET /version.json or GET /api/update/version
 * Direct standard version.json payload with zero caching
 */
exports.getVersionJson = (req, res) => {
    res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
    res.setHeader("Pragma", "no-cache");
    res.setHeader("Expires", "0");
    res.setHeader("Content-Type", "application/json");

    const data = getVersionData();
    res.json(data);
};

/**
 * GET /api/update/check?current_code=12&current_version=1.1.1
 * Detailed comparison endpoint for clients
 */
exports.checkUpdate = (req, res) => {
    res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
    res.setHeader("Pragma", "no-cache");
    res.setHeader("Expires", "0");

    const data = getVersionData();
    const currentCode = parseInt(req.query.current_code || req.query.version_code || "0", 10);
    const hasUpdate = data.version_code > currentCode;
    const isMandatory = currentCode < data.min_supported_version_code || hasUpdate;

    res.json({
        has_update: hasUpdate,
        is_mandatory: isMandatory,
        client_version_code: currentCode,
        ...data
    });
};

/**
 * GET /api/update/download
 * 302 redirect directly to the latest APK binary
 */
exports.downloadLatestApk = (req, res) => {
    const data = getVersionData();
    const downloadUrl = data.download_url || "https://github.com/27aryankhan/intelligent-erp-system/releases/latest/download/Intelligent.ERP.apk";
    res.redirect(302, downloadUrl);
};
