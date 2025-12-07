-- ============================================
-- MINIMAL STUDENT SEARCH FIX - Works with ANY Schema
-- ============================================
-- This version uses only the absolutely essential columns

-- ============================================
-- STEP 1: Create Enrollment Table
-- ============================================

CREATE TABLE IF NOT EXISTS "LectureStudentEnrollment" (
    "EnrollmentId" TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "StudentId" TEXT NOT NULL,
    "LectureOfferingId" TEXT NOT NULL,
    "EnrollmentDate" TIMESTAMPTZ DEFAULT NOW(),
    "EnrollmentStatus" TEXT DEFAULT 'Enrolled',
    CONSTRAINT unique_student_lecture UNIQUE ("StudentId", "LectureOfferingId")
);

CREATE INDEX IF NOT EXISTS idx_lecture_enrollment_student 
    ON "LectureStudentEnrollment"("StudentId");

-- ============================================
-- STEP 2: Enroll EXISTING Students in Courses
-- ============================================

-- This enrolls any existing students in Dr. Hanafy's courses
INSERT INTO "LectureStudentEnrollment" ("StudentId", "LectureOfferingId", "EnrollmentStatus")
SELECT 
    s."StudentId",
    lco."LectureOfferingId",
    'Enrolled'
FROM "Student" s
CROSS JOIN "LectureCourseOffering" lco
WHERE lco."FacultyId" = 'FAC-001'
  AND lco."IsActive" = TRUE
ON CONFLICT ("StudentId", "LectureOfferingId") 
DO UPDATE SET "EnrollmentStatus" = 'Enrolled';

-- ============================================
-- STEP 3: Create Student Count Function
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
-- STEP 4: Enable Row Level Security
-- ============================================

ALTER TABLE "LectureStudentEnrollment" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Students can view own enrollments" ON "LectureStudentEnrollment";
DROP POLICY IF EXISTS "Faculty can manage enrollments" ON "LectureStudentEnrollment";

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
-- STEP 5: Verification
-- ============================================

-- Count total students
SELECT 
    'Total Students in Database' as info,
    COUNT(*) as count
FROM "Student";

-- Count enrollments created
SELECT 
    'Total Enrollments Created' as info,
    COUNT(*) as count
FROM "LectureStudentEnrollment";

-- Test faculty student count
SELECT 
    'Dr. Hanafy Students' as info,
    get_faculty_student_count('FAC-001') as count;

-- Show sample of enrolled students
SELECT 
    s."StudentCode",
    u."FullName",
    COUNT(lse."LectureOfferingId") as courses_enrolled
FROM "Student" s
JOIN "User" u ON s."UserId" = u."UserId"
JOIN "LectureStudentEnrollment" lse ON s."StudentId" = lse."StudentId"
JOIN "LectureCourseOffering" lco ON lse."LectureOfferingId" = lco."LectureOfferingId"
WHERE lco."FacultyId" = 'FAC-001'
GROUP BY s."StudentCode", u."FullName"
ORDER BY s."StudentCode"
LIMIT 10;

-- Success message
DO $$
DECLARE
    total_students INT;
    faculty_students INT;
    total_enrollments INT;
BEGIN
    SELECT COUNT(*) INTO total_students FROM "Student";
    SELECT get_faculty_student_count('FAC-001') INTO faculty_students;
    SELECT COUNT(*) INTO total_enrollments FROM "LectureStudentEnrollment";
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ STUDENT SEARCH FIX COMPLETED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Summary:';
    RAISE NOTICE '  📊 Total Students in DB: %', total_students;
    RAISE NOTICE '  👨‍🏫 Dr. Hanafy Students: %', faculty_students;
    RAISE NOTICE '  📝 Enrollments Created: %', total_enrollments;
    RAISE NOTICE '';
    RAISE NOTICE 'What was done:';
    RAISE NOTICE '  ✅ Created LectureStudentEnrollment table';
    RAISE NOTICE '  ✅ Enrolled existing students in courses';
    RAISE NOTICE '  ✅ Created get_faculty_student_count() function';
    RAISE NOTICE '  ✅ Set up security policies';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Press R in Flutter terminal (Hot Restart)';
    RAISE NOTICE '  2. Go to Students tab';
    RAISE NOTICE '  3. Should see existing students!';
    RAISE NOTICE '========================================';
END $$;

