-- ============================================
-- QUICK FIX - Compatible with Your Current Schema
-- Run this if the main script gave DateOfBirth error
-- ============================================

-- First, let's check what columns your User table actually has
-- Run this query first to see your table structure:
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'User';

-- ============================================
-- STEP 1: Create StudentCourseEnrollment Table
-- ============================================

CREATE TABLE IF NOT EXISTS "StudentCourseEnrollment" (
    "EnrollmentId" TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "StudentId" TEXT NOT NULL,
    "LectureOfferingId" TEXT NOT NULL,
    "EnrollmentDate" TIMESTAMP DEFAULT NOW(),
    "Status" TEXT DEFAULT 'Active',
    CONSTRAINT unique_student_lecture UNIQUE ("StudentId", "LectureOfferingId")
);

-- ============================================
-- STEP 2: Create StudentSection Table
-- ============================================

CREATE TABLE IF NOT EXISTS "StudentSection" (
    "EnrollmentId" TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "StudentId" TEXT NOT NULL,
    "SectionOfferingId" TEXT NOT NULL,
    "EnrollmentDate" TIMESTAMP DEFAULT NOW(),
    "Status" TEXT DEFAULT 'Active',
    CONSTRAINT unique_student_section UNIQUE ("StudentId", "SectionOfferingId")
);

-- ============================================
-- STEP 3: Create Test Students (Minimal version)
-- ============================================

-- Insert users WITHOUT DateOfBirth column
INSERT INTO "User" ("UserId", "Email", "FullName", "Role")
VALUES 
    ('user-student-001', 'ahmed.student@mti.edu.eg', 'Ahmed Mohamed Ali', 'student'),
    ('user-student-002', 'fatima.student@mti.edu.eg', 'Fatima Al-Kaabi', 'student'),
    ('user-student-003', 'sara.student@mti.edu.eg', 'Sara Ahmed Hassan', 'student'),
    ('user-student-004', 'mohamed.student@mti.edu.eg', 'Mohamed Ibrahim', 'student'),
    ('user-student-005', 'nour.student@mti.edu.eg', 'Nour Ali Hussein', 'student')
ON CONFLICT ("Email") DO NOTHING;

-- Insert students
INSERT INTO "Student" ("StudentId", "UserId", "StudentCode", "Level")
VALUES 
    ('student-001', 'user-student-001', '200123', 'L2'),
    ('student-002', 'user-student-002', '200124', 'L2'),
    ('student-003', 'user-student-003', '200125', 'L2'),
    ('student-004', 'user-student-004', '200126', 'L2'),
    ('student-005', 'user-student-005', '200127', 'L2')
ON CONFLICT ("StudentId") DO NOTHING;

-- ============================================
-- STEP 4: Enroll Students in Dr. Hanafy's Courses
-- ============================================

-- Get Dr. Hanafy's courses and enroll all students
INSERT INTO "StudentCourseEnrollment" ("StudentId", "LectureOfferingId")
SELECT 
    s."StudentId",
    lco."LectureOfferingId"
FROM "Student" s
CROSS JOIN "LectureCourseOffering" lco
WHERE lco."FacultyId" = 'FAC-001'
AND s."StudentId" IN ('student-001', 'student-002', 'student-003', 'student-004', 'student-005')
ON CONFLICT ("StudentId", "LectureOfferingId") DO NOTHING;

-- ============================================
-- STEP 5: Enroll in TA Sections (if any exist)
-- ============================================

INSERT INTO "StudentSection" ("StudentId", "SectionOfferingId")
SELECT 
    s."StudentId",
    sco."SectionOfferingId"
FROM "Student" s
CROSS JOIN "SectionCourseOffering" sco
WHERE s."StudentId" IN ('student-001', 'student-002', 'student-003', 'student-004', 'student-005')
ON CONFLICT ("StudentId", "SectionOfferingId") DO NOTHING;

-- ============================================
-- STEP 6: Enable Row Level Security
-- ============================================

ALTER TABLE "StudentCourseEnrollment" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "StudentSection" ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 7: Drop Old Policies (if they exist)
-- ============================================

DROP POLICY IF EXISTS "Students can view own enrollments" ON "StudentCourseEnrollment";
DROP POLICY IF EXISTS "Faculty can view their course enrollments" ON "StudentCourseEnrollment";
DROP POLICY IF EXISTS "Faculty can manage enrollments" ON "StudentCourseEnrollment";
DROP POLICY IF EXISTS "TAs can view their section enrollments" ON "StudentSection";
DROP POLICY IF EXISTS "TAs can manage enrollments" ON "StudentSection";

-- ============================================
-- STEP 8: Create Security Policies
-- ============================================

-- Students can view their own enrollments
CREATE POLICY "Students can view own enrollments"
ON "StudentCourseEnrollment"
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM "Student"
        WHERE "Student"."StudentId" = "StudentCourseEnrollment"."StudentId"
        AND "Student"."UserId" = auth.uid()
    )
);

-- Faculty can manage all aspects of their course enrollments
CREATE POLICY "Faculty can manage enrollments"
ON "StudentCourseEnrollment"
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM "Faculty" f
        JOIN "LectureCourseOffering" lco ON f."FacultyId" = lco."FacultyId"
        WHERE f."UserId" = auth.uid()
        AND lco."LectureOfferingId" = "StudentCourseEnrollment"."LectureOfferingId"
    )
);

-- TAs can manage their section enrollments
CREATE POLICY "TAs can manage enrollments"
ON "StudentSection"
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM "TeacherAssistant" ta
        JOIN "SectionCourseOffering" sco ON ta."TAId" = sco."TAId"
        WHERE ta."UserId" = auth.uid()
        AND sco."SectionOfferingId" = "StudentSection"."SectionOfferingId"
    )
);

-- ============================================
-- STEP 9: Create Indexes for Performance
-- ============================================

CREATE INDEX IF NOT EXISTS idx_student_course_enrollment_student 
ON "StudentCourseEnrollment"("StudentId");

CREATE INDEX IF NOT EXISTS idx_student_course_enrollment_lecture 
ON "StudentCourseEnrollment"("LectureOfferingId");

CREATE INDEX IF NOT EXISTS idx_student_section_student 
ON "StudentSection"("StudentId");

CREATE INDEX IF NOT EXISTS idx_student_section_section 
ON "StudentSection"("SectionOfferingId");

-- ============================================
-- STEP 10: Verification
-- ============================================

-- Check tables created
SELECT 
    'Tables Created' as status,
    COUNT(*) as count
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('StudentCourseEnrollment', 'StudentSection');

-- Count enrollments
SELECT 
    'StudentCourseEnrollment Records' as table_name,
    COUNT(*) as total_records
FROM "StudentCourseEnrollment"
UNION ALL
SELECT 
    'StudentSection Records' as table_name,
    COUNT(*) as total_records
FROM "StudentSection";

-- Show enrolled students for Dr. Hanafy
SELECT 
    'Dr. Hanafy Enrollments' as info,
    COUNT(DISTINCT sce."StudentId") as total_students,
    COUNT(DISTINCT sce."LectureOfferingId") as total_courses,
    COUNT(*) as total_enrollments
FROM "StudentCourseEnrollment" sce
JOIN "LectureCourseOffering" lco ON sce."LectureOfferingId" = lco."LectureOfferingId"
WHERE lco."FacultyId" = 'FAC-001';

-- List students with their enrollments
SELECT 
    s."StudentCode",
    u."FullName" as student_name,
    c."Code" as course_code,
    c."Title" as course_title
FROM "StudentCourseEnrollment" sce
JOIN "Student" s ON sce."StudentId" = s."StudentId"
JOIN "User" u ON s."UserId" = u."UserId"
JOIN "LectureCourseOffering" lco ON sce."LectureOfferingId" = lco."LectureOfferingId"
JOIN "Course" c ON lco."CourseId" = c."CourseId"
WHERE lco."FacultyId" = 'FAC-001'
ORDER BY c."Code", s."StudentCode"
LIMIT 25;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ QUICK FIX COMPLETED SUCCESSFULLY!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'What was fixed:';
    RAISE NOTICE '  ✅ StudentCourseEnrollment table created';
    RAISE NOTICE '  ✅ StudentSection table created';
    RAISE NOTICE '  ✅ 5 test students created';
    RAISE NOTICE '  ✅ Students enrolled in courses';
    RAISE NOTICE '  ✅ Security policies applied';
    RAISE NOTICE '';
    RAISE NOTICE 'Next step:';
    RAISE NOTICE '  Press R in your terminal to hot restart';
    RAISE NOTICE '  Or press q and run: flutter run';
    RAISE NOTICE '========================================';
END $$;

