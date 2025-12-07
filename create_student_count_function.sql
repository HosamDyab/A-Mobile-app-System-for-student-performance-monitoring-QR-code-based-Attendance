-- ============================================
-- Create get_faculty_student_count Function
-- ============================================
-- This function counts the total number of students
-- enrolled in a faculty member's courses

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
      AND lco."IsActive" = TRUE;
    
    RETURN COALESCE(student_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment
COMMENT ON FUNCTION get_faculty_student_count IS 'Returns the count of distinct students enrolled in a faculty member''s courses';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_faculty_student_count TO authenticated;
GRANT EXECUTE ON FUNCTION get_faculty_student_count TO anon;

-- Test the function
-- SELECT get_faculty_student_count('FAC-001');

