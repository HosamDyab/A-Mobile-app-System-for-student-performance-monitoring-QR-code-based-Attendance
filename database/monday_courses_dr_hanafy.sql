-- =====================================================
-- DR. HANAFY - MONDAY COURSES ONLY
-- Two courses on Monday with specific times
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
    'Prof. Dr. Hanafy Ismail',
    'Faculty',
    'dept-cs-001',
    '+201234567890',
    TRUE
)
ON CONFLICT ("Email") DO UPDATE SET
    "PasswordHash" = EXCLUDED."PasswordHash",
    "FullName" = EXCLUDED."FullName",
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
    'Professor',
    'Computer Science',
    '2010-09-01',
    14
)
ON CONFLICT ("UserId") DO UPDATE SET
    "AcademicTitle" = EXCLUDED."AcademicTitle",
    "Specialization" = EXCLUDED."Specialization";

-- 4. Create Courses
INSERT INTO "Course" ("CourseId", "Code", "Title", "Description", "Credits", "DepartmentId", "CourseLevel", "Category")
VALUES 
    ('course-cs201', 'CS201', 'Object Oriented II', 'Advanced Object-Oriented Programming concepts', 3.0, 'dept-cs-001', 'L2', 'CoreRequirement'),
    ('course-cs202', 'CS202', 'File Organization', 'File structures and organization techniques', 3.0, 'dept-cs-001', 'L2', 'CoreRequirement')
ON CONFLICT ("Code") DO UPDATE SET
    "Title" = EXCLUDED."Title",
    "Description" = EXCLUDED."Description";

-- 5. Delete old lecture offerings for this faculty to start fresh
DELETE FROM "LectureCourseOffering" WHERE "FacultyId" = 'faculty-001';

-- 6. Create Monday Lecture Offerings with EXACT times
INSERT INTO "LectureCourseOffering" (
    "LectureOfferingId", "CourseId", "FacultyId", 
    "AcademicYear", "Semester", "Schedule", "RoomNo", "MaxCapacity"
)
VALUES 
    -- Object Oriented II - Monday 9:00 AM to 10:15 AM
    (
        'lect-offer-mon-001',
        'course-cs201',
        'faculty-001',
        EXTRACT(YEAR FROM CURRENT_DATE),
        'Fall',
        'Monday 09:00-10:15',
        'H-201',
        80
    ),
    -- File Organization - Monday 11:40 AM to 1:00 PM (13:00)
    (
        'lect-offer-mon-002',
        'course-cs202',
        'faculty-001',
        EXTRACT(YEAR FROM CURRENT_DATE),
        'Fall',
        'Monday 11:40-13:00',
        'H-202',
        80
    );

-- 7. Verification Query
SELECT 
    lco."LectureOfferingId",
    c."Code" AS "CourseCode",
    c."Title" AS "CourseTitle",
    lco."Schedule",
    lco."RoomNo",
    u."FullName" AS "Instructor"
FROM "LectureCourseOffering" lco
INNER JOIN "Course" c ON lco."CourseId" = c."CourseId"
INNER JOIN "Faculty" f ON lco."FacultyId" = f."FacultyId"
INNER JOIN "User" u ON f."UserId" = u."UserId"
WHERE lco."FacultyId" = 'faculty-001'
ORDER BY lco."Schedule";

-- =====================================================
-- Expected Output (on Monday):
-- 
-- CourseCode | CourseTitle          | Schedule             | RoomNo
-- -----------|----------------------|----------------------|--------
-- CS201      | Object Oriented II   | Monday 09:00-10:15  | H-201
-- CS202      | File Organization    | Monday 11:40-13:00  | H-202
--
-- On other days: Dashboard will show "No lectures scheduled for today"
-- =====================================================

-- Success Message
DO $$
BEGIN
    RAISE NOTICE '✅ Monday courses created successfully!';
    RAISE NOTICE '📚 Course 1: Object Oriented II (Monday 09:00-10:15)';
    RAISE NOTICE '📚 Course 2: File Organization (Monday 11:40-13:00)';
    RAISE NOTICE '👨‍🏫 Assigned to: Prof. Dr. Hanafy Ismail';
    RAISE NOTICE '🔑 Login: drhanafy@cs.mti.edu.eg / password123';
END $$;

