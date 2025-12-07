-- ============================================
-- Add Dr. Hanafy's Monday Lecture Instance
-- ============================================
-- Course: Project (example)
-- Day: Monday
-- Time: 9:00 AM - 3:35 PM
-- ============================================

-- Step 1: Find Dr. Hanafy's FacultyId (if you don't know it)
SELECT 
    f."FacultyId",
    f."EmployeeCode",
    u."FullName",
    u."Email"
FROM "Faculty" f
JOIN "User" u ON f."UserId" = u."UserId"
WHERE u."Email" ILIKE '%hanafy%'
   OR u."FullName" ILIKE '%hanafy%';

-- Expected result: FacultyId = 'FAC-001'

-- ============================================
-- Step 2: Check Dr. Hanafy's Active Courses
-- ============================================
SELECT 
    lco."LectureOfferingId",
    lco."AcademicYear",
    lco."Semester",
    c."Code",
    c."Title",
    lco."Schedule",
    lco."RoomNo"
FROM "LectureCourseOffering" lco
JOIN "Course" c ON lco."CourseId" = c."CourseId"
WHERE lco."FacultyId" = 'FAC-001'
  AND lco."IsActive" = TRUE
ORDER BY c."Code";

-- ============================================
-- Step 3: Create Monday Lecture Instance for Project Course
-- ============================================

-- Option A: If you know the LectureOfferingId
INSERT INTO "LectureInstance" (
    "InstanceId",
    "LectureOfferingId",
    "MeetingDate",
    "StartTime",
    "EndTime",
    "Topic",
    "QRCode",
    "QRExpiresAt",
    "IsCancelled"
)
VALUES (
    gen_random_uuid()::text,
    'REPLACE_WITH_LECTURE_OFFERING_ID', -- Get this from Step 2
    '2024-12-09',  -- Next Monday (adjust date as needed)
    '09:00:00',    -- 9:00 AM
    '15:35:00',    -- 3:35 PM
    'Project Session - Monday',
    gen_random_uuid()::text,  -- QR Code
    NOW() + INTERVAL '6 hours',  -- QR expires in 6 hours
    FALSE
);

-- Option B: Create instance for ALL Dr. Hanafy's courses on Monday
-- (Use this if Dr. Hanafy teaches multiple courses)
INSERT INTO "LectureInstance" (
    "InstanceId",
    "LectureOfferingId",
    "MeetingDate",
    "StartTime",
    "EndTime",
    "Topic",
    "QRCode",
    "QRExpiresAt",
    "IsCancelled"
)
SELECT 
    gen_random_uuid()::text,
    lco."LectureOfferingId",
    '2024-12-09',  -- Next Monday
    '09:00:00',
    '15:35:00',
    c."Title" || ' - Monday Project Session',
    gen_random_uuid()::text,
    NOW() + INTERVAL '6 hours',
    FALSE
FROM "LectureCourseOffering" lco
JOIN "Course" c ON lco."CourseId" = c."CourseId"
WHERE lco."FacultyId" = 'FAC-001'
  AND lco."IsActive" = TRUE;

-- ============================================
-- Step 4: Create Recurring Monday Instances (Next 4 Weeks)
-- ============================================

-- This will create lecture instances for the next 4 Mondays
WITH monday_dates AS (
    SELECT generate_series(
        date_trunc('week', CURRENT_DATE) + INTERVAL '7 days',  -- Next Monday
        date_trunc('week', CURRENT_DATE) + INTERVAL '28 days', -- 4 weeks ahead
        INTERVAL '7 days'
    )::date AS meeting_date
)
INSERT INTO "LectureInstance" (
    "InstanceId",
    "LectureOfferingId",
    "MeetingDate",
    "StartTime",
    "EndTime",
    "Topic",
    "QRCode",
    "QRExpiresAt",
    "IsCancelled"
)
SELECT 
    gen_random_uuid()::text,
    lco."LectureOfferingId",
    md.meeting_date,
    '09:00:00',
    '15:35:00',
    c."Title" || ' - Monday Session',
    gen_random_uuid()::text,
    md.meeting_date + TIME '15:35:00' + INTERVAL '2 hours',  -- QR expires 2 hours after class ends
    FALSE
FROM monday_dates md
CROSS JOIN "LectureCourseOffering" lco
JOIN "Course" c ON lco."CourseId" = c."CourseId"
WHERE lco."FacultyId" = 'FAC-001'
  AND lco."IsActive" = TRUE
ON CONFLICT DO NOTHING;

-- ============================================
-- Step 5: Verify Created Instances
-- ============================================

SELECT 
    li."InstanceId",
    li."MeetingDate",
    li."StartTime",
    li."EndTime",
    li."Topic",
    li."QRCode",
    li."QRExpiresAt",
    c."Code" as course_code,
    c."Title" as course_title,
    CASE 
        WHEN li."QRExpiresAt" > NOW() THEN '✅ Active'
        ELSE '❌ Expired'
    END as qr_status
FROM "LectureInstance" li
JOIN "LectureCourseOffering" lco ON li."LectureOfferingId" = lco."LectureOfferingId"
JOIN "Course" c ON lco."CourseId" = c."CourseId"
WHERE lco."FacultyId" = 'FAC-001'
ORDER BY li."MeetingDate", c."Code";

-- ============================================
-- QUICK FIX: If You Need Specific Lecture Offering ID
-- ============================================

-- Find the LectureOfferingId for a specific course
SELECT 
    lco."LectureOfferingId",
    c."Code",
    c."Title",
    lco."AcademicYear",
    lco."Semester"
FROM "LectureCourseOffering" lco
JOIN "Course" c ON lco."CourseId" = c."CourseId"
WHERE lco."FacultyId" = 'FAC-001'
  AND c."Title" ILIKE '%project%'  -- Adjust to match your course
  AND lco."IsActive" = TRUE;

-- Then use that LectureOfferingId in the INSERT above

-- ============================================
-- EXAMPLE: Complete Single Instance Creation
-- ============================================

-- Replace these values with your actual IDs:
DO $$
DECLARE
    v_lecture_offering_id TEXT;
    v_instance_id TEXT;
BEGIN
    -- Get Dr. Hanafy's Project course offering
    SELECT lco."LectureOfferingId" INTO v_lecture_offering_id
    FROM "LectureCourseOffering" lco
    JOIN "Course" c ON lco."CourseId" = c."CourseId"
    WHERE lco."FacultyId" = 'FAC-001'
      AND lco."IsActive" = TRUE
    LIMIT 1;  -- Change this to get specific course

    IF v_lecture_offering_id IS NOT NULL THEN
        -- Create Monday instance
        INSERT INTO "LectureInstance" (
            "InstanceId",
            "LectureOfferingId",
            "MeetingDate",
            "StartTime",
            "EndTime",
            "Topic",
            "QRCode",
            "QRExpiresAt",
            "IsCancelled"
        )
        VALUES (
            gen_random_uuid()::text,
            v_lecture_offering_id,
            CURRENT_DATE + ((8 - EXTRACT(ISODOW FROM CURRENT_DATE)::INT) % 7),  -- Next Monday
            '09:00:00',
            '15:35:00',
            'Monday Project Session',
            gen_random_uuid()::text,
            (CURRENT_DATE + ((8 - EXTRACT(ISODOW FROM CURRENT_DATE)::INT) % 7) + TIME '17:35:00'),  -- QR expires at 5:35 PM
            FALSE
        )
        RETURNING "InstanceId" INTO v_instance_id;

        RAISE NOTICE '✅ Lecture instance created: %', v_instance_id;
    ELSE
        RAISE NOTICE '❌ No active lecture offering found for Dr. Hanafy';
    END IF;
END $$;

-- ============================================
-- Success Message
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ DR. HANAFY MONDAY LECTURE SETUP COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Details:';
    RAISE NOTICE '  📅 Day: Monday';
    RAISE NOTICE '  🕐 Time: 9:00 AM - 3:35 PM';
    RAISE NOTICE '  📚 Course: Project';
    RAISE NOTICE '  👨‍🏫 Faculty: Dr. Hanafy (FAC-001)';
    RAISE NOTICE '';
    RAISE NOTICE 'What was created:';
    RAISE NOTICE '  ✅ Lecture instance(s) for Monday';
    RAISE NOTICE '  ✅ QR code generated (expires after class)';
    RAISE NOTICE '  ✅ Ready for student attendance';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Navigate to QR generation screen';
    RAISE NOTICE '  2. Select Monday instance';
    RAISE NOTICE '  3. Display QR for students to scan';
    RAISE NOTICE '========================================';
END $$;

