-- =====================================================
-- Student Courses and Grades Setup
-- Current Semester Courses with Midterm Scores
-- All Semester CGPA History
-- =====================================================

-- =====================================================
-- 1. CREATE CURRENT SEMESTER COURSES (Level 4, Semester 1)
-- =====================================================

-- Software Engineering II
INSERT INTO "Course" (
    "Code", 
    "Title", 
    "Credits", 
    "Description", 
    "CourseLevel", 
    "Category",
    "IsMandatory"
) VALUES (
    'CS411',
    'Software Engineering II',
    3,
    'Advanced software engineering principles, software design patterns, and project management',
    'Level 4',
    'Core',
    true
) ON CONFLICT ("Code") DO NOTHING;

-- Computer Graphics
INSERT INTO "Course" (
    "Code", 
    "Title", 
    "Credits", 
    "Description", 
    "CourseLevel", 
    "Category",
    "IsMandatory"
) VALUES (
    'CS412',
    'Computer Graphics',
    3,
    'Fundamentals of computer graphics, 2D/3D transformations, rendering, and graphics programming',
    'Level 4',
    'Core',
    true
) ON CONFLICT ("Code") DO NOTHING;

-- Microsystems
INSERT INTO "Course" (
    "Code", 
    "Title", 
    "Credits", 
    "Description", 
    "CourseLevel", 
    "Category",
    "IsMandatory"
) VALUES (
    'CS413',
    'Microsystems',
    3,
    'Study of microprocessor systems, embedded systems, and microcontroller programming',
    'Level 4',
    'Core',
    true
) ON CONFLICT ("Code") DO NOTHING;

-- Digital Signal Processing
INSERT INTO "Course" (
    "Code", 
    "Title", 
    "Credits", 
    "Description", 
    "CourseLevel", 
    "Category",
    "IsMandatory"
) VALUES (
    'CS414',
    'Digital Signal Processing',
    3,
    'Digital signal processing techniques, filters, transforms, and signal analysis',
    'Level 4',
    'Core',
    true
) ON CONFLICT ("Code") DO NOTHING;

-- Assembly Language
INSERT INTO "Course" (
    "Code", 
    "Title", 
    "Credits", 
    "Description", 
    "CourseLevel", 
    "Category",
    "IsMandatory"
) VALUES (
    'CS415',
    'Assembly Language',
    3,
    'Low-level programming using assembly language, computer architecture, and system programming',
    'Level 4',
    'Core',
    true
) ON CONFLICT ("Code") DO NOTHING;

-- =====================================================
-- 2. ENROLL STUDENT IN COURSES
-- =====================================================
-- Assuming student with email hosam.100308@cs.mti.edu.eg
-- Replace with actual StudentId, SectionId, and OfferingId

-- First, we need to create course offerings and sections
-- This is a simplified version - adjust IDs as needed

-- Note: You'll need to create LectureCourseOffering, SectionCourseOffering first
-- Then use StudentSection to enroll the student
-- Below is a template that assumes these exist

-- Example enrollment (adjust based on your actual IDs):
/*
INSERT INTO "StudentSection" (
    "StudentId",
    "SectionCourseOfferingId",
    "EnrollmentStatus",
    "EnrollmentDate"
) 
SELECT 
    s."StudentId",
    sco."SectionCourseOfferingId",
    'Enrolled',
    '2024-09-01'
FROM "Student" s
CROSS JOIN "SectionCourseOffering" sco
INNER JOIN "Course" c ON sco."CourseId" = c."CourseId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
  AND c."Code" IN ('CS411', 'CS412', 'CS413', 'CS414', 'CS415')
  AND sco."Semester" = 'Fall'
  AND sco."AcademicYear" = 2024
ON CONFLICT DO NOTHING;
*/

-- =====================================================
-- 3. ADD MIDTERM SCORES
-- =====================================================
-- Assuming SectionGrade table exists and is linked to StudentSection

-- Software Engineering II - Midterm: 18
/*
INSERT INTO "SectionGrade" (
    "StudentSectionId",
    "MidtermExam",
    "UpdatedAt"
)
SELECT 
    ss."StudentSectionId",
    18,
    NOW()
FROM "StudentSection" ss
INNER JOIN "SectionCourseOffering" sco ON ss."SectionCourseOfferingId" = sco."SectionCourseOfferingId"
INNER JOIN "Course" c ON sco."CourseId" = c."CourseId"
INNER JOIN "Student" s ON ss."StudentId" = s."StudentId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
  AND c."Code" = 'CS411'
ON CONFLICT ("StudentSectionId") 
DO UPDATE SET 
    "MidtermExam" = 18,
    "UpdatedAt" = NOW();

-- Computer Graphics - Midterm: 12
INSERT INTO "SectionGrade" (
    "StudentSectionId",
    "MidtermExam",
    "UpdatedAt"
)
SELECT 
    ss."StudentSectionId",
    12,
    NOW()
FROM "StudentSection" ss
INNER JOIN "SectionCourseOffering" sco ON ss."SectionCourseOfferingId" = sco."SectionCourseOfferingId"
INNER JOIN "Course" c ON sco."CourseId" = c."CourseId"
INNER JOIN "Student" s ON ss."StudentId" = s."StudentId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
  AND c."Code" = 'CS412'
ON CONFLICT ("StudentSectionId") 
DO UPDATE SET 
    "MidtermExam" = 12,
    "UpdatedAt" = NOW();

-- Microsystems - Midterm: 20
INSERT INTO "SectionGrade" (
    "StudentSectionId",
    "MidtermExam",
    "UpdatedAt"
)
SELECT 
    ss."StudentSectionId",
    20,
    NOW()
FROM "StudentSection" ss
INNER JOIN "SectionCourseOffering" sco ON ss."SectionCourseOfferingId" = sco."SectionCourseOfferingId"
INNER JOIN "Course" c ON sco."CourseId" = c."CourseId"
INNER JOIN "Student" s ON ss."StudentId" = s."StudentId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
  AND c."Code" = 'CS413'
ON CONFLICT ("StudentSectionId") 
DO UPDATE SET 
    "MidtermExam" = 20,
    "UpdatedAt" = NOW();

-- Digital Signal Processing - Midterm: 18
INSERT INTO "SectionGrade" (
    "StudentSectionId",
    "MidtermExam",
    "UpdatedAt"
)
SELECT 
    ss."StudentSectionId",
    18,
    NOW()
FROM "StudentSection" ss
INNER JOIN "SectionCourseOffering" sco ON ss."SectionCourseOfferingId" = sco."SectionCourseOfferingId"
INNER JOIN "Course" c ON sco."CourseId" = c."CourseId"
INNER JOIN "Student" s ON ss."StudentId" = s."StudentId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
  AND c."Code" = 'CS414'
ON CONFLICT ("StudentSectionId") 
DO UPDATE SET 
    "MidtermExam" = 18,
    "UpdatedAt" = NOW();

-- Assembly Language - Midterm: 20
INSERT INTO "SectionGrade" (
    "StudentSectionId",
    "MidtermExam",
    "UpdatedAt"
)
SELECT 
    ss."StudentSectionId",
    20,
    NOW()
FROM "StudentSection" ss
INNER JOIN "SectionCourseOffering" sco ON ss."SectionCourseOfferingId" = sco."SectionCourseOfferingId"
INNER JOIN "Course" c ON sco."CourseId" = c."CourseId"
INNER JOIN "Student" s ON ss."StudentId" = s."StudentId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
  AND c."Code" = 'CS415'
ON CONFLICT ("StudentSectionId") 
DO UPDATE SET 
    "MidtermExam" = 20,
    "UpdatedAt" = NOW();
*/

-- =====================================================
-- 4. UPDATE SEMESTER CGPA HISTORY
-- =====================================================
-- If you have a SemesterGPA table or similar

-- Create SemesterGPA table if it doesn't exist
CREATE TABLE IF NOT EXISTS "SemesterGPA" (
    "SemesterGPAId" SERIAL PRIMARY KEY,
    "StudentId" VARCHAR(50) NOT NULL,
    "AcademicYear" INTEGER NOT NULL,
    "Semester" VARCHAR(20) NOT NULL,
    "SemesterNumber" INTEGER NOT NULL,
    "GPA" NUMERIC(3,2) NOT NULL,
    "Credits" INTEGER,
    "CreatedAt" TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY ("StudentId") REFERENCES "Student"("StudentId"),
    UNIQUE ("StudentId", "AcademicYear", "Semester")
);

-- Insert Semester GPA history
INSERT INTO "SemesterGPA" ("StudentId", "AcademicYear", "Semester", "SemesterNumber", "GPA", "Credits")
SELECT 
    s."StudentId",
    2022,
    'Fall',
    1,
    3.57,
    18
FROM "Student" s
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
ON CONFLICT ("StudentId", "AcademicYear", "Semester") 
DO UPDATE SET "GPA" = 3.57;

INSERT INTO "SemesterGPA" ("StudentId", "AcademicYear", "Semester", "SemesterNumber", "GPA", "Credits")
SELECT 
    s."StudentId",
    2023,
    'Spring',
    2,
    3.83,
    18
FROM "Student" s
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
ON CONFLICT ("StudentId", "AcademicYear", "Semester") 
DO UPDATE SET "GPA" = 3.83;

INSERT INTO "SemesterGPA" ("StudentId", "AcademicYear", "Semester", "SemesterNumber", "GPA", "Credits")
SELECT 
    s."StudentId",
    2023,
    'Fall',
    3,
    3.73,
    18
FROM "Student" s
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
ON CONFLICT ("StudentId", "AcademicYear", "Semester") 
DO UPDATE SET "GPA" = 3.73;

INSERT INTO "SemesterGPA" ("StudentId", "AcademicYear", "Semester", "SemesterNumber", "GPA", "Credits")
SELECT 
    s."StudentId",
    2024,
    'Spring',
    4,
    3.50,
    18
FROM "Student" s
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
ON CONFLICT ("StudentId", "AcademicYear", "Semester") 
DO UPDATE SET "GPA" = 3.50;

INSERT INTO "SemesterGPA" ("StudentId", "AcademicYear", "Semester", "SemesterNumber", "GPA", "Credits")
SELECT 
    s."StudentId",
    2024,
    'Summer',
    5,
    3.63,
    12
FROM "Student" s
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
ON CONFLICT ("StudentId", "AcademicYear", "Semester") 
DO UPDATE SET "GPA" = 3.63;

INSERT INTO "SemesterGPA" ("StudentId", "AcademicYear", "Semester", "SemesterNumber", "GPA", "Credits")
SELECT 
    s."StudentId",
    2024,
    'Fall',
    6,
    3.67,
    18
FROM "Student" s
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
ON CONFLICT ("StudentId", "AcademicYear", "Semester") 
DO UPDATE SET "GPA" = 3.67;

-- =====================================================
-- 5. UPDATE CUMULATIVE GPA
-- =====================================================
-- Calculate and update CumulativeGPA based on all semesters
UPDATE "Student" s
SET "CumulativeGPA" = (
    SELECT ROUND(AVG(gpa."GPA")::numeric, 2)
    FROM "SemesterGPA" gpa
    WHERE gpa."StudentId" = s."StudentId"
)
FROM "User" u
WHERE s."UserId" = u."UserId"
  AND u."Email" = 'hosam.100308@cs.mti.edu.eg';

-- =====================================================
-- 6. VERIFICATION QUERIES
-- =====================================================

-- Check all current semester courses
SELECT 
    c."Code",
    c."Title",
    sg."MidtermExam",
    sg."Total",
    sg."LetterGrade"
FROM "StudentSection" ss
INNER JOIN "SectionCourseOffering" sco ON ss."SectionCourseOfferingId" = sco."SectionCourseOfferingId"
INNER JOIN "Course" c ON sco."CourseId" = c."CourseId"
LEFT JOIN "SectionGrade" sg ON ss."StudentSectionId" = sg."StudentSectionId"
INNER JOIN "Student" s ON ss."StudentId" = s."StudentId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
  AND sco."Semester" = 'Fall'
  AND sco."AcademicYear" = 2024
ORDER BY c."Code";

-- Check semester GPA history
SELECT 
    "SemesterNumber",
    "AcademicYear",
    "Semester",
    "GPA",
    "Credits"
FROM "SemesterGPA" sgpa
INNER JOIN "Student" s ON sgpa."StudentId" = s."StudentId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
ORDER BY "SemesterNumber";

-- Check cumulative GPA
SELECT 
    u."FullName",
    s."CumulativeGPA"
FROM "Student" s
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg';

-- =====================================================
-- SUMMARY:
-- =====================================================
-- Current Semester (Level 4, Semester 1 - Fall 2024):
--   1. CS411: Software Engineering II      - Midterm: 18/25
--   2. CS412: Computer Graphics            - Midterm: 12/25
--   3. CS413: Microsystems                 - Midterm: 20/25
--   4. CS414: Digital Signal Processing    - Midterm: 18/25
--   5. CS415: Assembly Language            - Midterm: 20/25
--
-- Semester GPA History:
--   Semester 1 (Fall 2022):    3.57
--   Semester 2 (Spring 2023):  3.83
--   Semester 3 (Fall 2023):    3.73
--   Semester 4 (Spring 2024):  3.50
--   Semester 5 (Summer 2024):  3.63
--   Semester 6 (Fall 2024):    3.67
--
-- Cumulative GPA: 3.66 (Average of all semesters)
-- =====================================================



