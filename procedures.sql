USE Group11_FinalProject;

/* =========================================================
   STORED PROCEDURES (3)
   ========================================================= */

DROP PROCEDURE IF EXISTS sp_EnrollStudent;
DELIMITER $$
CREATE PROCEDURE sp_EnrollStudent(
    IN p_StudentID INT,
    IN p_CourseID INT,
    IN p_Semester CHAR(1),
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
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_RecordGrade;
DELIMITER $$
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
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_GetStudentTranscript;
DELIMITER $$
CREATE PROCEDURE sp_GetStudentTranscript(IN p_StudentID INT)
BEGIN
    SELECT
        c.CourseCode,
        c.CourseTitle,
        e.Semester,
        a.AssessmentType,
        g.ScoreObtained,
        a.MaxScore,
        g.DateRecorded
    FROM Enrollment e
    JOIN Course c ON c.CourseID = e.CourseID
    JOIN Grade g ON g.EnrollmentID = e.EnrollmentID
    JOIN Assessment a ON a.AssessmentID = g.AssessmentID
    WHERE e.StudentID = p_StudentID
    ORDER BY e.Semester, c.CourseCode, a.AssessmentType;
END$$
DELIMITER ;


/* =========================================================
   USER-DEFINED FUNCTIONS (2)
   ========================================================= */

DROP FUNCTION IF EXISTS fn_CourseWeightedAverage;
DELIMITER $$
CREATE FUNCTION fn_CourseWeightedAverage(p_EnrollmentID INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_Average DECIMAL(5,2);

    SELECT ROUND(SUM((g.ScoreObtained / a.MaxScore) * a.WeightPercent), 2)
    INTO v_Average
    FROM Grade g
    JOIN Assessment a ON a.AssessmentID = g.AssessmentID
    WHERE g.EnrollmentID = p_EnrollmentID;

    RETURN IFNULL(v_Average, 0.00);
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS fn_AttendanceRate;
DELIMITER $$
CREATE FUNCTION fn_AttendanceRate(p_EnrollmentID INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_Total INT;
    DECLARE v_Present INT;

    SELECT COUNT(*), SUM(CASE WHEN AttendanceStatus = 'Present' THEN 1 ELSE 0 END)
    INTO v_Total, v_Present
    FROM Attendance
    WHERE EnrollmentID = p_EnrollmentID;

    IF v_Total = 0 OR v_Total IS NULL THEN
        RETURN 0.00;
    ELSE
        RETURN ROUND(100 * v_Present / v_Total, 2);
    END IF;
END$$
DELIMITER ;


/* =========================================================
   TRIGGERS (3) -- business rules
   ========================================================= */

DROP TRIGGER IF EXISTS trg_PreventDuplicateEnrollment;
DELIMITER $$
CREATE TRIGGER trg_PreventDuplicateEnrollment
BEFORE INSERT ON Enrollment
FOR EACH ROW
BEGIN
    -- Business rule: no duplicate enrollment for the same student/course/semester.
    IF EXISTS (
        SELECT 1 FROM Enrollment
        WHERE StudentID = NEW.StudentID
          AND CourseID = NEW.CourseID
          AND Semester = NEW.Semester
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Duplicate enrollment: student already enrolled in this course this semester.';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_ValidateGradeScore;
DELIMITER $$
CREATE TRIGGER trg_ValidateGradeScore
BEFORE INSERT ON Grade
FOR EACH ROW
BEGIN
    DECLARE v_MaxScore DECIMAL(5,2);

    SELECT MaxScore INTO v_MaxScore
    FROM Assessment
    WHERE AssessmentID = NEW.AssessmentID;

    -- Business rule: a recorded score cannot exceed the assessment's max score.
    IF NEW.ScoreObtained > v_MaxScore THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Score obtained exceeds the max score for this assessment.';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_CompleteEnrollmentOnExam;
DELIMITER $$
CREATE TRIGGER trg_CompleteEnrollmentOnExam
AFTER INSERT ON Grade
FOR EACH ROW
BEGIN
    DECLARE v_Type VARCHAR(20);

    SELECT AssessmentType INTO v_Type
    FROM Assessment
    WHERE AssessmentID = NEW.AssessmentID;

    -- Business rule: once a student's exam grade is recorded, the enrollment is complete.
    IF v_Type = 'Exam' THEN
        UPDATE Enrollment
        SET EnrollmentStatus = 'Completed'
        WHERE EnrollmentID = NEW.EnrollmentID;
    END IF;
END$$
DELIMITER ;


/* =========================================================
   USAGE EXAMPLES (commented out -- for manual testing only)
   =========================================================
CALL sp_EnrollStudent(1, 2, '1', CURDATE());
CALL sp_RecordGrade(1, 3, 45.00);
CALL sp_GetStudentTranscript(1);
SELECT fn_CourseWeightedAverage(1);
SELECT fn_AttendanceRate(1);
*/
