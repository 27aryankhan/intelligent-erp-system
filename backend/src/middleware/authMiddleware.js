const { supabase, isConfigured } = require("../config/supabase");
const rateLimit = require("express-rate-limit");

/**
 * Authentication Rate Limiter
 * Protects login and auth routes from brute-force attacks and credential stuffing
 */
const authRateLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 20, // Max 20 attempts per 15 minutes per IP
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        error: "Too Many Requests",
        message: "Too many login attempts from this IP address. Please try again after 15 minutes."
    }
});

/**
 * General API Rate Limiter
 * Protects server from DoS / abusive polling
 */
const generalApiLimiter = rateLimit({
    windowMs: 1 * 60 * 1000, // 1 minute
    max: 180, // Max 180 requests per minute
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        error: "Rate limit exceeded",
        message: "Too many requests. Please slow down."
    }
});

/**
 * Role-Based Access Control (RBAC) & Token Verification Middleware
 * Validates Supabase JWT or development mock token, verifying user privileges.
 */
function verifyAuth(allowedRoles = []) {
    return async (req, res, next) => {
        try {
            const authHeader = req.headers["authorization"];
            const token = authHeader && authHeader.split(" ")[1];

            const isProduction = process.env.NODE_ENV === "production";

            // In development fallback mode without auth token, allow mock requests only if not configured & not production
            if (!token) {
                if (!isConfigured && !isProduction) {
                    req.user = { id: "DEV_USER", role: "admin", name: "Development Mode" };
                    return next();
                }
                return res.status(401).json({
                    error: "Unauthorized",
                    message: "Authorization Bearer token is required."
                });
            }

            // Mock development token (Strictly disabled in production)
            if (token.startsWith("mock-jwt-token-")) {
                if (isProduction) {
                    return res.status(401).json({
                        error: "Unauthorized",
                        message: "Mock tokens are disabled in production environment."
                    });
                }

                const role = req.headers["x-user-role"] || "student";
                if (allowedRoles.length > 0 && !allowedRoles.includes(role)) {
                    return res.status(403).json({
                        error: "Forbidden",
                        message: `Access denied. Requires one of roles: [${allowedRoles.join(", ")}]`
                    });
                }

                req.user = {
                    id: "DEV_USER",
                    role,
                    name: "Local Dev User"
                };
                return next();
            }

            // Verify with Supabase Auth if configured
            if (isConfigured && supabase) {
                const { data: { user }, error } = await supabase.auth.getUser(token);
                if (error || !user) {
                    return res.status(401).json({
                        error: "Unauthorized",
                        message: "Invalid or expired session token."
                    });
                }

                // Check profile role
                const { data: profile } = await supabase
                    .from("profiles")
                    .select("role")
                    .eq("id", user.id)
                    .single();

                const role = profile?.role || "student";

                if (allowedRoles.length > 0 && !allowedRoles.includes(role)) {
                    return res.status(403).json({
                        error: "Forbidden",
                        message: `Access denied. Requires one of roles: [${allowedRoles.join(", ")}]`
                    });
                }

                req.user = { id: user.id, email: user.email, role };
                return next();
            }

            // If Supabase is not configured and token is not mock, verify role
            if (allowedRoles.length > 0) {
                const role = req.headers["x-user-role"] || "student";
                if (!allowedRoles.includes(role)) {
                    return res.status(403).json({
                        error: "Forbidden",
                        message: `Access denied. Requires one of roles: [${allowedRoles.join(", ")}]`
                    });
                }
            }

            next();
        } catch (err) {
            console.error("Auth Middleware Error:", err);
            return res.status(500).json({ error: "Internal Auth Error" });
        }
    };
}

module.exports = {
    authRateLimiter,
    generalApiLimiter,
    verifyAuth
};
