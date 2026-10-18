const { createClient } = require("@supabase/supabase-js");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../../.env") });

const supabaseUrl = process.env.SUPABASE_URL || "https://luzdjghixvegqlwaeyna.supabase.co";
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY && process.env.SUPABASE_SERVICE_ROLE_KEY !== "YOUR_SUPABASE_SERVICE_ROLE_KEY"
    ? process.env.SUPABASE_SERVICE_ROLE_KEY
    : (process.env.SUPABASE_ANON_KEY && process.env.SUPABASE_ANON_KEY !== "YOUR_SUPABASE_ANON_KEY"
        ? process.env.SUPABASE_ANON_KEY
        : null);

let supabase = null;
const isConfigured = Boolean(supabaseUrl && supabaseKey);

if (isConfigured) {
    try {
        supabase = createClient(supabaseUrl, supabaseKey);
        console.log(" Connected to Supabase:", supabaseUrl);
    } catch (err) {
        console.warn(" Failed to initialize Supabase client, using mock fallback:", err.message);
    }
} else {
    console.log("⚠️ Supabase API key not provided yet in backend/.env.");
    console.log(" Using intelligent mock database fallback for all endpoints.");
    console.log(" Add SUPABASE_ANON_KEY in backend/.env to connect to live Supabase.");
}

// Fallback Mock Data Store (Synchronized with HITAM ERP data)
const mockDb = {
    student: {
        id: "",
        name: "",
        department: "",
        year: "",
        attendance: 0,
        assignmentsPending: 0,
        upcomingExams: 0,
        newAnnouncements: 0
    },
    attendance: {
        studentId: "",
        studentName: "",
        department: "",
        semester: "",
        overallAttendance: 0,
        totalClasses: 0,
        attendedClasses: 0,
        marginClasses: 0,
        subjects: []
    },
    assignments: [
        {
            id: "ASG001",
            title: "Binary Search Implementation",
            subject: "Data Structures",
            code: "CS301PC",
            faculty: "Dr. Ramesh Kumar",
            dueDate: "20 August 2026",
            status: "Pending",
            points: 25,
            urgency: "Due in 2 days",
            description: "Implement iterative and recursive binary search algorithms in C++/Java with comprehensive time and space complexity proofs.",
            instructions: "Include unit test cases covering edge cases such as empty array, single element, negative numbers, and target-not-found scenarios."
        },
        {
            id: "ASG002",
            title: "ML Classification Report",
            subject: "Machine Learning",
            code: "CS702PE",
            faculty: "HITAM Faculty",
            dueDate: "22 August 2026",
            status: "Pending",
            points: 30,
            urgency: "Due in 4 days",
            description: "Train and benchmark Decision Tree and Random Forest classifiers on the provided customer churn dataset.",
            instructions: "Report confusion matrix, ROC-AUC curve, precision-recall trade-offs, and feature importance scores in a structured PDF document."
        },
        {
            id: "ASG003",
            title: "TCP/IP Protocol Analysis",
            subject: "Computer Networks",
            code: "CS701PC",
            faculty: "Dr. K. Srinivas Rao",
            dueDate: "25 August 2026",
            status: "Pending",
            points: 25,
            urgency: "Due in 7 days",
            description: "Analyze Wireshark packet capture traces for three-way handshakes, TCP sequence numbers, retransmissions, and flow control windows.",
            instructions: "Attach pcap export screenshots and detailed sequence number exchange timing diagrams."
        },
        {
            id: "ASG004",
            title: "Software Testing Case Study",
            subject: "Software Engineering",
            code: "CS503PC",
            faculty: "Prof. Ananya Roy",
            dueDate: "18 August 2026",
            status: "Completed",
            points: 25,
            urgency: "Submitted On Time",
            description: "Write unit and integration test suites using JUnit/PyTest for an e-commerce checkout and payment reconciliation module.",
            submittedDate: "17 August 2026, 09:30 PM",
            score: "24/25",
            grade: "Grade A+",
            feedback: "Exceptional test coverage (98%) and clear boundary value analysis. Well-documented code and edge cases handled effectively."
        }
    ],
    exams: [
        { id: "EXM001", subject: "Machine Learning", date: "12 September 2026", time: "10:00 AM - 01:00 PM", room: "Hall 302", venue: "Hall 302 (Block B, 3rd Floor)", type: "Mid Term", code: "CS602", maxMarks: 75, status: "Upcoming", duration: "3 Hours", seat: "B2-14" },
        { id: "EXM002", subject: "Computer Networks", date: "15 September 2026", time: "02:00 PM - 05:00 PM", room: "Lab 2", venue: "Lab 2 (Networking Lab, Block C)", type: "Lab Exam", code: "CS603", maxMarks: 50, status: "Upcoming", duration: "3 Hours", seat: "C3-08" },
        { id: "EXM003", subject: "Software Engineering & Agile", date: "18 September 2026", time: "10:00 AM - 01:00 PM", room: "Auditorium Hall A", venue: "Auditorium Hall A (Main Campus)", type: "Mid Term", code: "CS604", maxMarks: 75, status: "Upcoming", duration: "3 Hours", seat: "A1-22" },
        { id: "EXM004", subject: "Cloud Computing & DevOps Lab", date: "22 September 2026", time: "09:30 AM - 12:30 PM", room: "Cloud Lab 1", venue: "Cloud Lab 1 (Tech Center, 2nd Floor)", type: "Lab Exam", code: "CS605", maxMarks: 50, status: "Upcoming", duration: "3 Hours", seat: "TC-05" },
        { id: "EXM005", subject: "Data Structures & Algorithms", date: "26 September 2026", time: "10:00 AM - 01:00 PM", room: "Hall 101", venue: "Hall 101 (Examinations Wing)", type: "End Semester", code: "CS601", maxMarks: 100, status: "Upcoming", duration: "3 Hours", seat: "EW-31" }
    ],
    results: [
        {
            semester: "Semester 6",
            gpa: 8.65,
            cgpa: 8.42,
            subjects: [
                { code: "CS601", name: "Data Structures & Algorithms", grade: "A+", credits: 4, status: "Pass" },
                { code: "CS602", name: "Machine Learning", grade: "A", credits: 4, status: "Pass" },
                { code: "CS603", name: "Computer Networks", grade: "A", credits: 3, status: "Pass" },
                { code: "CS604", name: "Software Engineering", grade: "A+", credits: 3, status: "Pass" },
                { code: "CS605", name: "Cloud Computing Lab", grade: "O", credits: 2, status: "Pass" }
            ]
        },
        {
            semester: "Semester 5",
            gpa: 8.40,
            cgpa: 8.38,
            subjects: [
                { code: "CS501", name: "Design & Analysis of Algorithms", grade: "A+", credits: 4, status: "Pass" },
                { code: "CS502", name: "Database Management Systems", grade: "O", credits: 4, status: "Pass" },
                { code: "CS503", name: "Operating Systems", grade: "A", credits: 3, status: "Pass" },
                { code: "CS504", name: "Formal Languages & Automata", grade: "B+", credits: 3, status: "Pass" },
                { code: "CS505", name: "DBMS & OS Virtual Lab", grade: "O", credits: 2, status: "Pass" }
            ]
        },
        {
            semester: "Semester 4",
            gpa: 8.50,
            cgpa: 8.36,
            subjects: [
                { code: "CS401", name: "Computer Organization & Arch", grade: "A", credits: 4, status: "Pass" },
                { code: "CS402", name: "Java & OOP Systems", grade: "O", credits: 4, status: "Pass" },
                { code: "CS403", name: "Discrete Mathematical Structures", grade: "A+", credits: 3, status: "Pass" },
                { code: "CS404", name: "Environmental Engineering", grade: "A", credits: 2, status: "Pass" },
                { code: "CS405", name: "Java Programming Laboratory", grade: "O", credits: 2, status: "Pass" }
            ]
        }
    ],
    faculty: {
        id: "FAC001",
        name: "Dr. Ramesh",
        department: "CSE",
        students: 42,
        attendanceManagement: "Manage",
        activeAssignments: 5,
        announcements: "Create",
        timetable: "View"
    },
    facultyStudents: [],
    facultyAssignments: [
        {
            id: "ASG001",
            subject: "Data Structures",
            code: "CS301PC",
            title: "Binary Search Implementation",
            faculty: "Dr. Ramesh Kumar",
            dueDate: "20 August 2026",
            points: 25,
            totalStudents: 0,
            status: "Active",
            description: "Implement iterative and recursive binary search algorithms in C++/Java with comprehensive time and space complexity proofs.",
            instructions: "Upload solutions strictly in PDF format. Include boundary condition test cases.",
            submissions: []
        },
        {
            id: "ASG002",
            subject: "Machine Learning",
            code: "CS702PE",
            title: "ML Classification Report",
            faculty: "HITAM Faculty",
            dueDate: "22 August 2026",
            points: 30,
            totalStudents: 0,
            status: "Active",
            description: "Train and benchmark Decision Tree and Random Forest classifiers on the customer churn dataset.",
            instructions: "Submit comparative ROC-AUC graphs, confusion matrices and hyperparameter tuning analysis in PDF format.",
            submissions: []
        },
        {
            id: "ASG003",
            subject: "Computer Networks",
            code: "CS701PC",
            title: "TCP/IP Protocol Analysis",
            faculty: "Dr. K. Srinivas Rao",
            dueDate: "25 August 2026",
            points: 25,
            totalStudents: 0,
            status: "Active",
            description: "Analyze Wireshark packet capture traces for three-way handshakes, TCP sequence numbers, and retransmissions.",
            instructions: "Include annotated Wireshark packet captures and sequence diagrams in PDF format.",
            submissions: []
        },
        {
            id: "ASG004",
            subject: "Software Engineering",
            code: "CS503PC",
            title: "Software Testing Case Study",
            faculty: "Prof. Ananya Roy",
            dueDate: "18 August 2026",
            points: 25,
            totalStudents: 0,
            status: "Completed",
            description: "Write unit and integration test suites using JUnit/PyTest for an e-commerce checkout module.",
            instructions: "Provide PDF report with JaCoCo / PyTest test coverage metrics and defect log.",
            submissions: []
        }
    ],
    facultyAttendanceList: [],
    parent: {
        parentName: "",
        studentName: "",
        studentId: "",
        attendance: 0,
        assignmentsPending: 0,
        upcomingExams: 0,
        feeReminder: "",
        newAnnouncements: 0,
        rollNo: "",
        department: "",
        overallAttendance: "0%",
        pendingFees: "₹0",
        recentGpa: "0.0",
        alerts: 0
    },
    parentFees: {
        studentName: "",
        studentId: "",
        department: "",
        academicYear: "",
        totalFee: 0,
        paidFee: 0,
        pendingFee: 0,
        dueDate: "",
        status: "",
        breakdown: []
    },
    fees: [
        { feeType: "Academic Tuition Fee", totalAmount: 85000, paidAmount: 60000, dueAmount: 25000, dueDate: "30 August 2026", status: "Pending" },
        { feeType: "College Bus Transport", totalAmount: 25000, paidAmount: 25000, dueAmount: 0, dueDate: "15 July 2026", status: "Paid" },
        { feeType: "Examination Fee", totalAmount: 2500, paidAmount: 2500, dueAmount: 0, dueDate: "10 August 2026", status: "Paid" },
        { feeType: "Library & Lab Deposit", totalAmount: 5000, paidAmount: 5000, dueAmount: 0, dueDate: "01 June 2026", status: "Paid" }
    ],
    adminSummary: {
        totalStudents: 1240,
        totalFaculty: 85,
        totalDepartments: 6,
        feeCollectionRate: "91%",
        activeExams: 3,
        systemAlerts: 1
    },
    adminStudents: [],
    adminFaculty: [
        { id: "FAC001", name: "Dr. Ramesh", department: "CSE", designation: "HOD & Professor", email: "ramesh@hitam.edu", phone: "+91 9876543210" },
        { id: "FAC002", name: "Dr. Sharma", department: "ECE", designation: "Professor", email: "sharma@hitam.edu", phone: "+91 9876543211" },
        { id: "FAC003", name: "Prof. Priya", department: "CSE", designation: "Assistant Professor", email: "priya@hitam.edu", phone: "+91 9876543212" }
    ],
    announcements: [
        {
            id: 1,
            title: "Campus Placement Drive 2026",
            content: "TCS and Infosys recruitment registrations are now officially open for final year CSE & ECE students. Eligible candidates must complete company profile registration on the portal before Friday 5:00 PM.",
            message: "TCS and Infosys recruitment registrations are now officially open for final year CSE & ECE students. Eligible candidates must complete company profile registration on the portal before Friday 5:00 PM.",
            author: "Dr. Ramesh Kumar",
            role: "Placement Dean",
            category: "Placements",
            type: "Placements",
            priority: "urgent",
            isPinned: true,
            department: "Training & Placements",
            targetAudience: "Final Year B.Tech",
            refNo: "HITAM/TPO/2026/048",
            attachment: "TCS_Infosys_Drive_Eligibility_2026.pdf",
            date: "Today"
        },
        {
            id: 2,
            title: "Mid-Semester Examination Schedule (Odd Sem)",
            content: "Mid-Term Examinations for 3rd and 4th year B.Tech students will commence from 12th September 2026. Hall tickets and session timetables can be accessed from the examination tab.",
            message: "Mid-Term Examinations for 3rd and 4th year B.Tech students will commence from 12th September 2026. Hall tickets and session timetables can be accessed from the examination tab.",
            author: "Dr. Sharma",
            role: "Examination Cell",
            category: "Examinations",
            type: "Examinations",
            priority: "urgent",
            isPinned: true,
            department: "Controller of Examinations",
            targetAudience: "3rd & 4th Year B.Tech",
            refNo: "HITAM/EXAM/2026/102",
            attachment: "Mid_Term_Timetable_ODD_SEM.pdf",
            date: "Yesterday"
        },
        {
            id: 3,
            title: "Tuition Fee Payment Reminder & Concession Form",
            content: "Last date for odd semester academic fee payment without late penalty is 30th August. Merit-based fee concession applications are also available at the accounts office.",
            message: "Last date for odd semester academic fee payment without late penalty is 30th August. Merit-based fee concession applications are also available at the accounts office.",
            author: "Finance Dept",
            role: "Administration",
            category: "Finance",
            type: "Finance",
            priority: "normal",
            isPinned: false,
            department: "Accounts & Fees",
            targetAudience: "All Students & Parents",
            refNo: "HITAM/ACC/2026/031",
            attachment: "Fee_Structure_and_Payment_Challan.pdf",
            date: "3 days ago"
        },
        {
            id: 4,
            title: "Independence Day Celebrations & Holiday Notice",
            content: "The college campus will host the 80th Independence Day Flag Hoisting ceremony at 8:30 AM on 15th August. Academic classes will remain closed for the national holiday.",
            message: "The college campus will host the 80th Independence Day Flag Hoisting ceremony at 8:30 AM on 15th August. Academic classes will remain closed for the national holiday.",
            author: "Principal Office",
            role: "Administration",
            category: "Holiday",
            type: "Holiday",
            priority: "normal",
            isPinned: false,
            department: "Principal Office",
            targetAudience: "All Students, Staff & Faculty",
            refNo: "HITAM/GEN/2026/019",
            attachment: null,
            date: "5 days ago"
        }
    ],
    notifications: [],
    deviceTokens: []
};

module.exports = {
    supabase,
    isConfigured,
    mockDb
};
