-- =====================================================
-- FACULTY TEST DATA - Dr. Hanafy
-- Creates a faculty member with today's lectures for testing
-- =====================================================

-- 1. Create Department (if not exists)
INSERT INTO "Department" ("DepartmentId", "Code", "FullName", "Description")
VALUES ('dept-cs-001', 'CS', 'Computer Science', 'Computer Science Department')
ON CONFLICT ("Code") DO NOTHING;

-- 2. Create Faculty User
INSERT INTO "User" (
    "UserId", "Email", "PasswordHash", "FullName", "Role", 
    "DepartmentId", "Phone", "IsActive"
)
VALUES (
    'user-faculty-001', 
    'drhanafy@cs.mti.edu.eg', 
    'password123',  -- Plain password (change in production!)
    'Dr. Hanafy Mohamed',
    'Faculty',
    'dept-cs-001',
    '+201234567890',
    TRUE
)
ON CONFLICT ("Email") DO UPDATE SET
    "PasswordHash" = EXCLUDED."PasswordHash",
    "IsActive" = TRUE;

-- 3. Create Faculty Record
INSERT INTO "Faculty" (
    "FacultyId", "UserId", "EmployeeCode", "AcademicTitle", 
    "Specialization", "HireDate", "ExperienceYears"
)
VALUES (
    'faculty-001',
    'user-faculty-001',
    'FAC-001',
    'Doctor',
    'Software Engineering',
    '2015-09-01',
    8
)
ON CONFLICT ("UserId") DO UPDATE SET
    "AcademicTitle" = EXCLUDED."AcademicTitle",
    "Specialization" = EXCLUDED."Specialization";

-- 4. Create Courses
INSERT INTO "Course" ("CourseId", "Code", "Title", "Description", "Credits", "DepartmentId", "CourseLevel", "Category")
VALUES 
    ('course-cs411', 'CS411', 'Software Engineering II', 'Advanced software engineering concepts', 3.0, 'dept-cs-001', 'L4', 'CoreRequirement'),
    ('course-cs412', 'CS412', 'Database Systems', 'Advanced database design and implementation', 3.0, 'dept-cs-001', 'L4', 'CoreRequirement'),
    ('course-cs413', 'CS413', 'Operating Systems', 'OS concepts and implementation', 3.0, 'dept-cs-001', 'L3', 'CoreRequirement')
ON CONFLICT ("Code") DO NOTHING;

-- 5. Get current day name for scheduling
DO $$
DECLARE
    current_day TEXT;
    current_year INTEGER;
BEGIN
    current_day := TO_CHAR(CURRENT_DATE, 'Day');
    current_day := TRIM(current_day);  -- Remove trailing spaces
    current_year := EXTRACT(YEAR FROM CURRENT_DATE);

    -- 6. Create Lecture Offerings for TODAY
    -- Software Engineering II - Today at 8:00-10:00
    INSERT INTO "LectureCourseOffering" (
        "LectureOfferingId", "CourseId", "FacultyId", 
        "AcademicYear", "Semester", "Schedule", "RoomNo", "MaxCapacity"
    )
    VALUES (
        'lect-offer-001',
        'course-cs411',
        'faculty-001',
        current_year,
        'Fall',
        current_day || ' 08:00-10:00',
        'H-101',
        100
    )
    ON CONFLICT ("CourseId", "AcademicYear", "Semester") 
    DO UPDATE SET "Schedule" = EXCLUDED."Schedule";

    -- Database Systems - Today at 10:30-12:30
    INSERT INTO "LectureCourseOffering" (
        "LectureOfferingId", "CourseId", "FacultyId", 
        "AcademicYear", "Semester", "Schedule", "RoomNo", "MaxCapacity"
    )
    VALUES (
        'lect-offer-002',
        'course-cs412',
        'faculty-001',
        current_year,
        'Fall',
        current_day || ' 10:30-12:30',
        'H-102',
        100
    )
    ON CONFLICT ("CourseId", "AcademicYear", "Semester") 
    DO UPDATE SET "Schedule" = EXCLUDED."Schedule";

    -- Operating Systems - Today at 14:00-16:00
    INSERT INTO "LectureCourseOffering" (
        "LectureOfferingId", "CourseId", "FacultyId", 
        "AcademicYear", "Semester", "Schedule", "RoomNo", "MaxCapacity"
    )
    VALUES (
        'lect-offer-003',
        'course-cs413',
        'faculty-001',
        current_year,
        'Fall',
        current_day || ' 14:00-16:00',
        'H-103',
        100
    )
    ON CONFLICT ("CourseId", "AcademicYear", "Semester") 
    DO UPDATE SET "Schedule" = EXCLUDED."Schedule";
END $$;

-- 7. Verification Query
SELECT 
    lco."LectureOfferingId",
    c."Code" AS "CourseCode",
    c."Title" AS "CourseTitle",
    lco."Schedule",
    lco."RoomNo",
    f."AcademicTitle" || ' ' || u."FullName" AS "Instructor"
FROM "LectureCourseOffering" lco
INNER JOIN "Course" c ON lco."CourseId" = c."CourseId"
INNER JOIN "Faculty" f ON lco."FacultyId" = f."FacultyId"
INNER JOIN "User" u ON f."UserId" = u."UserId"
WHERE lco."FacultyId" = 'faculty-001'
  AND lco."Schedule" LIKE '%' || TRIM(TO_CHAR(CURRENT_DATE, 'Day')) || '%'
ORDER BY lco."Schedule";

-- =====================================================
-- Expected Output:
-- Shows 3 lectures for Dr. Hanafy scheduled for TODAY
-- =====================================================


