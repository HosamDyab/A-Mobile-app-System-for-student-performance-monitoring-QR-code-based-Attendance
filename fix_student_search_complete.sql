-- ============================================
-- FIX STUDENT SEARCH - COMPLETE SOLUTION
-- ============================================
-- This script ensures all tables exist and students are properly enrolled
-- Run this in Supabase SQL Editor

-- ============================================
-- STEP 1: Create Missing Tables (if they don't exist)
-- ============================================

-- LectureStudentEnrollment (if missing)
CREATE TABLE IF NOT EXISTS "LectureStudentEnrollment" (
    "EnrollmentId" TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "StudentId" TEXT NOT NULL,
    "LectureOfferingId" TEXT NOT NULL,
    "EnrollmentDate" TIMESTAMPTZ DEFAULT NOW(),
    "EnrollmentStatus" TEXT DEFAULT 'Enrolled',
    "DropDate" TIMESTAMPTZ,
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_student_lecture UNIQUE ("StudentId", "LectureOfferingId"),
    CONSTRAINT fk_enrollment_student 
        FOREIGN KEY ("StudentId") REFERENCES "Student"("StudentId") ON DELETE CASCADE,
    CONSTRAINT fk_enrollment_lecture 
        FOREIGN KEY ("LectureOfferingId") REFERENCES "LectureCourseOffering"("LectureOfferingId") ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_lecture_enrollment_student 
    ON "LectureStudentEnrollment"("StudentId");
CREATE INDEX IF NOT EXISTS idx_lecture_enrollment_offering 
    ON "LectureStudentEnrollment"("LectureOfferingId");
CREATE INDEX IF NOT EXISTS idx_lecture_enrollment_status 
    ON "LectureStudentEnrollment"("EnrollmentStatus");

-- ============================================
-- STEP 2: Ensure StudentSection Table Exists
-- ============================================

CREATE TABLE IF NOT EXISTS "StudentSection" (
    "EnrollmentId" TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "StudentId" TEXT NOT NULL,
    "SectionOfferingId" TEXT NOT NULL,
    "EnrollmentDate" TIMESTAMPTZ DEFAULT NOW(),
    "EnrollmentStatus" TEXT DEFAULT 'Enrolled',
    "DropDate" TIMESTAMPTZ,
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
    "UpdatedAt" TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_student_section UNIQUE ("StudentId", "SectionOfferingId"),
    CONSTRAINT fk_section_enrollment_student 
        FOREIGN KEY ("StudentId") REFERENCES "Student"("StudentId") ON DELETE CASCADE,
    CONSTRAINT fk_section_enrollment_section 
        FOREIGN KEY ("SectionOfferingId") REFERENCES "SectionCourseOffering"("SectionOfferingId") ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_section_enrollment_student 
    ON "StudentSection"("StudentId");
CREATE INDEX IF NOT EXISTS idx_section_enrollment_offering 
    ON "StudentSection"("SectionOfferingId");

-- ============================================
-- STEP 3: Create Test Students (if not exist)
-- ============================================

-- Insert test student users
INSERT INTO "User" ("UserId", "Email", "PasswordHash", "FullName", "Role", "DepartmentId", "IsActive")
SELECT 
    'user-stu-' || i::text,
    'student' || i::text || '@mti.edu.eg',
    '$2a$10$abcdefghijklmnopqrstuvwxyz12345',  -- Dummy hash
    CASE i
        WHEN 1 THEN 'Ahmed Mohamed Ali'
        WHEN 2 THEN 'Fatima Al-Kaabi'
        WHEN 3 THEN 'Sara Ahmed Hassan'
        WHEN 4 THEN 'Mohamed Ibrahim'
        WHEN 5 THEN 'Nour Ali Hussein'
        WHEN 6 THEN 'Omar Abdullah'
        WHEN 7 THEN 'Layla Mahmoud'
        WHEN 8 THEN 'Youssef Khaled'
        WHEN 9 THEN 'Amira Hassan'
        WHEN 10 THEN 'Karim Saeed'
    END,
    'Student',
    (SELECT "DepartmentId" FROM "Department" LIMIT 1),
    TRUE
FROM generate_series(1, 10) i
ON CONFLICT ("Email") DO NOTHING;

-- Insert student records
INSERT INTO "Student" (
    "StudentId", 
    "UserId", 
    "StudentCode", 
    "Major", 
    "CurrentGPA", 
    "AcademicLevel", 
    "EnrollmentYear", 
    "CurrentAcademicYear", 
    "CurrentSemester",
    "Status"
)
SELECT 
    'student-' || LPAD(i::text, 3, '0'),
    'user-stu-' || i::text,
    '20' || LPAD((100 + i)::text, 4, '0'),
    CASE (i % 3)
        WHEN 0 THEN 'CS'
        WHEN 1 THEN 'IS'
        ELSE 'AI'
    END,
    2.5 + (i * 0.15),
    CASE (i % 4)
        WHEN 0 THEN 'L1'
        WHEN 1 THEN 'L2'
        WHEN 2 THEN 'L3'
        ELSE 'L4'
    END,
    2023,
    2024,
    'Fall',
    'Active'
FROM generate_series(1, 10) i
ON CONFLICT ("StudentId") DO NOTHING;

-- ============================================
-- STEP 4: Enroll Students in Dr. Hanafy's Courses
-- ============================================

-- Enroll all test students in all of Dr. Hanafy's lecture offerings
INSERT INTO "LectureStudentEnrollment" ("StudentId", "LectureOfferingId", "EnrollmentStatus")
SELECT 
    s."StudentId",
    lco."LectureOfferingId",
    'Enrolled'
FROM "Student" s
CROSS JOIN "LectureCourseOffering" lco
WHERE lco."FacultyId" = 'FAC-001'
  AND lco."IsActive" = TRUE
  AND s."StudentId" LIKE 'student-%'
ON CONFLICT ("StudentId", "LectureOfferingId") DO UPDATE
SET "EnrollmentStatus" = 'Enrolled';

-- Also enroll in sections (if they exist)
INSERT INTO "StudentSection" ("StudentId", "SectionOfferingId", "EnrollmentStatus")
SELECT 
    s."StudentId",
    sco."SectionOfferingId",
    'Enrolled'
FROM "Student" s
CROSS JOIN "SectionCourseOffering" sco
INNER JOIN "LectureCourseOffering" lco ON sco."LectureOfferingId" = lco."LectureOfferingId"
WHERE lco."FacultyId" = 'FAC-001'
  AND sco."IsActive" = TRUE
  AND s."StudentId" LIKE 'student-%'
ON CONFLICT ("StudentId", "SectionOfferingId") DO UPDATE
SET "EnrollmentStatus" = 'Enrolled';

-- ============================================
-- STEP 5: Create get_faculty_student_count Function
-- ============================================

CREATE OR REPLACE FUNCTION get_faculty_student_count(faculty_id_param TEXT)
RETURNS INTEGER AS $$
DECLARE
    student_count INTEGER;
BEGIN
    -- Count distinct students enrolled in this faculty's courses
    SELECT COUNT(DISTINCT lse."StudentId")
    INTO student_count
    FROM "LectureCourseOffering" lco
    LEFT JOIN "LectureStudentEnrollment" lse 
        ON lco."LectureOfferingId" = lse."LectureOfferingId"
    WHERE lco."FacultyId" = faculty_id_param
      AND lco."IsActive" = TRUE
      AND lse."EnrollmentStatus" = 'Enrolled';
    
    RETURN COALESCE(student_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_faculty_student_count TO authenticated;
GRANT EXECUTE ON FUNCTION get_faculty_student_count TO anon;

-- ============================================
-- STEP 6: Create Helper Function to Get Students by Faculty
-- ============================================

CREATE OR REPLACE FUNCTION get_faculty_students(faculty_id_param TEXT)
RETURNS TABLE (
    "StudentId" TEXT,
    "StudentCode" TEXT,
    "FullName" TEXT,
    "Email" TEXT,
    "AcademicLevel" academic_level,
    "Major" major_type,
    "CurrentGPA" NUMERIC,
    "Status" student_status
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        s."StudentId",
        s."StudentCode",
        u."FullName",
        u."Email",
        s."AcademicLevel",
        s."Major",
        s."CurrentGPA",
        s."Status"
    FROM "Student" s
    INNER JOIN "User" u ON s."UserId" = u."UserId"
    INNER JOIN "LectureStudentEnrollment" lse ON s."StudentId" = lse."StudentId"
    INNER JOIN "LectureCourseOffering" lco ON lse."LectureOfferingId" = lco."LectureOfferingId"
    WHERE lco."FacultyId" = faculty_id_param
      AND lco."IsActive" = TRUE
      AND lse."EnrollmentStatus" = 'Enrolled'
      AND s."Status" = 'Active'
    ORDER BY s."StudentCode";
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_faculty_students TO authenticated;
GRANT EXECUTE ON FUNCTION get_faculty_students TO anon;

-- ============================================
-- STEP 7: Enable Row Level Security
-- ============================================

ALTER TABLE "LectureStudentEnrollment" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "StudentSection" ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Students can view own enrollments" ON "LectureStudentEnrollment";
DROP POLICY IF EXISTS "Faculty can view their enrollments" ON "LectureStudentEnrollment";
DROP POLICY IF EXISTS "Faculty can manage enrollments" ON "LectureStudentEnrollment";
DROP POLICY IF EXISTS "TAs can view section enrollments" ON "StudentSection";
DROP POLICY IF EXISTS "TAs can manage section enrollments" ON "StudentSection";

-- Create new policies
CREATE POLICY "Students can view own enrollments"
ON "LectureStudentEnrollment"
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM "Student"
        WHERE "Student"."StudentId" = "LectureStudentEnrollment"."StudentId"
        AND "Student"."UserId" = auth.uid()::TEXT
    )
);

CREATE POLICY "Faculty can manage enrollments"
ON "LectureStudentEnrollment"
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM "Faculty" f
        JOIN "LectureCourseOffering" lco ON f."FacultyId" = lco."FacultyId"
        WHERE f."UserId" = auth.uid()::TEXT
        AND lco."LectureOfferingId" = "LectureStudentEnrollment"."LectureOfferingId"
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM "Faculty" f
        JOIN "LectureCourseOffering" lco ON f."FacultyId" = lco."FacultyId"
        WHERE f."UserId" = auth.uid()::TEXT
        AND lco."LectureOfferingId" = "LectureStudentEnrollment"."LectureOfferingId"
    )
);

CREATE POLICY "TAs can manage section enrollments"
ON "StudentSection"
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM "TeacherAssistant" ta
        JOIN "SectionCourseOffering" sco ON ta."TAId" = sco."TAId"
        WHERE ta."UserId" = auth.uid()::TEXT
        AND sco."SectionOfferingId" = "StudentSection"."SectionOfferingId"
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM "TeacherAssistant" ta
        JOIN "SectionCourseOffering" sco ON ta."TAId" = sco."TAId"
        WHERE ta."UserId" = auth.uid()::TEXT
        AND sco."SectionOfferingId" = "StudentSection"."SectionOfferingId"
    )
);

-- ============================================
-- STEP 8: Verification Queries
-- ============================================

-- Count total students
SELECT 
    'Total Students' as metric,
    COUNT(*) as count
FROM "Student";

-- Count enrollments for Dr. Hanafy
SELECT 
    'Dr. Hanafy Students' as metric,
    get_faculty_student_count('FAC-001') as count;

-- Show enrolled students
SELECT 
    s."StudentCode",
    u."FullName",
    s."AcademicLevel",
    s."Major",
    COUNT(DISTINCT lse."LectureOfferingId") as enrolled_courses
FROM "Student" s
JOIN "User" u ON s."UserId" = u."UserId"
JOIN "LectureStudentEnrollment" lse ON s."StudentId" = lse."StudentId"
JOIN "LectureCourseOffering" lco ON lse."LectureOfferingId" = lco."LectureOfferingId"
WHERE lco."FacultyId" = 'FAC-001'
GROUP BY s."StudentCode", u."FullName", s."AcademicLevel", s."Major"
ORDER BY s."StudentCode"
LIMIT 10;

-- Success message
DO $$
DECLARE
    total_students INT;
    faculty_students INT;
BEGIN
    SELECT COUNT(*) INTO total_students FROM "Student";
    SELECT get_faculty_student_count('FAC-001') INTO faculty_students;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ STUDENT SEARCH FIX COMPLETED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Summary:';
    RAISE NOTICE '  📊 Total Students: %', total_students;
    RAISE NOTICE '  👨‍🏫 Dr. Hanafy Students: %', faculty_students;
    RAISE NOTICE '';
    RAISE NOTICE 'Tables Created/Verified:';
    RAISE NOTICE '  ✅ LectureStudentEnrollment';
    RAISE NOTICE '  ✅ StudentSection';
    RAISE NOTICE '';
    RAISE NOTICE 'Functions Created:';
    RAISE NOTICE '  ✅ get_faculty_student_count()';
    RAISE NOTICE '  ✅ get_faculty_students()';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Press R in Flutter terminal (Hot Restart)';
    RAISE NOTICE '  2. Go to Students tab';
    RAISE NOTICE '  3. Students should now load!';
    RAISE NOTICE '========================================';
END $$;

