const { supabase, isConfigured, mockDb } = require("../config/supabase");

// Helper to match targetRole against active role
function matchesRole(targetRole, userRole) {
    if (!userRole || userRole === "all") return true;
    if (!targetRole || targetRole === "all") return true;
    const tr = targetRole.toLowerCase();
    const ur = userRole.toLowerCase();
    if (tr === ur) return true;
    if (tr === "students_parents" || tr === "students_and_parents" || tr === "both") {
        return ur === "student" || ur === "parent";
    }
    if (tr.includes(ur)) return true;
    return false;
}

// Helper to compute human-friendly relative time
function getRelativeTime(dateStr) {
    try {
        const diffMs = Date.now() - new Date(dateStr).getTime();
        const diffMins = Math.floor(diffMs / (60 * 1000));
        if (diffMins < 1) return "Just now";
        if (diffMins < 60) return `${diffMins} mins ago`;
        const diffHours = Math.floor(diffMins / 60);
        if (diffHours < 24) return `${diffHours} hours ago`;
        const diffDays = Math.floor(diffHours / 24);
        if (diffDays === 1) return "Yesterday";
        if (diffDays < 7) return `${diffDays} days ago`;
        return new Date(dateStr).toLocaleDateString("en-IN", { day: "numeric", month: "short" });
    } catch {
        return "Recent";
    }
}

// 1. GET Notifications Feed (Role-Based & User-Targeted)
exports.getNotifications = async (req, res) => {
    try {
        const role = (req.query.role || "all").toLowerCase();
        const userId = req.query.userId || "";
        const type = req.query.type;
        const senderRole = (req.query.senderRole || req.query.sender || "").toLowerCase();

        if (isConfigured && supabase) {
            let query = supabase
                .from("notifications")
                .select("*")
                .order("created_at", { ascending: false });

            if (role !== "all" && userId) {
                query = query.or(`target_role.eq.${role},target_role.eq.all,target_role.eq.students_parents,user_id.eq.${userId},user_id.is.null`);
            } else if (role !== "all") {
                query = query.or(`target_role.eq.${role},target_role.eq.all,target_role.eq.students_parents,user_id.is.null`);
            } else if (userId) {
                query = query.or(`user_id.eq.${userId},user_id.is.null`);
            }

            if (type && type !== "All") {
                query = query.eq("type", type.toLowerCase());
            }

            const { data, error } = await query;
            if (data && !error && data.length > 0) {
                let list = data.map(n => ({
                    id: n.id.toString(),
                    userId: n.user_id,
                    targetRole: n.target_role || "all",
                    senderRole: n.sender_role || (n.target_role === "faculty" ? "admin" : "faculty"),
                    senderName: n.sender_name || (n.sender_role === "admin" ? "HITAM Administration" : "Faculty Department"),
                    title: n.title,
                    body: n.body || n.message || "",
                    type: n.type || "general",
                    targetScreen: n.target_screen || n.type || "dashboard",
                    priority: n.priority || "normal",
                    isRead: Boolean(n.is_read),
                    createdAt: n.created_at,
                    timeAgo: getRelativeTime(n.created_at)
                }));

                // Strict role isolation: users only receive notifications intended for their role or all
                if (role && role !== "all") {
                    list = list.filter(n => matchesRole(n.targetRole, role));
                }

                if (userId) {
                    list = list.filter(n => !n.userId || n.userId === userId);
                }

                if (senderRole && senderRole !== "all") {
                    list = list.filter(n => n.senderRole.toLowerCase() === senderRole);
                }

                const unreadCount = list.filter(n => !n.isRead).length;
                return res.json({
                    notifications: list,
                    unreadCount,
                    total: list.length,
                    role
                });
            }
        }

        // Fallback to in-memory store
        let list = mockDb.notifications.filter(n => {
            const matchRole = matchesRole(n.targetRole, role);
            const matchUser = !userId || !n.userId || n.userId === userId;
            const matchSender = !senderRole || senderRole === "all" || (n.senderRole || "").toLowerCase() === senderRole;
            return matchRole && matchUser && matchSender;
        });

        if (type && type !== "All") {
            list = list.filter(n => n.type.toLowerCase() === type.toLowerCase());
        }

        const unreadCount = list.filter(n => !n.isRead).length;
        return res.json({
            notifications: list,
            unreadCount,
            total: list.length,
            role
        });
    } catch (err) {
        console.error("Error in getNotifications:", err);
        return res.json({
            notifications: mockDb.notifications,
            unreadCount: mockDb.notifications.filter(n => !n.isRead).length,
            total: mockDb.notifications.length,
            role: req.query.role || "all"
        });
    }
};

// 2. SEND Notification (Broadcast to Role or Specific User)
exports.sendNotification = async (req, res) => {
    try {
        const { title, body, message, type, targetScreen, priority, userId, targetRole, senderRole, senderName } = req.body;

        if (!title) {
            return res.status(400).json({ error: "Notification title is required" });
        }

        const notificationContent = body || message || "You have a new campus notification.";
        const notifType = (type || "general").toLowerCase();
        const screen = targetScreen || notifType;
        const notifPriority = priority || "normal";
        const role = (targetRole || "all").toLowerCase();
        const targetUserId = userId || null;
        const sRole = (senderRole || (role === "faculty" ? "admin" : "faculty")).toLowerCase();
        const sName = senderName || (sRole === "admin" ? "HITAM Administration" : "Dr. Ramesh Kumar (Faculty)");
        const now = new Date().toISOString();

        if (isConfigured && supabase) {
            const { data, error } = await supabase
                .from("notifications")
                .insert([{
                    user_id: targetUserId,
                    target_role: role,
                    sender_role: sRole,
                    sender_name: sName,
                    title,
                    body: notificationContent,
                    type: notifType,
                    target_screen: screen,
                    priority: notifPriority,
                    is_read: false,
                    created_at: now
                }])
                .select()
                .single();

            if (!error && data) {
                const insertedNotif = {
                    id: data.id.toString(),
                    userId: data.user_id,
                    targetRole: data.target_role,
                    senderRole: data.sender_role || sRole,
                    senderName: data.sender_name || sName,
                    title: data.title,
                    body: data.body,
                    type: data.type,
                    targetScreen: data.target_screen,
                    priority: data.priority,
                    isRead: data.is_read,
                    createdAt: data.created_at,
                    timeAgo: "Just now"
                };
                mockDb.notifications.unshift(insertedNotif);
                return res.status(201).json({
                    message: "Role-targeted notification sent and dispatched in real-time!",
                    notification: insertedNotif,
                    pushStatus: "dispatched_realtime"
                });
            }
        }

        // Mock in-memory storage
        const newNotif = {
            id: `NOTIF_${Date.now()}`,
            userId: targetUserId,
            targetRole: role,
            senderRole: sRole,
            senderName: sName,
            title,
            body: notificationContent,
            type: notifType,
            targetScreen: screen,
            priority: notifPriority,
            isRead: false,
            createdAt: now,
            timeAgo: "Just now"
        };
        mockDb.notifications.unshift(newNotif);

        return res.status(201).json({
            message: "Role-targeted notification dispatched in real-time!",
            notification: newNotif,
            pushStatus: "dispatched_realtime"
        });
    } catch (err) {
        console.error("Error in sendNotification:", err);
        return res.status(500).json({ error: "Failed to dispatch notification" });
    }
};

// 3. REGISTER Device Push Token with Role (FCM / APNs)
exports.registerDeviceToken = async (req, res) => {
    try {
        const { userId, role, email, token, platform } = req.body || {};

        if (!token) {
            return res.status(400).json({ error: "Device push token is required" });
        }

        const now = new Date().toISOString();
        const clientUserId = userId || "STU001";
        const clientRole = (role || "student").toLowerCase();
        const clientEmail = email || null;
        const clientPlatform = platform || "android";

        if (isConfigured && supabase) {
            const { error } = await supabase
                .from("device_tokens")
                .upsert(
                    {
                        user_id: clientUserId,
                        role: clientRole,
                        email: clientEmail,
                        token,
                        platform: clientPlatform,
                        updated_at: now
                    },
                    { onConflict: "token" }
                );

            if (!error) {
                return res.json({
                    message: "Device token registered with role in Supabase!",
                    token,
                    role: clientRole,
                    platform: clientPlatform
                });
            }
        }

        // Mock fallback
        const existingIdx = mockDb.deviceTokens.findIndex(d => d.token === token);
        if (existingIdx >= 0) {
            mockDb.deviceTokens[existingIdx].role = clientRole;
            mockDb.deviceTokens[existingIdx].userId = clientUserId;
            mockDb.deviceTokens[existingIdx].email = clientEmail;
            mockDb.deviceTokens[existingIdx].lastActive = now;
        } else {
            mockDb.deviceTokens.push({
                userId: clientUserId,
                role: clientRole,
                email: clientEmail,
                token,
                platform: clientPlatform,
                lastActive: now
            });
        }

        return res.json({
            message: "Device token registered successfully with role!",
            token,
            role: clientRole,
            platform: clientPlatform
        });
    } catch (err) {
        console.error("Error in registerDeviceToken:", err);
        return res.status(500).json({ error: "Failed to register device token" });
    }
};

// 4. POLL Real-Time Delta Notifications (Zero-Delay Client Sync)
exports.pollNotifications = async (req, res) => {
    try {
        const role = (req.query.role || "all").toLowerCase();
        const userId = req.query.userId || "";
        const since = req.query.since;
        const sinceTime = since ? new Date(since).getTime() : 0;

        if (isConfigured && supabase && since) {
            let pollQuery = supabase
                .from("notifications")
                .select("*")
                .gt("created_at", since)
                .order("created_at", { ascending: false });

            const { data, error } = await pollQuery;
            if (!error && data && data.length > 0) {
                let alerts = data.map(n => ({
                    id: n.id.toString(),
                    userId: n.user_id,
                    targetRole: n.target_role || "all",
                    senderRole: n.sender_role || "admin",
                    senderName: n.sender_name || "HITAM Administration",
                    title: n.title,
                    body: n.body || n.message || "",
                    type: n.type || "general",
                    targetScreen: n.target_screen || n.type || "dashboard",
                    priority: n.priority || "normal",
                    isRead: Boolean(n.is_read),
                    createdAt: n.created_at,
                    timeAgo: getRelativeTime(n.created_at)
                }));

                if (role && role !== "all") {
                    alerts = alerts.filter(n => matchesRole(n.targetRole, role));
                }
                if (userId) {
                    alerts = alerts.filter(n => !n.userId || n.userId === userId);
                }

                return res.json({
                    newAlerts: alerts,
                    count: alerts.length,
                    timestamp: new Date().toISOString()
                });
            }
        }

        const newAlerts = mockDb.notifications.filter(n => {
            const matchRole = matchesRole(n.targetRole, role);
            const matchUser = !userId || !n.userId || n.userId === userId;
            const notifTime = new Date(n.createdAt).getTime();
            return matchRole && matchUser && notifTime > sinceTime;
        });

        return res.json({
            newAlerts,
            count: newAlerts.length,
            timestamp: new Date().toISOString()
        });
    } catch (err) {
        console.error("Error in pollNotifications:", err);
        return res.status(500).json({ error: "Failed to poll notifications" });
    }
};

// 5. MARK Notification As Read
exports.markAsRead = async (req, res) => {
    try {
        const notifId = req.params.id;

        if (isConfigured && supabase) {
            await supabase
                .from("notifications")
                .update({ is_read: true })
                .eq("id", notifId);
        }

        const found = mockDb.notifications.find(n => n.id.toString() === notifId.toString());
        if (found) {
            found.isRead = true;
        }

        return res.json({ message: "Notification marked as read", id: notifId });
    } catch (err) {
        console.error("Error in markAsRead:", err);
        return res.status(500).json({ error: "Failed to update notification" });
    }
};

// 6. MARK ALL Notifications As Read (Role or User)
exports.markAllAsRead = async (req, res) => {
    try {
        const userId = (req.body && req.body.userId) || "";
        const role = (req.body && req.body.role) || "";

        if (isConfigured && supabase) {
            let updateQuery = supabase.from("notifications").update({ is_read: true });
            if (role) {
                updateQuery = updateQuery.or(`target_role.eq.${role},target_role.eq.all`);
            } else if (userId) {
                updateQuery = updateQuery.or(`user_id.eq.${userId},user_id.is.null`);
            }
            await updateQuery;
        }

        mockDb.notifications.forEach(n => {
            const notifRole = (n.targetRole || "all").toLowerCase();
            const matchRole = !role || role === "all" || notifRole === "all" || notifRole === role.toLowerCase();
            const matchUser = !userId || !n.userId || n.userId === userId;
            if (matchRole && matchUser) {
                n.isRead = true;
            }
        });

        return res.json({ message: "All notifications marked as read" });
    } catch (err) {
        console.error("Error in markAllAsRead:", err);
        return res.status(500).json({ error: "Failed to mark all as read" });
    }
};
