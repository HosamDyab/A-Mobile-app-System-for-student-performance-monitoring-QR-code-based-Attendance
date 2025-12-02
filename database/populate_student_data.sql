-- =====================================================
-- POPULATE STUDENT DATA - Hosam (100308)
-- This will add courses, enrollments, and grades
-- =====================================================

-- First, verify the student exists
SELECT 
    s."StudentId",
    u."FullName",
    u."Email"
FROM "Student" s
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg';

-- =====================================================
-- 1. CREATE COURSES (If they don't exist)
-- =====================================================

-- Software Engineering II
INSERT INTO "Course" ("Code", "Title", "Credits", "Description", "CourseLevel", "Category", "IsMandatory")
VALUES ('CS411', 'Software Engineering II', 3, 'Advanced software engineering', 'Level 4', 'Core', true)
ON CONFLICT ("Code") DO NOTHING;

-- Computer Graphics
INSERT INTO "Course" ("Code", "Title", "Credits", "Description", "CourseLevel", "Category", "IsMandatory")
VALUES ('CS412', 'Computer Graphics', 3, 'Computer graphics fundamentals', 'Level 4', 'Core', true)
ON CONFLICT ("Code") DO NOTHING;

-- Microsystems
INSERT INTO "Course" ("Code", "Title", "Credits", "Description", "CourseLevel", "Category", "IsMandatory")
VALUES ('CS413', 'Microsystems', 3, 'Microprocessor systems', 'Level 4', 'Core', true)
ON CONFLICT ("Code") DO NOTHING;

-- Digital Signal Processing
INSERT INTO "Course" ("Code", "Title", "Credits", "Description", "CourseLevel", "Category", "IsMandatory")
VALUES ('CS414', 'Digital Signal Processing', 3, 'Signal processing techniques', 'Level 4', 'Core', true)
ON CONFLICT ("Code") DO NOTHING;

-- Assembly Language
INSERT INTO "Course" ("Code", "Title", "Credits", "Description", "CourseLevel", "Category", "IsMandatory")
VALUES ('CS415', 'Assembly Language', 3, 'Low-level programming', 'Level 4', 'Core', true)
ON CONFLICT ("Code") DO NOTHING;

-- =====================================================
-- 2. CREATE LECTURE OFFERINGS
-- =====================================================

-- Get or create faculty for Dr. Hanafy
INSERT INTO "LectureCourseOffering" ("CourseId", "FacultyId", "AcademicYear", "Semester", "LectureSchedule")
SELECT 
    c."CourseId",
    (SELECT "FacultyId" FROM "Faculty" f INNER JOIN "User" u ON f."UserId" = u."UserId" WHERE u."Email" = 'drhanafy@cs.mti.edu.eg' LIMIT 1),
    2024,
    'Fall',
    'Sunday 10:00-12:00'
FROM "Course" c
WHERE c."Code" IN ('CS411', 'CS412', 'CS413', 'CS414', 'CS415')
ON CONFLICT DO NOTHING;

-- =====================================================
-- 3. CREATE SECTION OFFERINGS
-- =====================================================

INSERT INTO "SectionCourseOffering" (
    "LectureOfferingId",
    "SectionNumber",
    "AcademicYear",
    "Semester",
    "MaxCapacity",
    "CurrentEnrollment"
)
SELECT 
    lco."LectureOfferingId",
    1,
    2024,
    'Fall',
    50,
    1
FROM "LectureCourseOffering" lco
INNER JOIN "Course" c ON lco."CourseId" = c."CourseId"
WHERE c."Code" IN ('CS411', 'CS412', 'CS413', 'CS414', 'CS415')
  AND lco."AcademicYear" = 2024
  AND lco."Semester" = 'Fall'
ON CONFLICT DO NOTHING;

-- =====================================================
-- 4. ENROLL STUDENT IN COURSES
-- =====================================================

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
INNER JOIN "LectureCourseOffering" lco ON sco."LectureOfferingId" = lco."LectureOfferingId"
INNER JOIN "Course" c ON lco."CourseId" = c."CourseId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
  AND c."Code" IN ('CS411', 'CS412', 'CS413', 'CS414', 'CS415')
  AND sco."AcademicYear" = 2024
  AND sco."Semester" = 'Fall'
ON CONFLICT DO NOTHING;

-- =====================================================
-- 5. ADD GRADES (Midterm Scores)
-- =====================================================

-- Software Engineering II - Midterm: 18
INSERT INTO "SectionGrade" ("StudentSectionId", "MidtermExam", "Total", "LetterGrade")
SELECT 
    ss."StudentSectionId",
    18,
    72,
    'B+'
FROM "StudentSection" ss
INNER JOIN "SectionCourseOffering" sco ON ss."SectionCourseOfferingId" = sco."SectionCourseOfferingId"
INNER JOIN "LectureCourseOffering" lco ON sco."LectureOfferingId" = lco."LectureOfferingId"
INNER JOIN "Course" c ON lco."CourseId" = c."CourseId"
INNER JOIN "Student" s ON ss."StudentId" = s."StudentId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
  AND c."Code" = 'CS411'
ON CONFLICT ("StudentSectionId") DO UPDATE SET "MidtermExam" = 18, "Total" = 72, "LetterGrade" = 'B+';

-- Computer Graphics - Midterm: 12
INSERT INTO "SectionGrade" ("StudentSectionId", "MidtermExam", "Total", "LetterGrade")
SELECT 
    ss."StudentSectionId",
    12,
    48,
    'F'
FROM "StudentSection" ss
INNER JOIN "SectionCourseOffering" sco ON ss."SectionCourseOfferingId" = sco."SectionCourseOfferingId"
INNER JOIN "LectureCourseOffering" lco ON sco."LectureOfferingId" = lco."LectureOfferingId"
INNER JOIN "Course" c ON lco."CourseId" = c."CourseId"
INNER JOIN "Student" s ON ss."StudentId" = s."StudentId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
  AND c."Code" = 'CS412'
ON CONFLICT ("StudentSectionId") DO UPDATE SET "MidtermExam" = 12, "Total" = 48, "LetterGrade" = 'F';

-- Microsystems - Midterm: 20
INSERT INTO "SectionGrade" ("StudentSectionId", "MidtermExam", "Total", "LetterGrade")
SELECT 
    ss."StudentSectionId",
    20,
    80,
    'A-'
FROM "StudentSection" ss
INNER JOIN "SectionCourseOffering" sco ON ss."SectionCourseOfferingId" = sco."SectionCourseOfferingId"
INNER JOIN "LectureCourseOffering" lco ON sco."LectureOfferingId" = lco."LectureOfferingId"
INNER JOIN "Course" c ON lco."CourseId" = c."CourseId"
INNER JOIN "Student" s ON ss."StudentId" = s."StudentId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
  AND c."Code" = 'CS413'
ON CONFLICT ("StudentSectionId") DO UPDATE SET "MidtermExam" = 20, "Total" = 80, "LetterGrade" = 'A-';

-- Digital Signal Processing - Midterm: 18
INSERT INTO "SectionGrade" ("StudentSectionId", "MidtermExam", "Total", "LetterGrade")
SELECT 
    ss."StudentSectionId",
    18,
    72,
    'B+'
FROM "StudentSection" ss
INNER JOIN "SectionCourseOffering" sco ON ss."SectionCourseOfferingId" = sco."SectionCourseOfferingId"
INNER JOIN "LectureCourseOffering" lco ON sco."LectureOfferingId" = lco."LectureOfferingId"
INNER JOIN "Course" c ON lco."CourseId" = c."CourseId"
INNER JOIN "Student" s ON ss."StudentId" = s."StudentId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
  AND c."Code" = 'CS414'
ON CONFLICT ("StudentSectionId") DO UPDATE SET "MidtermExam" = 18, "Total" = 72, "LetterGrade" = 'B+';

-- Assembly Language - Midterm: 20
INSERT INTO "SectionGrade" ("StudentSectionId", "MidtermExam", "Total", "LetterGrade")
SELECT 
    ss."StudentSectionId",
    20,
    80,
    'A-'
FROM "StudentSection" ss
INNER JOIN "SectionCourseOffering" sco ON ss."SectionCourseOfferingId" = sco."SectionCourseOfferingId"
INNER JOIN "LectureCourseOffering" lco ON sco."LectureOfferingId" = lco."LectureOfferingId"
INNER JOIN "Course" c ON lco."CourseId" = c."CourseId"
INNER JOIN "Student" s ON ss."StudentId" = s."StudentId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
  AND c."Code" = 'CS415'
ON CONFLICT ("StudentSectionId") DO UPDATE SET "MidtermExam" = 20, "Total" = 80, "LetterGrade" = 'A-';

-- =====================================================
-- 6. VERIFICATION - Check what was created
-- =====================================================

-- Check student enrollments
SELECT 
    c."Code",
    c."Title",
    sco."Semester",
    sco."AcademicYear",
    sg."MidtermExam",
    sg."Total",
    sg."LetterGrade"
FROM "StudentSection" ss
INNER JOIN "SectionCourseOffering" sco ON ss."SectionCourseOfferingId" = sco."SectionCourseOfferingId"
INNER JOIN "LectureCourseOffering" lco ON sco."LectureOfferingId" = lco."LectureOfferingId"
INNER JOIN "Course" c ON lco."CourseId" = c."CourseId"
LEFT JOIN "SectionGrade" sg ON ss."StudentSectionId" = sg."StudentSectionId"
INNER JOIN "Student" s ON ss."StudentId" = s."StudentId"
INNER JOIN "User" u ON s."UserId" = u."UserId"
WHERE u."Email" = 'hosam.100308@cs.mti.edu.eg'
ORDER BY c."Code";

-- =====================================================
-- Expected Result:
-- CS411 | Software Engineering II     | Fall | 2024 | 18 | 72 | B+
-- CS412 | Computer Graphics           | Fall | 2024 | 12 | 48 | F
-- CS413 | Microsystems                | Fall | 2024 | 20 | 80 | A-
-- CS414 | Digital Signal Processing   | Fall | 2024 | 18 | 72 | B+
-- CS415 | Assembly Language           | Fall | 2024 | 20 | 80 | A-
-- =====================================================



