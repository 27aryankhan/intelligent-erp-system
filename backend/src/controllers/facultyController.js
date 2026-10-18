const { supabase, isConfigured, mockDb } = require("../config/supabase");

// 1. Faculty Dashboard Overview
exports.getFacultyOverview = async (req, res) => {
    try {
        if (isConfigured && supabase) {
            const { data, error } = await supabase
                .from("faculty")
                .select("id, name, department, students_count, active_assignments, designation")
                .eq("id", "FAC001")
                .single();

            if (data && !error) {
                return res.json({
                    id: data.id,
                    name: data.name,
                    department: data.department,
                    students: data.students_count,
                    attendanceManagement: "Manage",
                    activeAssignments: data.active_assignments,
                    announcements: "Create",
                    timetable: "View"
                });
            }
        }
        return res.json(mockDb.faculty);
    } catch (err) {
        console.error("Error in getFacultyOverview:", err);
        return res.json(mockDb.faculty);
    }
};

// 2. Faculty Students List
exports.getFacultyStudents = async (req, res) => {
    try {
        if (isConfigured && supabase) {
            const { data, error } = await supabase
                .from("students")
                .select("id, name, overall_attendance, assignments_pending");

            if (data && !error && data.length > 0) {
                return res.json(data.map(s => ({
                    id: s.id,
                    name: s.name,
                    attendance: s.overall_attendance,
                    assignmentsPending: s.assignments_pending
                })));
            }
        }
        return res.json(mockDb.facultyStudents);
    } catch (err) {
        console.error("Error in getFacultyStudents:", err);
        return res.json(mockDb.facultyStudents);
    }
};

// 3. Faculty Assignments
exports.getFacultyAssignments = async (req, res) => {
    try {
        if (isConfigured && supabase) {
            const { data, error } = await supabase
                .from("assignments")
                .select("*");

            if (data && !error && data.length > 0) {
                return res.json(data.map(a => {
                    const mock = mockDb.facultyAssignments.find(m => m.id === a.id || m.title === a.title) || {};
                    const subs = mock.submissions || [];
                    const submittedCount = subs.filter(s => s.status === 'Submitted').length;
                    const totalStudents = a.total_students || mock.totalStudents || 42;
                    return {
                        id: a.id,
                        subject: a.subject,
                        code: a.code || mock.code || "CSE",
                        title: a.title,
                        faculty: a.faculty || mock.faculty || "Dr. Ramesh Kumar",
                        dueDate: a.due_date || a.dueDate || mock.dueDate,
                        points: a.points || mock.points || 25,
                        submissions: subs,
                        submittedCount: submittedCount,
                        pendingCount: totalStudents - submittedCount,
                        totalStudents: totalStudents,
                        status: a.status || mock.status || "Active",
                        description: a.description || mock.description,
                        instructions: a.instructions || mock.instructions
                    };
                }));
            }
        }
        
        // Enrich mockDb assignments with submission metrics
        const enriched = mockDb.facultyAssignments.map(a => {
            const subs = a.submissions || [];
            const submittedCount = subs.filter(s => s.status === 'Submitted').length;
            const totalStudents = a.totalStudents || 42;
            return {
                ...a,
                submittedCount: submittedCount,
                pendingCount: totalStudents - submittedCount,
                submissions: subs
            };
        });

        return res.json(enriched);
    } catch (err) {
        console.error("Error in getFacultyAssignments:", err);
        return res.json(mockDb.facultyAssignments);
    }
};

// 3b. Create New Assignment (Faculty Posts Assignment)
exports.createFacultyAssignment = async (req, res) => {
    try {
        const { title, subject, code, dueDate, points, description, instructions, totalStudents } = req.body;

        if (!title || !subject) {
            return res.status(400).json({ success: false, message: "Title and Subject are required" });
        }

        const newId = `ASG${String(mockDb.facultyAssignments.length + 1).padStart(3, '0')}`;
        
        const newFacultyAssignment = {
            id: newId,
            subject: subject,
            code: code || "CSE",
            title: title,
            faculty: "Dr. Ramesh Kumar",
            dueDate: dueDate || "30 August 2026",
            points: points ? parseInt(points) : 25,
            totalStudents: totalStudents ? parseInt(totalStudents) : 42,
            submittedCount: 0,
            pendingCount: totalStudents ? parseInt(totalStudents) : 42,
            status: "Active",
            description: description || "Complete the assignment as instructed and upload your PDF.",
            instructions: instructions || "Upload your complete report in PDF format.",
            submissions: []
        };

        // Add to faculty list
        mockDb.facultyAssignments.unshift(newFacultyAssignment);

        // Also add to student assignments so students see it immediately!
        const newStudentAssignment = {
            id: newId,
            title: title,
            subject: subject,
            code: code || "CSE",
            faculty: "Dr. Ramesh Kumar",
            dueDate: dueDate || "30 August 2026",
            status: "Pending",
            points: points ? parseInt(points) : 25,
            urgency: "New Assignment",
            description: description || "Complete the assignment as instructed and upload your PDF.",
            instructions: instructions || "Upload your complete report in PDF format."
        };
        mockDb.assignments.unshift(newStudentAssignment);

        // Notify students & parents with rich notification payload
        if (mockDb.notifications) {
            const nowIso = new Date().toISOString();
            // Student notification
            mockDb.notifications.unshift({
                id: `NOTIF_${Date.now()}_STU`,
                userId: null,
                targetRole: "student",
                senderRole: "faculty",
                senderName: "Dr. Ramesh Kumar (Faculty)",
                type: "assignment",
                targetScreen: "assignments",
                priority: "urgent",
                title: `New Assignment Posted: ${title}`,
                body: `${subject}: Due on ${newStudentAssignment.dueDate}. Check details and upload your PDF report.`,
                createdAt: nowIso,
                timeAgo: "Just now",
                isRead: false
            });
            // Parent notification
            mockDb.notifications.unshift({
                id: `NOTIF_${Date.now()}_PAR`,
                userId: null,
                targetRole: "parent",
                senderRole: "faculty",
                senderName: "Dr. Ramesh Kumar (Faculty)",
                type: "assignment",
                targetScreen: "assignments",
                priority: "normal",
                title: `New Academic Assignment: ${title}`,
                body: `A new assignment for ${subject} has been assigned to your ward. Due date: ${newStudentAssignment.dueDate}.`,
                createdAt: nowIso,
                timeAgo: "Just now",
                isRead: false
            });
        }

        return res.status(201).json({
            success: true,
            message: "Assignment posted successfully!",
            assignment: newFacultyAssignment
        });
    } catch (err) {
        console.error("Error in createFacultyAssignment:", err);
        return res.status(500).json({ success: false, message: "Internal server error" });
    }
};

// 3c. Get Assignment Submissions Roster (Done vs Not Done)
exports.getAssignmentSubmissions = async (req, res) => {
    try {
        const { id } = req.params;
        const assignment = mockDb.facultyAssignments.find(a => a.id === id);

        if (!assignment) {
            return res.status(404).json({ success: false, message: "Assignment not found" });
        }

        const submissions = assignment.submissions || [];
        const doneList = submissions.filter(s => s.status === "Submitted");
        const notDoneList = submissions.filter(s => s.status === "Pending");

        return res.json({
            success: true,
            assignment: {
                id: assignment.id,
                title: assignment.title,
                subject: assignment.subject,
                code: assignment.code,
                dueDate: assignment.dueDate,
                points: assignment.points,
                totalStudents: assignment.totalStudents || 42,
                submittedCount: doneList.length,
                pendingCount: notDoneList.length
            },
            submitted: doneList,
            notDone: notDoneList,
            all: submissions
        });
    } catch (err) {
        console.error("Error in getAssignmentSubmissions:", err);
        return res.status(500).json({ success: false, message: "Internal server error" });
    }
};

// 3d. Grade Student Submission
exports.gradeStudentSubmission = async (req, res) => {
    try {
        const { id } = req.params;
        const { studentId, rollNo, score, grade, feedback } = req.body;

        const assignment = mockDb.facultyAssignments.find(a => a.id === id);
        if (!assignment) {
            return res.status(404).json({ success: false, message: "Assignment not found" });
        }

        const submission = (assignment.submissions || []).find(
            s => (studentId && s.studentId === studentId) || (rollNo && s.rollNo === rollNo)
        );

        if (!submission) {
            return res.status(404).json({ success: false, message: "Student submission record not found" });
        }

        submission.score = score || submission.score;
        submission.grade = grade || (score ? `Grade A` : submission.grade);
        submission.feedback = feedback || submission.feedback;

        // Also update student's view if matching
        const studentAsg = mockDb.assignments.find(a => a.id === id);
        if (studentAsg && (rollNo || studentId)) {
            studentAsg.score = submission.score;
            studentAsg.grade = submission.grade;
            studentAsg.feedback = submission.feedback;
        }

        return res.json({
            success: true,
            message: "Submission evaluated successfully!",
            submission
        });
    } catch (err) {
        console.error("Error in gradeStudentSubmission:", err);
        return res.status(500).json({ success: false, message: "Internal server error" });
    }
};

// 3e. Remind Students Who Have Not Done Assignment
exports.remindPendingStudents = async (req, res) => {
    try {
        const { id } = req.params;
        const assignment = mockDb.facultyAssignments.find(a => a.id === id);

        if (!assignment) {
            return res.status(404).json({ success: false, message: "Assignment not found" });
        }

        const pendingStudents = (assignment.submissions || []).filter(s => s.status === "Pending");

        if (mockDb.notifications) {
            mockDb.notifications.unshift({
                id: Date.now().toString(),
                role: "student",
                type: "assignment_reminder",
                title: `Reminder: ${assignment.title} Pending`,
                body: `Your submission for ${assignment.subject} is pending. Please upload your PDF before ${assignment.dueDate}.`,
                timestamp: new Date().toISOString(),
                read: false
            });
        }

        return res.json({
            success: true,
            message: `Reminder successfully sent to ${pendingStudents.length} pending student(s)!`,
            remindedCount: pendingStudents.length,
            students: pendingStudents.map(s => ({ name: s.studentName, rollNo: s.rollNo }))
        });
    } catch (err) {
        console.error("Error in remindPendingStudents:", err);
        return res.status(500).json({ success: false, message: "Internal server error" });
    }
};

function getRosterForClass(branch, year, section) {
    const branchCodeMap = {
        "COMPUTER SCIENCE ENGINEERING": { code: "05", short: "CSE" },
        "COMPUTER SCIENCE MACHINE LEARNING": { code: "66", short: "CSM" },
        "COMPUTER SCIENCE DATA SCIENCE": { code: "67", short: "CSD" },
        "MECHANICAL ENGINEERING": { code: "03", short: "MECH" },
        "ELECTRONICS AND COMMUNICATION ENGINEERING": { code: "04", short: "ECE" },
        "CSE": { code: "05", short: "CSE" },
        "CSM": { code: "66", short: "CSM" },
        "CSD": { code: "67", short: "CSD" },
        "MECH": { code: "03", short: "MECH" },
        "ECE": { code: "04", short: "ECE" }
    };

    const bKey = (branch || "CSE").toUpperCase().trim();
    const bInfo = branchCodeMap[bKey] || { code: "05", short: "CSE" };
    
    let yearPrefix = "22";
    if (year && (year.includes("3") || year.includes("3rd"))) yearPrefix = "23";
    else if (year && (year.includes("2") || year.includes("2nd"))) yearPrefix = "24";
    else if (year && (year.includes("1") || year.includes("1st"))) yearPrefix = "25";

    const sec = (section || "A").replace(/Section\s*/i, "").trim().toUpperCase() || "A";
    const secOffset = { "A": 1, "B": 11, "C": 21, "D": 31, "E": 41 }[sec] || 1;

    return Array.from({ length: 12 }, (_, idx) => {
        const num = secOffset + idx;
        const numStr = String(num).padStart(2, '0');
        const rollNo = `${yearPrefix}K91A${bInfo.code}${numStr}`;
        const pct = 75 + ((idx * 7) % 23);
        return {
            id: `STU_${bInfo.short}_${sec}_${numStr}`,
            studentId: `STU_${bInfo.short}_${sec}_${numStr}`,
            name: rollNo,
            studentName: rollNo,
            rollNo: rollNo,
            status: pct >= 80 ? "Present" : "Absent",
            percentage: pct,
            attendance: pct,
            overallAttendance: pct,
            branch: `${bInfo.short} - Sec ${sec}`,
            year: year || "3rd Year",
            section: `Section ${sec}`
        };
    });
}

// 4. Faculty Attendance Roster
exports.getFacultyAttendance = async (req, res) => {
    try {
        const { branch, year, section } = req.query;
        if (branch || section || year) {
            return res.json(getRosterForClass(branch, year, section));
        }

        if (isConfigured && supabase) {
            const { data, error } = await supabase
                .from("faculty_attendance")
                .select("student_id, student_name, attendance, assignments_pending")
                .eq("faculty_id", "FAC001");

            if (data && !error && data.length > 0) {
                return res.json(data.map(item => ({
                    id: item.student_id,
                    studentId: item.student_id,
                    name: item.student_name,
                    studentName: item.student_name,
                    rollNo: item.roll_no || item.student_id || "",
                    status: item.attendance >= 80 ? "Present" : "Absent",
                    percentage: item.attendance,
                    attendance: item.attendance,
                    overallAttendance: item.attendance,
                    branch: "CSE-A"
                })));
            }
        }
        return res.json(mockDb.facultyAttendanceList);
    } catch (err) {
        console.error("Error in getFacultyAttendance:", err);
        return res.json(mockDb.facultyAttendanceList);
    }
};

// 4b. Save / Update Daily Faculty Attendance
exports.saveFacultyAttendance = async (req, res) => {
    try {
        const { subject, date, period, records } = req.body;
        const absentStudents = [];
        if (Array.isArray(records)) {
            // Update in-memory roster
            records.forEach(rec => {
                const found = mockDb.facultyAttendanceList.find(s => (s.studentId === rec.studentId || s.id === rec.id));
                if (found) {
                    found.status = rec.status;
                }
                if (rec.status === "Absent") {
                    absentStudents.push(rec.name || rec.studentName || "Student");
                }
            });

            // If any student was absent, trigger notifications to parents and students
            if (absentStudents.length > 0 && mockDb.notifications) {
                const nowIso = new Date().toISOString();
                mockDb.notifications.unshift({
                    id: `NOTIF_${Date.now()}_ABS_PAR`,
                    userId: "PAR001",
                    targetRole: "parent",
                    senderRole: "faculty",
                    senderName: "Faculty Attendance Office",
                    type: "attendance",
                    targetScreen: "attendance",
                    priority: "urgent",
                    title: `Attendance Alert: Absent in ${subject || "Lecture"}`,
                    body: `Your ward was recorded as Absent today for ${subject || "class"}. Please verify with student.`,
                    createdAt: nowIso,
                    timeAgo: "Just now",
                    isRead: false
                });

                mockDb.notifications.unshift({
                    id: `NOTIF_${Date.now()}_ABS_STU`,
                    userId: "STU001",
                    targetRole: "student",
                    senderRole: "faculty",
                    senderName: "Faculty Attendance Office",
                    type: "attendance",
                    targetScreen: "attendance",
                    priority: "high",
                    title: `Attendance Notice: Absent Recorded`,
                    body: `You were marked Absent for ${subject || "class"} on ${date || "today"}. Aggregate attendance must stay above 75%.`,
                    createdAt: nowIso,
                    timeAgo: "Just now",
                    isRead: false
                });
            }
        }
        return res.json({
            success: true,
            message: `Attendance for ${subject || "Course"} on ${date || "Today"} saved successfully!`,
            recordsCount: records ? records.length : mockDb.facultyAttendanceList.length,
            absentNotified: absentStudents.length
        });
    } catch (err) {
        console.error("Error in saveFacultyAttendance:", err);
        return res.status(500).json({ success: false, message: "Failed to record attendance." });
    }
};

// 5. Create Announcement from Faculty
exports.createFacultyAnnouncement = async (req, res) => {
    try {
        const { title, department, targetAudience, branch, year, section } = req.body;
        const bodyContent = req.body.content || req.body.message || "";
        const bodyCategory = req.body.type || req.body.category || department || "General";
        const classScopeLabel = branch ? `${branch} (${year || "4th"} • ${section || "A"})` : (department || "CSE");

        if (!title) {
            return res.status(400).json({ error: "Title is required" });
        }

        const aud = (targetAudience || "Students").toLowerCase();
        let targetRole = "student";
        if (aud.includes("parent") && aud.includes("student")) targetRole = "students_parents";
        else if (aud.includes("parent")) targetRole = "parent";
        else targetRole = "student";

        if (isConfigured && supabase) {
            const { data, error } = await supabase
                .from("announcements")
                .insert([{
                    title,
                    content: bodyContent,
                    author_name: "Dr. Ramesh",
                    author_role: "Faculty",
                    target_audience: targetAudience || "Students",
                    department: classScopeLabel
                }])
                .select()
                .single();

            if (!error && data) {
                return res.status(201).json({
                    message: "Announcement created successfully in Supabase!",
                    announcement: data
                });
            }
        }

        // Fallback save to memory
        const newAnn = {
            id: mockDb.announcements.length + 1,
            title,
            content: bodyContent,
            message: bodyContent,
            author: "Dr. Ramesh",
            role: "Faculty",
            category: bodyCategory,
            type: bodyCategory,
            priority: "normal",
            isPinned: false,
            department: classScopeLabel,
            targetAudience: targetAudience || "Students",
            refNo: `HITAM/FAC/2026/0${mockDb.announcements.length + 1}`,
            attachment: null,
            date: "Just now"
        };
        mockDb.announcements.unshift(newAnn);

        // Also push a live notification from Faculty to chosen audience (students/parents)
        if (mockDb.notifications) {
            mockDb.notifications.unshift({
                id: `NOTIF_${Date.now()}_FAC_ANN`,
                userId: null,
                targetRole: targetRole,
                senderRole: "faculty",
                senderName: "Dr. Ramesh (Faculty)",
                type: "announcement",
                targetScreen: "announcements",
                priority: "high",
                title: `Faculty Notice: ${title}`,
                body: bodyContent || `New announcement from ${department || "CSE"} Faculty.`,
                createdAt: new Date().toISOString(),
                timeAgo: "Just now",
                isRead: false
            });
        }

        return res.status(201).json({
            message: "Announcement created successfully!",
            announcement: newAnn
        });
    } catch (err) {
        console.error("Error in createFacultyAnnouncement:", err);
        return res.status(500).json({ error: "Failed to create announcement" });
    }
};
