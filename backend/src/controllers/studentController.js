const { supabase, isConfigured, mockDb } = require("../config/supabase");

// 1. Student Dashboard Summary
exports.getStudentOverview = async (req, res) => {
    try {
        const rollNo = req.query.rollNo || req.query.studentId || (req.user && req.user.id) || "";
        if (isConfigured && supabase && rollNo) {
            const { data, error } = await supabase
                .from("students")
                .select("id, name, department, year, overall_attendance, assignments_pending, upcoming_exams, new_announcements")
                .eq("id", rollNo)
                .single();

            if (data && !error) {
                return res.json({
                    id: data.id,
                    name: data.name,
                    department: data.department,
                    year: data.year,
                    attendance: data.overall_attendance,
                    assignmentsPending: data.assignments_pending,
                    upcomingExams: data.upcoming_exams,
                    newAnnouncements: data.new_announcements
                });
            }
        }
        return res.json(mockDb.student);
    } catch (err) {
        console.error("Error in getStudentOverview:", err);
        return res.json(mockDb.student);
    }
};

// 2. Student Attendance Breakdown
exports.getStudentAttendance = async (req, res) => {
    try {
        const studentId = req.query.rollNo || req.query.studentId || (req.user && req.user.id) || "";
        const studentName = req.query.name || req.query.studentName || (req.user && req.user.name) || "";
        const department = req.query.department || "";
        const semester = req.query.semester || "";

        if (isConfigured && supabase && studentId) {
            const { data, error } = await supabase
                .from("attendance_subjects")
                .select("subject, attended, total, percentage")
                .eq("student_id", studentId);

            if (data && !error && data.length > 0) {
                const total = data.reduce((sum, s) => sum + Number(s.total || 0), 0);
                const attended = data.reduce((sum, s) => sum + Number(s.attended || 0), 0);
                const overall = total > 0 ? Math.round((attended / total) * 100) : 0;

                return res.json({
                    studentId,
                    studentName,
                    department,
                    semester,
                    overallAttendance: overall,
                    totalClasses: total,
                    attendedClasses: attended,
                    marginClasses: Math.max(0, Math.floor(attended - (0.75 * total))),
                    subjects: data
                });
            }
        }
        return res.json({
            ...mockDb.attendance,
            studentId,
            studentName,
            department,
            semester
        });
    } catch (err) {
        console.error("Error in getStudentAttendance:", err);
        return res.json(mockDb.attendance);
    }
};

// 3. Student Assignments
exports.getStudentAssignments = async (req, res) => {
    try {
        if (isConfigured && supabase) {
            const { data, error } = await supabase
                .from("assignments")
                .select("*");

            if (data && !error && data.length > 0) {
                return res.json(data.map(a => {
                    const mockMatch = mockDb.assignments.find(m => m.id === a.id || m.title === a.title) || {};
                    return {
                        id: a.id,
                        title: a.title,
                        subject: a.subject,
                        code: a.code || mockMatch.code || "CS301PC",
                        faculty: a.faculty || mockMatch.faculty || "Faculty Department",
                        dueDate: a.due_date || a.dueDate || mockMatch.dueDate,
                        status: a.status || mockMatch.status || "Pending",
                        points: a.points || mockMatch.points || 25,
                        urgency: a.urgency || mockMatch.urgency || "Due Soon",
                        description: a.description || mockMatch.description || "Complete and submit solution by deadline.",
                        instructions: a.instructions || mockMatch.instructions || "Adhere to the rubric and test cases.",
                        submittedDate: a.submitted_date || a.submittedDate || mockMatch.submittedDate,
                        score: a.score || mockMatch.score,
                        grade: a.grade || mockMatch.grade,
                        feedback: a.feedback || mockMatch.feedback
                    };
                }));
            }
        }
        return res.json(mockDb.assignments);
    } catch (err) {
        console.error("Error in getStudentAssignments:", err);
        return res.json(mockDb.assignments);
    }
};

// 3b. Submit Student Assignment
exports.submitStudentAssignment = async (req, res) => {
    try {
        const { assignmentId, comments, fileName } = req.body;
        if (!assignmentId) {
            return res.status(400).json({ success: false, message: "assignmentId is required" });
        }

        // Update in mockDb student assignments
        const activeRoll = req.body.rollNo || req.body.studentId || "";
        const activeName = req.body.studentName || req.body.name || "Student";
        const item = mockDb.assignments.find(a => a.id === assignmentId);
        const submissionTimestamp = "Just now • " + new Date().toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
        const finalFileName = fileName || `assignment_solution_${activeRoll || 'document'}.pdf`;

        if (item) {
            item.status = "Completed";
            item.submittedDate = submissionTimestamp;
            item.urgency = "Submitted On Time";
            item.submittedFile = finalFileName;
            item.studentComments = comments || "Submitted via ERP Portal.";
        }

        // Synchronize with Faculty Assignments Roster
        const facultyAsg = mockDb.facultyAssignments.find(a => a.id === assignmentId || a.title === (item ? item.title : null));
        if (facultyAsg) {
            if (!facultyAsg.submissions) facultyAsg.submissions = [];
            const studentSub = facultyAsg.submissions.find(s => (activeRoll && (s.rollNo === activeRoll || s.studentId === activeRoll)));
            if (studentSub) {
                studentSub.status = "Submitted";
                studentSub.submittedAt = submissionTimestamp;
                studentSub.fileName = finalFileName;
                studentSub.fileSize = "1.5 MB";
                studentSub.score = studentSub.score || null;
                studentSub.grade = studentSub.grade || null;
                studentSub.feedback = studentSub.feedback || null;
            } else {
                facultyAsg.submissions.unshift({
                    studentId: activeRoll || "STU",
                    studentName: activeName,
                    rollNo: activeRoll,
                    department: "Engineering",
                    status: "Submitted",
                    submittedAt: submissionTimestamp,
                    fileName: finalFileName,
                    fileSize: "1.5 MB",
                    score: null,
                    grade: null,
                    feedback: null
                });
            }
        }

        // Notify faculty of submission
        if (mockDb.notifications) {
            mockDb.notifications.unshift({
                id: Date.now().toString(),
                role: "faculty",
                type: "assignment_submission",
                title: `New Assignment Submission Received`,
                body: `${activeName}${activeRoll ? ` (${activeRoll})` : ''} submitted PDF for "${item ? item.title : assignmentId}".`,
                timestamp: new Date().toISOString(),
                read: false
            });
        }

        // Update student pending count
        if (mockDb.student && mockDb.student.assignmentsPending > 0) {
            mockDb.student.assignmentsPending -= 1;
        }

        return res.json({
            success: true,
            message: "Assignment submitted successfully in PDF format!",
            assignment: item || { id: assignmentId, status: "Completed" }
        });
    } catch (err) {
        console.error("Error in submitStudentAssignment:", err);
        return res.status(500).json({ success: false, message: "Internal server error" });
    }
};

// 4. Student Exams
exports.getStudentExams = async (req, res) => {
    try {
        if (isConfigured && supabase) {
            const { data, error } = await supabase
                .from("exams")
                .select("id, subject, exam_date, exam_time, room, exam_type");

            if (data && !error && data.length > 0) {
                return res.json(data.map(e => ({
                    id: e.id,
                    subject: e.subject,
                    date: e.exam_date,
                    time: e.exam_time,
                    room: e.room,
                    venue: e.room || "Hall 302",
                    type: e.exam_type || "Mid Term"
                })));
            }
        }
        return res.json(mockDb.exams);
    } catch (err) {
        console.error("Error in getStudentExams:", err);
        return res.json(mockDb.exams);
    }
};

// 5. Student Results
exports.getStudentResults = async (req, res) => {
    try {
        if (isConfigured && supabase) {
            const { data: resultsList, error: resultsError } = await supabase
                .from("results")
                .select("id, semester, gpa, cgpa")
                .eq("student_id", "STU001")
                .order("id", { ascending: false });

            if (resultsList && !resultsError && resultsList.length > 0) {
                const fullResults = await Promise.all(
                    resultsList.map(async (r) => {
                        const { data: subjectsData } = await supabase
                            .from("result_subjects")
                            .select("code, name, grade, credits, status")
                            .eq("result_id", r.id);
                        return {
                            semester: r.semester,
                            gpa: Number(r.gpa),
                            cgpa: Number(r.cgpa),
                            subjects: subjectsData || []
                        };
                    })
                );
                return res.json(fullResults);
            }
        }
        return res.json(mockDb.results);
    } catch (err) {
        console.error("Error in getStudentResults:", err);
        return res.json(mockDb.results);
    }
};
