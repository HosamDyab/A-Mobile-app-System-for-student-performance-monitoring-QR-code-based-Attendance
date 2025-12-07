-- ============================================
-- SIMPLE STUDENT SEARCH FIX - Works with Existing Schema
-- ============================================
-- This version uses only the columns that exist in your database

-- ============================================
-- STEP 1: Create Enrollment Table (if missing)
-- ============================================

CREATE TABLE IF NOT EXISTS "LectureStudentEnrollment" (
    "EnrollmentId" TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "StudentId" TEXT NOT NULL,
    "LectureOfferingId" TEXT NOT NULL,
    "EnrollmentDate" TIMESTAMPTZ DEFAULT NOW(),
    "EnrollmentStatus" TEXT DEFAULT 'Enrolled',
    "CreatedAt" TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_student_lecture UNIQUE ("StudentId", "LectureOfferingId")
);

CREATE INDEX IF NOT EXISTS idx_lecture_enrollment_student 
    ON "LectureStudentEnrollment"("StudentId");
CREATE INDEX IF NOT EXISTS idx_lecture_enrollment_offering 
    ON "LectureStudentEnrollment"("LectureOfferingId");

-- ============================================
-- STEP 2: Create Test Students (Simple Version)
-- ============================================

-- Get a valid DepartmentId (use existing one)
DO $$
DECLARE
    v_dept_id TEXT;
BEGIN
    -- Get first available department
    SELECT "DepartmentId" INTO v_dept_id
    FROM "Department"
    LIMIT 1;
    
    -- If no department exists, create a default one
    IF v_dept_id IS NULL THEN
        INSERT INTO "Department" ("DepartmentId", "Code", "FullName")
        VALUES ('DEPT-CS', 'CS', 'Computer Science')
        ON CONFLICT DO NOTHING;
        v_dept_id := 'DEPT-CS';
    END IF;

    -- Insert test users with PasswordHash and DepartmentId
    INSERT INTO "User" ("UserId", "Email", "PasswordHash", "FullName", "Role", "DepartmentId")
    VALUES 
        ('user-stu-001', 'ahmed.student@mti.edu.eg', '$2a$10$dummyhashdummyhashdummyhashdummyhashdummyhash', 'Ahmed Mohamed Ali', 'Student', v_dept_id),
        ('user-stu-002', 'fatima.student@mti.edu.eg', '$2a$10$dummyhashdummyhashdummyhashdummyhashdummyhash', 'Fatima Al-Kaabi', 'Student', v_dept_id),
        ('user-stu-003', 'sara.student@mti.edu.eg', '$2a$10$dummyhashdummyhashdummyhashdummyhashdummyhash', 'Sara Ahmed Hassan', 'Student', v_dept_id),
        ('user-stu-004', 'mohamed.student@mti.edu.eg', '$2a$10$dummyhashdummyhashdummyhashdummyhashdummyhash', 'Mohamed Ibrahim', 'Student', v_dept_id),
        ('user-stu-005', 'nour.student@mti.edu.eg', '$2a$10$dummyhashdummyhashdummyhashdummyhashdummyhash', 'Nour Ali Hussein', 'Student', v_dept_id),
        ('user-stu-006', 'omar.student@mti.edu.eg', '$2a$10$dummyhashdummyhashdummyhashdummyhash', 'Omar Abdullah', 'Student', v_dept_id),
        ('user-stu-007', 'layla.student@mti.edu.eg', '$2a$10$dummyhashdummyhashdummyhashdummyhash', 'Layla Mahmoud', 'Student', v_dept_id),
        ('user-stu-008', 'youssef.student@mti.edu.eg', '$2a$10$dummyhashdummyhashdummyhashdummyhash', 'Youssef Khaled', 'Student', v_dept_id),
        ('user-stu-009', 'amira.student@mti.edu.eg', '$2a$10$dummyhashdummyhashdummyhashdummyhash', 'Amira Hassan', 'Student', v_dept_id),
        ('user-stu-010', 'karim.student@mti.edu.eg', '$2a$10$dummyhashdummyhashdummyhashdummyhash', 'Karim Saeed', 'Student', v_dept_id)
    ON CONFLICT ("Email") DO NOTHING;
END $$;

-- Insert students (using only basic columns that exist)
INSERT INTO "Student" ("StudentId", "UserId", "StudentCode", "Level")
VALUES 
    ('student-001', 'user-stu-001', '200101', 'L2'),
    ('student-002', 'user-stu-002', '200102', 'L2'),
    ('student-003', 'user-stu-003', '200103', 'L2'),
    ('student-004', 'user-stu-004', '200104', 'L3'),
    ('student-005', 'user-stu-005', '200105', 'L3'),
    ('student-006', 'user-stu-006', '200106', 'L3'),
    ('student-007', 'user-stu-007', '200107', 'L4'),
    ('student-008', 'user-stu-008', '200108', 'L4'),
    ('student-009', 'user-stu-009', '200109', 'L1'),
    ('student-010', 'user-stu-010', '200110', 'L1')
ON CONFLICT ("StudentId") DO NOTHING;

-- ============================================
-- STEP 3: Enroll Students in Dr. Hanafy's Courses
-- ============================================

-- Enroll all students in all active courses for Dr. Hanafy
INSERT INTO "LectureStudentEnrollment" ("StudentId", "LectureOfferingId", "EnrollmentStatus")
SELECT 
    s."StudentId",
    lco."LectureOfferingId",
    'Enrolled'
FROM "Student" s
CROSS JOIN "LectureCourseOffering" lco
WHERE lco."FacultyId" = 'FAC-001'
  AND lco."IsActive" = TRUE
  AND s."StudentId" IN (
    'student-001', 'student-002', 'student-003', 'student-004', 'student-005',
    'student-006', 'student-007', 'student-008', 'student-009', 'student-010'
  )
ON CONFLICT ("StudentId", "LectureOfferingId") 
DO UPDATE SET "EnrollmentStatus" = 'Enrolled';

-- ============================================
-- STEP 4: Create Student Count Function
-- ============================================

CREATE OR REPLACE FUNCTION get_faculty_student_count(faculty_id_param TEXT)
RETURNS INTEGER AS $$
DECLARE
    student_count INTEGER;
BEGIN
    SELECT COUNT(DISTINCT lse."StudentId")
    INTO student_count
    FROM "LectureCourseOffering" lco
    LEFT JOIN "LectureStudentEnrollment" lse 
        ON lco."LectureOfferingId" = lse."LectureOfferingId"
    WHERE lco."FacultyId" = faculty_id_param
      AND lco."IsActive" = TRUE
      AND (lse."EnrollmentStatus" = 'Enrolled' OR lse."EnrollmentStatus" IS NULL);
    
    RETURN COALESCE(student_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_faculty_student_count TO authenticated;
GRANT EXECUTE ON FUNCTION get_faculty_student_count TO anon;

-- ============================================
-- STEP 5: Create Get Students Function
-- ============================================

CREATE OR REPLACE FUNCTION get_faculty_students(faculty_id_param TEXT)
RETURNS TABLE (
    "StudentId" TEXT,
    "StudentCode" TEXT,
    "FullName" TEXT,
    "Email" TEXT,
    "Level" TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        s."StudentId",
        s."StudentCode",
        u."FullName",
        u."Email",
        s."Level"
    FROM "Student" s
    INNER JOIN "User" u ON s."UserId" = u."UserId"
    INNER JOIN "LectureStudentEnrollment" lse ON s."StudentId" = lse."StudentId"
    INNER JOIN "LectureCourseOffering" lco ON lse."LectureOfferingId" = lco."LectureOfferingId"
    WHERE lco."FacultyId" = faculty_id_param
      AND lco."IsActive" = TRUE
      AND lse."EnrollmentStatus" = 'Enrolled'
    ORDER BY s."StudentCode";
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_faculty_students TO authenticated;
GRANT EXECUTE ON FUNCTION get_faculty_students TO anon;

-- ============================================
-- STEP 6: Enable Row Level Security
-- ============================================

ALTER TABLE "LectureStudentEnrollment" ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist
DROP POLICY IF EXISTS "Students can view own enrollments" ON "LectureStudentEnrollment";
DROP POLICY IF EXISTS "Faculty can manage enrollments" ON "LectureStudentEnrollment";

-- Create policies
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

-- ============================================
-- STEP 7: Verification
-- ============================================

-- Count students
SELECT 
    'Total Students Created' as info,
    COUNT(*) as count
FROM "Student"
WHERE "StudentId" LIKE 'student-%';

-- Count enrollments
SELECT 
    'Total Enrollments' as info,
    COUNT(*) as count
FROM "LectureStudentEnrollment";

-- Test faculty student count
SELECT 
    'Dr. Hanafy Students' as info,
    get_faculty_student_count('FAC-001') as count;

-- List enrolled students
SELECT 
    s."StudentCode",
    u."FullName",
    s."Level",
    COUNT(lse."LectureOfferingId") as courses_enrolled
FROM "Student" s
JOIN "User" u ON s."UserId" = u."UserId"
JOIN "LectureStudentEnrollment" lse ON s."StudentId" = lse."StudentId"
JOIN "LectureCourseOffering" lco ON lse."LectureOfferingId" = lco."LectureOfferingId"
WHERE lco."FacultyId" = 'FAC-001'
  AND s."StudentId" LIKE 'student-%'
GROUP BY s."StudentCode", u."FullName", s."Level"
ORDER BY s."StudentCode"
LIMIT 10;

-- Success message
DO $$
DECLARE
    total_students INT;
    faculty_students INT;
BEGIN
    SELECT COUNT(*) INTO total_students 
    FROM "Student" WHERE "StudentId" LIKE 'student-%';
    
    SELECT get_faculty_student_count('FAC-001') INTO faculty_students;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ STUDENT SEARCH FIX COMPLETED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Summary:';
    RAISE NOTICE '  📊 Test Students Created: %', total_students;
    RAISE NOTICE '  👨‍🏫 Dr. Hanafy Students: %', faculty_students;
    RAISE NOTICE '';
    RAISE NOTICE 'Tables:';
    RAISE NOTICE '  ✅ LectureStudentEnrollment';
    RAISE NOTICE '';
    RAISE NOTICE 'Functions:';
    RAISE NOTICE '  ✅ get_faculty_student_count()';
    RAISE NOTICE '  ✅ get_faculty_students()';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Press R in Flutter terminal';
    RAISE NOTICE '  2. Go to Students tab';
    RAISE NOTICE '  3. Students should load!';
    RAISE NOTICE '========================================';
END $$;

