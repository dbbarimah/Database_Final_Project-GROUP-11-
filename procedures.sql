-- 3 Stored Procedures
-- Procedure 1: Enrolls a student into a course
DROP PROCEDURE IF EXISTS sp_EnrollStudent;
DELIMITER //
CREATE PROCEDURE sp_EnrollStudent(
    IN p_StudentID INT,
    IN p_CourseID INT,
    IN p_Semester VARCHAR(7),
    IN p_EnrollmentDate DATE
)
BEGIN
    -- Business rule: a student cannot be enrolled in the same course twice in the same semester.
    IF EXISTS (
        SELECT 1 FROM Enrollment
        WHERE StudentID = p_StudentID
          AND CourseID = p_CourseID
          AND Semester = p_Semester
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student is already enrolled in this course for this semester.';
    ELSE
        INSERT INTO Enrollment (StudentID, CourseID, Semester, EnrollmentDate, EnrollmentStatus)
        VALUES (p_StudentID, p_CourseID, p_Semester, p_EnrollmentDate, 'Active');
    END IF;
END //
DELIMITER ;


-- Procedure 2: Records a student's score for a specific assessment
DROP PROCEDURE IF EXISTS sp_RecordGrade;
DELIMITER //
CREATE PROCEDURE sp_RecordGrade(
    IN p_EnrollmentID INT,
    IN p_AssessmentID INT,
    IN p_Score DECIMAL(5,2)
)
BEGIN
    DECLARE v_MaxScore DECIMAL(5,2);

    SELECT MaxScore INTO v_MaxScore
    FROM Assessment
    WHERE AssessmentID = p_AssessmentID;

    -- Business rule: a score cannot exceed the assessment's max score.
    IF p_Score > v_MaxScore THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Score obtained cannot exceed the assessment max score.';
    ELSE
        INSERT INTO Grade (EnrollmentID, AssessmentID, ScoreObtained, DateRecorded)
        VALUES (p_EnrollmentID, p_AssessmentID, p_Score, CURDATE());
    END IF;
END //
DELIMITER ;


-- Procedure 3: Returns a student's cumulative weighted score per course
DROP PROCEDURE IF EXISTS sp_GetStudentTranscript//
CREATE PROCEDURE sp_GetStudentTranscript(IN p_StudentID INT)
BEGIN
    SELECT
        e.EnrollmentID,
        c.CourseCode,
        c.CourseTitle,
        c.CreditHours,
        e.Semester,
        e.EnrollmentStatus,
        ROUND(SUM((g.ScoreObtained / a.MaxScore) * a.WeightPercent), 2) AS CumulativeScore,
        ROUND(SUM(a.WeightPercent), 2) AS WeightGraded,
        (SELECT ROUND(SUM(WeightPercent), 2) FROM Assessment WHERE CourseID = e.CourseID) AS TotalWeight,
        fn_GPA(p_StudentID) AS GPA
    FROM Enrollment e
    JOIN Course c ON c.CourseID = e.CourseID
    JOIN Grade g ON g.EnrollmentID = e.EnrollmentID
    JOIN Assessment a ON a.AssessmentID = g.AssessmentID
    WHERE e.StudentID = p_StudentID
    GROUP BY e.EnrollmentID, c.CourseCode, c.CourseTitle, c.CreditHours, e.Semester, e.EnrollmentStatus
    ORDER BY e.Semester, c.CourseCode;
END//


GRANT EXECUTE ON PROCEDURE Group11_FinalProject.sp_GetStudentTranscript TO student;
GRANT EXECUTE ON FUNCTION Group11_FinalProject.fn_GPA TO student;




-- 2 User-Defined Functions
-- User-Defined Function 1: Calculates a Student's Weighted Average Score in a specific Course
DROP FUNCTION IF EXISTS fn_CourseWeightedAverage;
DELIMITER //
CREATE FUNCTION fn_CourseWeightedAverage(p_StudentID INT, p_CourseID INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_Average DECIMAL(5,2);

    SELECT ROUND(SUM((g.ScoreObtained / a.MaxScore) * a.WeightPercent), 2)
    INTO v_Average
    FROM Grade g
    JOIN Assessment a ON a.AssessmentID = g.AssessmentID
    JOIN Enrollment e ON e.EnrollmentID = g.EnrollmentID
    WHERE e.StudentID = p_StudentID
      AND e.CourseID = p_CourseID;

    RETURN IFNULL(v_Average, 0.00);
END //
DELIMITER ;


-- User-Defined Function 2: Calculates the Attendance Rate for a Specific Course
DROP FUNCTION IF EXISTS fn_AttendanceRate;
DELIMITER //
CREATE FUNCTION fn_AttendanceRate(p_StudentID INT, p_CourseID INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_Total INT;
    DECLARE v_Present INT;

    SELECT COUNT(*), SUM(CASE WHEN att.AttendanceStatus = 'Present' THEN 1 ELSE 0 END)
    INTO v_Total, v_Present
    FROM Attendance att
    JOIN Enrollment e ON e.EnrollmentID = att.EnrollmentID
    WHERE e.StudentID = p_StudentID
      AND e.CourseID = p_CourseID;

    IF v_Total = 0 OR v_Total IS NULL THEN
        RETURN 0.00;
    ELSE
        RETURN ROUND(100 * v_Present / v_Total, 2);
    END IF;
END //
DELIMITER ;

-- Additional User-Defined Function: Calculates a Student's GPA
DELIMITER //
CREATE FUNCTION fn_GPA(p_StudentID INT)
RETURNS DECIMAL(3,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_GPA DECIMAL(3,2);

    SELECT ROUND(SUM(grade_points * CreditHours) / SUM(CreditHours), 2)
    INTO v_GPA
    FROM (
        SELECT
            c.CreditHours,
            CASE
                WHEN ROUND(SUM((g.ScoreObtained / a.MaxScore) * a.WeightPercent), 2) >= 90 THEN 4.0
                WHEN ROUND(SUM((g.ScoreObtained / a.MaxScore) * a.WeightPercent), 2) >= 85 THEN 4.0
                WHEN ROUND(SUM((g.ScoreObtained / a.MaxScore) * a.WeightPercent), 2) >= 80 THEN 3.5
                WHEN ROUND(SUM((g.ScoreObtained / a.MaxScore) * a.WeightPercent), 2) >= 75 THEN 3.0
                WHEN ROUND(SUM((g.ScoreObtained / a.MaxScore) * a.WeightPercent), 2) >= 70 THEN 2.5
                WHEN ROUND(SUM((g.ScoreObtained / a.MaxScore) * a.WeightPercent), 2) >= 65 THEN 2.0
                WHEN ROUND(SUM((g.ScoreObtained / a.MaxScore) * a.WeightPercent), 2) >= 60 THEN 1.5
                WHEN ROUND(SUM((g.ScoreObtained / a.MaxScore) * a.WeightPercent), 2) >= 55 THEN 1.0
                ELSE 0.0
            END AS grade_points
        FROM Enrollment e
        JOIN Course c ON c.CourseID = e.CourseID
        JOIN Grade g ON g.EnrollmentID = e.EnrollmentID
        JOIN Assessment a ON a.AssessmentID = g.AssessmentID
        WHERE e.StudentID = p_StudentID
        GROUP BY e.EnrollmentID, c.CreditHours
    ) AS course_grades;

    RETURN IFNULL(v_GPA, 0.00);
END//
DELIMITER ;
