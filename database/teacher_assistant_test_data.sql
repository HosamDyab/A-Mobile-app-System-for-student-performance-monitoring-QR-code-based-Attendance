-- =====================================================
-- TEACHER ASSISTANT TEST DATA
-- Creates a TA with today's sections for testing
-- =====================================================

-- 1. Create TA User
INSERT INTO "User" (
    "UserId", "Email", "PasswordHash", "FullName", "Role", 
    "DepartmentId", "Phone", "IsActive"
)
VALUES (
    'user-ta-001', 
    'Gina.Hamdy@cs.mti.edu.eg', 
    'password123',
    'Gina Hamdy',
    'TeacherAssistant',
    'dept-cs-001',
    '+201234567891',
    TRUE
)
ON CONFLICT ("Email") DO UPDATE SET
    "PasswordHash" = EXCLUDED."PasswordHash",
    "IsActive" = TRUE;

-- 2. Create TA Record
INSERT INTO "TeacherAssistant" (
    "TAId", "UserId", "EmployeeCode", 
    "ContractStart", "Specialization"
)
VALUES (
    'ta-001',
    'user-ta-001',
    'TA-001',
    '2023-09-01',
    'Database Systems'
)
ON CONFLICT ("UserId") DO UPDATE SET
    "EmployeeCode" = EXCLUDED."EmployeeCode";

-- 3. Get current day name for scheduling
DO $$
DECLARE
    current_day TEXT;
    current_year INTEGER;
BEGIN
    current_day := TO_CHAR(CURRENT_DATE, 'Day');
    current_day := TRIM(current_day);
    current_year := EXTRACT(YEAR FROM CURRENT_DATE);

    -- 4. Create Section Offerings for TODAY (linked to existing lectures)
    -- Section for Database Systems - Today at 13:00-15:00
    INSERT INTO "SectionCourseOffering" (
        "SectionOfferingId", "LectureOfferingId", "CourseId", 
        "SectionNo", "TAId", "AcademicYear", "Semester", 
        "Schedule", "RoomNo", "MaxCapacity"
    )
    VALUES (
        'sect-offer-001',
        'lect-offer-002',  -- Database Systems lecture
        'course-cs412',
        'S1',
        'ta-001',
        current_year,
        'Fall',
        current_day || ' 13:00-15:00',
        'Lab-201',
        30
    )
    ON CONFLICT ("CourseId", "AcademicYear", "Semester", "SectionNo") 
    DO UPDATE SET "Schedule" = EXCLUDED."Schedule", "TAId" = EXCLUDED."TAId";

    -- Section for Operating Systems - Today at 16:30-18:30
    INSERT INTO "SectionCourseOffering" (
        "SectionOfferingId", "LectureOfferingId", "CourseId", 
        "SectionNo", "TAId", "AcademicYear", "Semester", 
        "Schedule", "RoomNo", "MaxCapacity"
    )
    VALUES (
        'sect-offer-002',
        'lect-offer-003',  -- Operating Systems lecture
        'course-cs413',
        'S1',
        'ta-001',
        current_year,
        'Fall',
        current_day || ' 16:30-18:30',
        'Lab-202',
        30
    )
    ON CONFLICT ("CourseId", "AcademicYear", "Semester", "SectionNo") 
    DO UPDATE SET "Schedule" = EXCLUDED."Schedule", "TAId" = EXCLUDED."TAId";
END $$;

-- 5. Verification Query
SELECT 
    sco."SectionOfferingId",
    c."Code" AS "CourseCode",
    c."Title" AS "CourseTitle",
    sco."SectionNo",
    sco."Schedule",
    sco."RoomNo",
    u."FullName" AS "TA"
FROM "SectionCourseOffering" sco
INNER JOIN "Course" c ON sco."CourseId" = c."CourseId"
INNER JOIN "TeacherAssistant" ta ON sco."TAId" = ta."TAId"
INNER JOIN "User" u ON ta."UserId" = u."UserId"
WHERE sco."TAId" = 'ta-001'
  AND sco."Schedule" LIKE '%' || TRIM(TO_CHAR(CURRENT_DATE, 'Day')) || '%'
ORDER BY sco."Schedule";

-- =====================================================
-- Expected Output:
-- Shows 2 sections for Gina Hamdy scheduled for TODAY
-- =====================================================

-- =====================================================
-- TO TEST:
-- 1. Login as TA: Gina.Hamdy@cs.mti.edu.eg / password123
-- 2. Dashboard will show today's 2 sections
-- 3. Can generate QR and track attendance for sections
-- =====================================================


