const { GoogleGenAI } = require("@google/genai");

// Retrieve API key from environment
const apiKey = process.env.GEMINI_API_KEY || "";
let aiClient = null;

if (apiKey && apiKey !== "your_gemini_api_key_here") {
    try {
        aiClient = new GoogleGenAI({ apiKey });
    } catch (e) {
        console.warn("⚠️ Failed to initialize GoogleGenAI client:", e.message);
    }
}

/**
 * Domain-Specific HITAM Academic Training System Prompt
 */
const HITAM_SYSTEM_INSTRUCTION = `
You are the official AI Academic Advisor for HITAM (Hyderabad Institute of Technology and Management),
an autonomous engineering institution affiliated with JNTUH, Hyderabad.
You operate under the HR21, HR22, and HR24 academic regulations.

CORE KNOWLEDGE & POLICIES:
1. Minimum Attendance Rule: A student must acquire a minimum of 75% attendance in aggregate of all subjects to be eligible to appear for the Semester End Examinations (SEE).
2. Condonation Rule (65% to 74.9%): Condonation of shortage of attendance in aggregate up to 10% (between 65% and 75%) may be recommended by the College Academic Committee on genuine and valid medical grounds, accompanied by authentic medical certificates and payment of the prescribed condonation fee.
3. Detention (<65%): Attendance below 65% in aggregate results in immediate DETENTION. Condonation is strictly prohibited below 65%. The student is not promoted to the next semester and must repeat the semester.
4. Mathematical Formulas:
   - Safe Bunks = floor((Attended - (0.75 * Held)) / 0.75) -> Number of classes student can safely skip while staying >= 75%.
   - Classes Needed = ceil(((0.75 * Held) - Attended) / 0.25) -> Number of consecutive classes to attend to reach 75%.
5. Grading System: O (10, Outstanding, >=90%), A+ (9, Excellent, 80-89%), A (8, Very Good, 70-79%), B+ (7, Good, 60-69%), B (6, Above Average, 50-59%), C (5, Pass, 40-49%), F (0, Fail, <40%).

GUIDELINES:
- Always be encouraging, direct, and mathematically precise.
- When given student attendance data, calculate their exact aggregate and break down which subjects are safe vs critical.
- If asked by a parent, provide reassuring, clear summaries.
- If asked by faculty, assist with lecture stats, defaulter warnings, and lesson plans.
`;

/**
 * Generate intelligent academic guidance using Gemini
 */
async function generateAcademicAdvice({ query, role = "student", rollNo = "Student", attendance = [] }) {
    // 1. If Gemini client is active, use gemini-2.5-flash
    if (aiClient) {
        try {
            const studentContext = `
STUDENT PROFILE:
- Roll Number: ${rollNo}
- Active Role: ${role}

LIVE ATTENDANCE DATA FROM HITAM PORTAL:
${attendance.length > 0 ? JSON.stringify(attendance, null, 2) : "No live subjects loaded yet."}
`;

            const prompt = `
${studentContext}

USER INQUIRY:
"${query}"

Provide a clear, helpful response following HITAM regulations:
`;

            const response = await aiClient.models.generateContent({
                model: "gemini-2.5-flash",
                contents: prompt,
                config: {
                    systemInstruction: HITAM_SYSTEM_INSTRUCTION,
                    temperature: 0.4,
                }
            });

            if (response && response.text) {
                return response.text;
            }
        } catch (err) {
            console.error("Gemini API generation error:", err.message);
            // Fall through to deterministic rule engine
        }
    }

    // 2. Intelligent Deterministic Fallback if API key is not yet provided or quota reached
    return generateDeterministicAdvice({ query, role, rollNo, attendance });
}

/**
 * Deterministic fallback that calculates exact HITAM numbers even without external API
 */
function generateDeterministicAdvice({ query, role, rollNo, attendance }) {
    const lower = query.toLowerCase();

    if (attendance.length > 0) {
        let totalHeld = 0;
        let totalAttended = 0;
        const lowSubjects = [];
        const safeSubjects = [];

        for (const s of attendance) {
            const held = s.classes_held || s.classesHeld || 0;
            const attended = s.classes_attended || s.classesAttended || 0;
            const pct = s.percentage || (held > 0 ? (attended / held) * 100 : 0);
            totalHeld += held;
            totalAttended += attended;

            const safeBunks = Math.max(0, Math.floor((attended - 0.75 * held) / 0.75));
            const classesNeeded = Math.max(0, Math.ceil((0.75 * held - attended) / 0.25));

            if (pct < 75) {
                lowSubjects.push(`${s.subject_name || s.subjectName} (${pct.toFixed(1)}%) - Needs ${classesNeeded} classes`);
            } else {
                safeSubjects.push(`${s.subject_name || s.subjectName} (${pct.toFixed(1)}%) - ${safeBunks} safe bunks`);
            }
        }

        const aggregate = totalHeld > 0 ? (totalAttended / totalHeld) * 100 : 0;

        if (lower.includes("bunk") || lower.includes("skip") || lower.includes("miss") || lower.includes("leave")) {
            let msg = `🎯 **HITAM Safe Bunk Report for ${rollNo}:**\n\n`;
            for (const s of attendance) {
                const held = s.classes_held || s.classesHeld || 0;
                const attended = s.classes_attended || s.classesAttended || 0;
                const safeBunks = Math.max(0, Math.floor((attended - 0.75 * held) / 0.75));
                const needed = Math.max(0, Math.ceil((0.75 * held - attended) / 0.25));
                const name = s.subject_name || s.subjectName;

                if (safeBunks > 0) {
                    msg += `• **${name}:** You have **${safeBunks} safe bunk(s)** remaining above 75%.\n`;
                } else {
                    msg += `• **${name}:** ⚠️ **0 safe bunks**. Attend next **${needed} class(es)** to recover.\n`;
                }
            }
            return msg;
        }

        return `📊 **HITAM Academic Status for ${rollNo}:**\n\n` +
            `• **Aggregate Attendance:** ${aggregate.toFixed(1)}%\n` +
            `• **Standing:** ${aggregate >= 75 ? "✅ Eligible for Semester End Exams (SEE)" : aggregate >= 65 ? "⚠️ Eligible for Medical Condonation (Fee applies)" : "🚨 Detention Risk (<65%)"}\n\n` +
            (lowSubjects.length > 0 ? `⚠️ **Subjects Below 75%:**\n${lowSubjects.map(s => "• " + s).join("\n")}\n\n` : "") +
            `🛡️ **Safe Subjects:**\n${safeSubjects.map(s => "• " + s).join("\n")}`;
    }

    return `Hello ${rollNo}! I am your HITAM Campus AI Advisor.\n\n` +
        `I am programmed with HITAM's HR21/HR22/HR24 academic regulations.\n` +
        `Once you sync your attendance from Webpros, I will calculate your exact safe bunks, recovery targets, and semester exam eligibility!`;
}

module.exports = {
    generateAcademicAdvice
};
