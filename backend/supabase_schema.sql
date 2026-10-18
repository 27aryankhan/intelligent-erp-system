-- ==============================================================================
-- INTELLIGENT ERP SYSTEM (HITAM) - SUPABASE POSTGRESQL SCHEMA & SEED DATA
-- Project Reference: luzdjghixvegqlwaeyna
-- URL: https://luzdjghixvegqlwaeyna.supabase.co
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. DROP EXISTING TABLES IF RE-RUNNING (Safe Cascade)
DROP TABLE IF EXISTS fees CASCADE;
DROP TABLE IF EXISTS announcements CASCADE;
DROP TABLE IF EXISTS faculty_attendance CASCADE;
DROP TABLE IF EXISTS assignment_submissions CASCADE;
DROP TABLE IF EXISTS assignments CASCADE;
DROP TABLE IF EXISTS result_subjects CASCADE;
DROP TABLE IF EXISTS results CASCADE;
DROP TABLE IF EXISTS exams CASCADE;
DROP TABLE IF EXISTS attendance_subjects CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS faculty CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- 3. PROFILES / USERS TABLE
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('student', 'faculty', 'parent', 'admin')),
    department TEXT DEFAULT 'CSE',
    phone TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. DEPARTMENTS TABLE
CREATE TABLE departments (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    hod_name TEXT,
    building TEXT
);

INSERT INTO departments (code, name, hod_name, building) VALUES
('CSE', 'Computer Science and Engineering', 'Dr. Ramesh', 'Block A'),
('ECE', 'Electronics & Communication Engineering', 'Dr. Sharma', 'Block B'),
('MECH', 'Mechanical Engineering', 'Dr. Reddy', 'Block C'),
('CIVIL', 'Civil Engineering', 'Dr. Varma', 'Block D');

-- 5. STUDENTS TABLE
CREATE TABLE students (
    id TEXT PRIMARY KEY, -- e.g. STU001
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    department TEXT NOT NULL REFERENCES departments(code),
    year TEXT NOT NULL DEFAULT '4th Year',
    overall_attendance INTEGER NOT NULL DEFAULT 85,
    assignments_pending INTEGER NOT NULL DEFAULT 3,
    upcoming_exams INTEGER NOT NULL DEFAULT 2,
    new_announcements INTEGER NOT NULL DEFAULT 4,
    roll_no TEXT,
    parent_email TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. ATTENDANCE SUBJECTS (Detailed breakdown per student)
CREATE TABLE attendance_subjects (
    id SERIAL PRIMARY KEY,
    student_id TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    attended INTEGER NOT NULL,
    total INTEGER NOT NULL,
    percentage INTEGER GENERATED ALWAYS AS (ROUND((attended::NUMERIC / NULLIF(total, 0)) * 100)) STORED
);

-- 7. ASSIGNMENTS TABLE
CREATE TABLE assignments (
    id TEXT PRIMARY KEY, -- e.g. ASG001 / FA001
    title TEXT NOT NULL,
    subject TEXT NOT NULL,
    department TEXT DEFAULT 'CSE',
    due_date TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Pending', -- 'Pending', 'Completed', 'Active'
    submissions INTEGER DEFAULT 0,
    total_students INTEGER DEFAULT 42,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. EXAMINATIONS TABLE
CREATE TABLE exams (
    id TEXT PRIMARY KEY,
    student_id TEXT REFERENCES students(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    exam_date TEXT NOT NULL,
    exam_time TEXT NOT NULL,
    room TEXT NOT NULL,
    exam_type TEXT NOT NULL DEFAULT 'Final Semester' -- 'Mid Term', 'Final Semester', 'Lab Exam'
);

-- 9. RESULTS & GRADES TABLE
CREATE TABLE results (
    id TEXT PRIMARY KEY,
    student_id TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    semester TEXT NOT NULL,
    gpa NUMERIC(4, 2) NOT NULL,
    cgpa NUMERIC(4, 2) NOT NULL
);

CREATE TABLE result_subjects (
    id SERIAL PRIMARY KEY,
    result_id TEXT NOT NULL REFERENCES results(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    grade TEXT NOT NULL,
    credits INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'Pass'
);

-- 10. FACULTY TABLE
CREATE TABLE faculty (
    id TEXT PRIMARY KEY, -- e.g. FAC001
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    department TEXT NOT NULL REFERENCES departments(code),
    students_count INTEGER DEFAULT 42,
    active_assignments INTEGER DEFAULT 5,
    designation TEXT DEFAULT 'Associate Professor',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. FACULTY ATTENDANCE ROSTER (Students under faculty)
CREATE TABLE faculty_attendance (
    id SERIAL PRIMARY KEY,
    faculty_id TEXT NOT NULL REFERENCES faculty(id) ON DELETE CASCADE,
    student_id TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    student_name TEXT NOT NULL,
    attendance INTEGER NOT NULL DEFAULT 85,
    assignments_pending INTEGER NOT NULL DEFAULT 2
);

-- 12. ANNOUNCEMENTS TABLE
CREATE TABLE announcements (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    author_name TEXT NOT NULL,
    author_role TEXT NOT NULL DEFAULT 'Admin', -- 'Admin', 'Faculty'
    target_audience TEXT NOT NULL DEFAULT 'All', -- 'All', 'Students', 'Faculty', 'Parents'
    department TEXT DEFAULT 'All',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. FEES TABLE
CREATE TABLE fees (
    id SERIAL PRIMARY KEY,
    student_id TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    fee_type TEXT NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL,
    paid_amount NUMERIC(10, 2) NOT NULL,
    due_amount NUMERIC(10, 2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
    due_date TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('Paid', 'Pending', 'Overdue'))
);

-- 14. NOTIFICATIONS TABLE (ROLE-BASED & REAL-TIME)
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id TEXT, -- specific student/faculty/parent/admin ID or NULL for broadcast
    target_role TEXT NOT NULL DEFAULT 'all', -- 'all', 'student', 'parent', 'faculty', 'admin'
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'general', -- 'attendance', 'fee', 'assignment', 'exam', 'announcement', 'system'
    target_screen TEXT DEFAULT 'dashboard',
    priority TEXT NOT NULL DEFAULT 'normal', -- 'normal', 'high', 'urgent'
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15. DEVICE TOKENS TABLE (FCM & APNs)
CREATE TABLE IF NOT EXISTS device_tokens (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'student',
    email TEXT,
    token TEXT UNIQUE NOT NULL,
    platform TEXT NOT NULL DEFAULT 'android',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- SEED DATA (HITAM CAMPUS REALISTIC DATA)
-- ==============================================================================

-- Profiles
INSERT INTO profiles (username, email, full_name, role, department) VALUES
('bhargavi', 'bhargavi@hitam.edu', 'Bhargavi', 'student', 'CSE'),
('ramesh', 'ramesh@hitam.edu', 'Dr. Ramesh', 'faculty', 'CSE'),
('parent_bhargavi', 'parent.bhargavi@gmail.com', 'Narayana (Parent)', 'parent', 'CSE'),
('admin', 'admin@hitam.edu', 'HITAM Academic Admin', 'admin', 'CSE');

-- Student: Bhargavi (STU001)
INSERT INTO students (id, name, department, year, overall_attendance, assignments_pending, upcoming_exams, new_announcements, roll_no, parent_email) VALUES
('STU001', 'Student 01', 'CSE', '4th Year', 85, 3, 2, 4, '22K91A0501', 'parent1@hitam.edu'),
('STU002', 'Student 02', 'CSE', '4th Year', 92, 1, 2, 4, '22K91A0502', 'parent2@hitam.edu'),
('STU003', 'Student 03', 'CSE', '4th Year', 78, 4, 2, 4, '22K91A0503', 'parent3@hitam.edu'),
('STU004', 'Student 04', 'CSE', '4th Year', 88, 2, 2, 4, '22K91A0504', 'parent4@hitam.edu');

-- Attendance for Bhargavi
INSERT INTO attendance_subjects (student_id, subject, attended, total) VALUES
('STU001', 'Data Structures', 42, 48),
('STU001', 'Machine Learning', 38, 45),
('STU001', 'Computer Networks', 40, 46),
('STU001', 'Software Engineering', 36, 44);

-- Student Assignments
INSERT INTO assignments (id, title, subject, due_date, status, submissions, total_students) VALUES
('ASG001', 'Binary Search Implementation', 'Data Structures', '20 August 2026', 'Pending', 35, 42),
('ASG002', 'ML Classification Report', 'Machine Learning', '22 August 2026', 'Pending', 30, 42),
('ASG003', 'TCP/IP Protocol Analysis', 'Computer Networks', '25 August 2026', 'Pending', 28, 42),
('ASG004', 'Software Testing Case Study', 'Software Engineering', '18 August 2026', 'Completed', 42, 42);

-- Exams
INSERT INTO exams (id, student_id, subject, exam_date, exam_time, room, exam_type) VALUES
('EXM001', 'STU001', 'Machine Learning', '12 September 2026', '10:00 AM - 01:00 PM', 'Hall 302', 'Mid Term'),
('EXM002', 'STU001', 'Computer Networks', '15 September 2026', '02:00 PM - 05:00 PM', 'Lab 2', 'Lab Exam');

-- Results
INSERT INTO results (id, student_id, semester, gpa, cgpa) VALUES
('RES001', 'STU001', 'Semester 6', 8.65, 8.42);

INSERT INTO result_subjects (result_id, code, name, grade, credits, status) VALUES
('RES001', 'CS601', 'Data Structures & Algorithms', 'A+', 4, 'Pass'),
('RES001', 'CS602', 'Machine Learning', 'A', 4, 'Pass'),
('RES001', 'CS603', 'Computer Networks', 'A', 3, 'Pass'),
('RES001', 'CS604', 'Software Engineering', 'A+', 3, 'Pass'),
('RES001', 'CS605', 'Cloud Computing Lab', 'O', 2, 'Pass');

-- Faculty: Dr. Ramesh
INSERT INTO faculty (id, name, department, students_count, active_assignments, designation) VALUES
('FAC001', 'Dr. Ramesh', 'CSE', 42, 5, 'Associate Professor & HOD');

-- Faculty Roster
INSERT INTO faculty_attendance (faculty_id, student_id, student_name, attendance, assignments_pending) VALUES
('FAC001', 'STU001', '22K91A0501', 85, 3),
('FAC001', 'STU002', '22K91A0502', 92, 1),
('FAC001', 'STU003', '22K91A0503', 78, 4),
('FAC001', 'STU004', '22K91A0504', 88, 2);

-- Announcements
INSERT INTO announcements (title, content, author_name, author_role, target_audience, department) VALUES
('Campus Placement Drive 2026', 'TCS and Infosys recruitment registrations are now open for final year CSE students. Please register before Friday.', 'Dr. Ramesh', 'Faculty', 'Students', 'CSE'),
('Independence Day Holiday Notice', 'College will remain closed on 15th August on the occasion of Independence Day.', 'Admin Office', 'Admin', 'All', 'All'),
('Mid-Semester Examination Schedule', 'Mid-Term Examinations for 3rd and 4th year B.Tech students will commence from 12th September.', 'Examination Cell', 'Admin', 'Students', 'All'),
('Fee Payment Reminder', 'Last date for tuition fee payment for odd semester without late fee is 30th August.', 'Accounts Dept', 'Admin', 'Parents', 'All');

-- Fees for Bhargavi
INSERT INTO fees (student_id, fee_type, total_amount, paid_amount, due_date, status) VALUES
('STU001', 'Academic Tuition Fee', 85000.00, 60000.00, '30 August 2026', 'Pending'),
('STU001', 'College Bus Transport', 25000.00, 25000.00, '15 July 2026', 'Paid'),
('STU001', 'Examination Fee', 2500.00, 2500.00, '10 August 2026', 'Paid'),
('STU001', 'Library & Lab Deposit', 5000.00, 5000.00, '01 June 2026', 'Paid');

-- Seed Role-Based Notifications
INSERT INTO notifications (user_id, target_role, title, body, type, target_screen, priority, is_read) VALUES
-- Student Notifications
('STU001', 'student', 'Attendance Recorded: Present', 'Your attendance for Computer Networks was recorded. Current aggregate: 85%.', 'attendance', 'attendance', 'normal', false),
('STU001', 'student', 'Assignment Due in 24 Hours', 'Perceptron Implementation in Neural Networks is due tomorrow at 11:59 PM.', 'assignment', 'assignments', 'urgent', false),
('STU001', 'student', 'Tuition Fee Due Reminder', 'Second installment of ₹25,000 is due by 30th September without late fees.', 'fee', 'fees', 'high', false),
('STU001', 'student', 'Semester 6 Hall Tickets Released', 'Odd semester mid-term examination timetable is now active. Verify assigned room number.', 'exam', 'exams', 'high', true),

-- Parent Notifications
('PAR001', 'parent', 'Ward Daily Attendance Update', 'Ward was marked Present in all 4 lecture sessions today (Overall: 85%).', 'attendance', 'attendance', 'normal', false),
('PAR001', 'parent', 'Fee Payment Reminder: ₹25,000 Pending', 'The second installment tuition fee of ₹25,000 for academic year 2025-2026 is due soon.', 'fee', 'fees', 'urgent', false),
('PAR001', 'parent', 'Parent-Teacher Meeting (PTM) Scheduled', 'Interactive PTM is scheduled for Saturday 20th September at 10:00 AM in CSE Block.', 'announcement', 'announcements', 'high', false),
('PAR001', 'parent', 'Academic Performance: 8.65 SGPA', 'Ward scored 8.65 SGPA with grade A+ in Data Structures in Semester 6 results.', 'academic', 'academic', 'normal', true),

-- Faculty Notifications
('FAC001', 'faculty', '35 New Assignment Submissions', '35 students submitted Neural Networks assignment "Perceptron Implementation" awaiting evaluation.', 'assignment', 'assignments', 'urgent', false),
('FAC001', 'faculty', 'Daily Attendance Lock Reminder', 'Please finalize and lock Section-A attendance for Computer Networks before 4:30 PM.', 'attendance', 'attendance', 'high', false),
('FAC001', 'faculty', 'Student Medical Leave Request', 'A student submitted a medical leave application for 3 days awaiting your approval.', 'system', 'dashboard', 'normal', false),
('FAC001', 'faculty', 'Curriculum Committee Meeting', 'Academic council curriculum revision meeting tomorrow at 3:00 PM in Conference Hall A.', 'announcement', 'announcements', 'high', true),

-- Administrator Notifications
('ADM001', 'admin', 'Daily Fee Collection Summary', '₹4,85,000 collected today across semester fee installments. 82% target achieved.', 'fee', 'fees', 'high', false),
('ADM001', 'admin', 'Staff Leave Approval Queue', '2 faculty leave applications are pending administrative review and approval.', 'system', 'dashboard', 'normal', false),
('ADM001', 'admin', 'Biometric Access Server Sync', 'Server sync completed successfully across all 6 campus gate scanners and biometric units.', 'system', 'dashboard', 'normal', false),
('ADM001', 'admin', 'Campus Broadcast Ready for Sign-Off', 'Annual technical symposium circular drafted and ready for college-wide release.', 'announcement', 'announcements', 'urgent', true),

-- College-Wide Broadcast
(NULL, 'all', 'Independence Day Celebrations Notice', 'College campus flag hoisting ceremony at 8:30 AM on 15th August. Academic classes remain closed.', 'announcement', 'announcements', 'normal', true);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- We enable RLS and grant public access for development
-- ==============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE results ENABLE ROW LEVEL SECURITY;
ALTER TABLE result_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE faculty ENABLE ROW LEVEL SECURITY;
ALTER TABLE faculty_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Allow anonymous / authenticated read and write for rapid development
CREATE POLICY "Public Read Profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Public Read Departments" ON departments FOR SELECT USING (true);
CREATE POLICY "Public Read Students" ON students FOR ALL USING (true);
CREATE POLICY "Public Read Attendance" ON attendance_subjects FOR ALL USING (true);
CREATE POLICY "Public Read Assignments" ON assignments FOR ALL USING (true);
CREATE POLICY "Public Read Exams" ON exams FOR ALL USING (true);
CREATE POLICY "Public Read Results" ON results FOR ALL USING (true);
CREATE POLICY "Public Read ResultSubjects" ON result_subjects FOR ALL USING (true);
CREATE POLICY "Public Read Faculty" ON faculty FOR ALL USING (true);
CREATE POLICY "Public Read FacultyAttendance" ON faculty_attendance FOR ALL USING (true);
CREATE POLICY "Public Read Announcements" ON announcements FOR ALL USING (true);
CREATE POLICY "Public Read Fees" ON fees FOR ALL USING (true);
CREATE POLICY "Public Read Notifications" ON notifications FOR ALL USING (true);
CREATE POLICY "Public Read DeviceTokens" ON device_tokens FOR ALL USING (true);
