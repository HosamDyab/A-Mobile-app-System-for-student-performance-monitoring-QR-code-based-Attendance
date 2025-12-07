-- =====================================================
-- TEST STUDENT FOR ATTENDANCE
-- Creates a test student for QR scanning
-- =====================================================

-- 1. Create Student User
INSERT INTO "User" (
    "UserId", "Email", "PasswordHash", "FullName", "Role", 
    "DepartmentId", "Phone", "IsActive"
)
VALUES (
    'user-student-test',
    'ahmed.200123@cs.mti.edu.eg',
    'password123',
    'Ahmed Mohamed',
    'Student',
    'dept-cs-001',
    '+201111111111',
    TRUE
)
ON CONFLICT ("Email") DO UPDATE SET
    "PasswordHash" = EXCLUDED."PasswordHash",
    "IsActive" = TRUE;

-- 2. Create Student Record
INSERT INTO "Student" (
    "StudentId", "UserId", "StudentCode", "Major", 
    "CurrentGPA", "AcademicLevel", "GroupName",
    "EnrollmentYear", "CurrentAcademicYear", "CurrentSemester",
    "Status"
)
VALUES (
    'student-test-001',
    'user-student-test',
    'STU-200123',
    'CS',
    3.50,
    'L4',
    'Group A',
    2020,
    EXTRACT(YEAR FROM CURRENT_DATE),
    'Fall',
    'Active'
)
ON CONFLICT ("UserId") DO UPDATE SET
    "AcademicLevel" = EXCLUDED."AcademicLevel",
    "CurrentSemester" = EXCLUDED."CurrentSemester";

-- =====================================================
-- INSTRUCTIONS FOR TESTING ATTENDANCE:
-- =====================================================
-- 
-- 1. Login as Faculty (drhanafy@cs.mti.edu.eg / password123)
-- 2. Go to Dashboard - you'll see today's lectures
-- 3. Click on a lecture and set timer (e.g., 10 minutes)
-- 4. Note the QR code displayed
-- 
-- 5. To simulate student scanning (manual INSERT):
--    Replace 'YOUR_SESSION_ID' with the actual sessionId from QR code
--
-- INSERT INTO "LectureInstance" (
--     "InstanceId",
--     "LectureOfferingId",
--     "MeetingDate",
--     "StartTime",
--     "EndTime",
--     "QRCode"
-- )
-- VALUES (
--     'YOUR_SESSION_ID',  -- e.g., 'LINST-1701234567890'
--     'lect-offer-001',   -- Choose matching lecture offering
--     CURRENT_DATE,
--     CURRENT_TIME,
--     CURRENT_TIME + INTERVAL '10 minutes',
--     'YOUR_SESSION_ID'
-- );
--
-- INSERT INTO "LectureQR" (
--     "StudentId",
--     "InstanceId",
--     "ScanTime",
--     "Status"
-- )
-- VALUES (
--     'student-test-001',
--     'YOUR_SESSION_ID',
--     NOW(),
--     'Present'
-- );
--
-- 6. The faculty screen will now show "Ahmed Mohamed" in the attendance list!
-- =====================================================


