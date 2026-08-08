USE Group11_FinalProject;

/* The purpose of this file is to implement the advanced SQL queries (Phase 6)
5 views
3 stored procedures
2 user-defined functions
3 triggers implemeneting business rules
*/

-- 5 Views
-- View 1: Calculates the Student's weighted average score for each course they enrolled in
DROP VIEW IF EXISTS vw_StudentCourseAverage;
CREATE VIEW vw_StudentCourseAverage AS
SELECT
    e.EnrollmentID,
    e.StudentID,
    s.Fname,
    s.Lname,
    e.CourseID,
    c.CourseTitle,
    e.Semester,
    ROUND(SUM((g.ScoreObtained / a.MaxScore) * a.WeightPercent), 2) AS WeightedAverage
FROM Enrollment e
JOIN Student s ON s.StudentID = e.StudentID
JOIN Course c ON c.CourseID = e.CourseID
JOIN Grade g ON g.EnrollmentID = e.EnrollmentID
JOIN Assessment a ON a.AssessmentID = g.AssessmentID
GROUP BY e.EnrollmentID, e.StudentID, s.Fname, s.Lname, e.CourseID, c.CourseTitle, e.Semester;


-- View 2: Shows how many students are enrolled in each course per semester
DROP VIEW IF EXISTS vw_CourseEnrollmentSummary;
CREATE VIEW vw_CourseEnrollmentSummary AS
SELECT
    c.CourseID,
    c.CourseCode,
    c.CourseTitle,
    e.Semester,
    COUNT(e.EnrollmentID) AS StudentsEnrolled
FROM Course c
JOIN Enrollment e ON e.CourseID = c.CourseID
GROUP BY c.CourseID, c.CourseCode, c.CourseTitle, e.Semester;


-- View 3: Shows how many Courses each Staff member is assigned to per semester
DROP VIEW IF EXISTS vw_StaffTeachingLoad;
CREATE VIEW vw_StaffTeachingLoad AS
SELECT
    st.StaffID,
    st.Fname,
    st.Lname,
    st.Role,
    ta.Semester,
    COUNT(ta.AssignmentID) AS CoursesAssigned
FROM Staff st
JOIN Teaching_Assignment ta ON ta.AssigneeID = st.StaffID
GROUP BY st.StaffID, st.Fname, st.Lname, st.Role, ta.Semester;


-- View 4: Shows the attendance record for each enrolled student per course
DROP VIEW IF EXISTS vw_AttendanceSummary;
CREATE VIEW vw_AttendanceSummary AS
SELECT
    e.EnrollmentID,
    e.StudentID,
    CONCAT(s.Fname, ' ', s.Lname) AS StudentName,
    e.CourseID,
    COUNT(att.AttendanceID) AS SessionsRecorded,
    SUM(CASE WHEN att.AttendanceStatus = 'Present' THEN 1 ELSE 0 END) AS SessionsPresent,
    ROUND(100 * SUM(CASE WHEN att.AttendanceStatus = 'Present' THEN 1 ELSE 0 END) / COUNT(att.AttendanceID), 2) AS AttendanceRatePct
FROM Enrollment e
JOIN Student s ON s.StudentID = e.StudentID
JOIN Attendance att ON att.EnrollmentID = e.EnrollmentID
GROUP BY e.EnrollmentID, e.StudentID, s.Fname, s.Lname, e.CourseID;


-- View 5: Gives a summary of each department
DROP VIEW IF EXISTS vw_DepartmentOverview;
CREATE VIEW vw_DepartmentOverview AS
SELECT
    d.DepartmentID,
    d.DeptCode,
    d.DeptName,
    CONCAT(hs.Fname, ' ', hs.Lname) AS HeadOfDepartment,
    (SELECT COUNT(*) FROM Staff st WHERE st.DepartmentID = d.DepartmentID) AS StaffCount,
    (SELECT COUNT(*) FROM Student stu WHERE stu.DepartmentID = d.DepartmentID) AS StudentCount,
    (SELECT COUNT(*) FROM Course c WHERE c.DepartmentID = d.DepartmentID) AS CourseCount
FROM Department d
LEFT JOIN Staff hs ON hs.StaffID = d.HeadID;


-- Additional View: Shows the number of materials available per course
DROP VIEW IF EXISTS vw_CourseMaterialSummary;
CREATE VIEW vw_CourseMaterialSummary AS
SELECT
    c.CourseID,
    c.CourseCode,
    c.CourseTitle,
    COUNT(cm.MaterialID) AS MaterialCount,
    MAX(cm.DateUploaded) AS LastUploaded
FROM Course c
LEFT JOIN CourseMaterial cm ON cm.CourseID = c.CourseID
GROUP BY c.CourseID, c.CourseCode, c.CourseTitle;



-- 3 Stored Procedures
-- Procedure 1: Enrolls a student into a course
DROP PROCEDURE IF EXISTS sp_EnrollStudent;
DELIMITER $$
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
END$$
DELIMITER ;


-- Procedure 2: Records a student's score for a specific assessment
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


-- Procedure 3: Takes in a StudentID and returns their full academic record
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




-- 2 User-Defined Functions
-- User-Defined Function 1: Calculates a Student's Weighted Average Score in a specific Course
DROP FUNCTION IF EXISTS fn_CourseWeightedAverage;
DELIMITER $$
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
END$$
DELIMITER ;


-- User-Defined Function 2: Calculates the Attendance Rate for a Specific Course
DROP FUNCTION IF EXISTS fn_AttendanceRate;
DELIMITER $$
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
END$$
DELIMITER ;




-- 3 Triggers
-- Trigger 1: Prevents a student from being enrolled in the same course twice in the same semester.
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


-- Trigger 2: Prevents a grade from being recorded if it exceeds the maximum score for that assessment.
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


-- Trigger 3: Updates a student's enrollment status to Completed once their exam grade has been recorded
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


-- Additional Trigger: Prevents a faculty intern from being assigned to more than one course per semester
DROP TRIGGER IF EXISTS trg_OneFIPerSemester;
DELIMITER $$
CREATE TRIGGER trg_OneFIPerSemester
BEFORE INSERT ON Teaching_Assignment
FOR EACH ROW
BEGIN
    DECLARE v_Role VARCHAR(20);

    SELECT Role INTO v_Role
    FROM Staff
    WHERE StaffID = NEW.AssigneeID;

    IF v_Role = 'Faculty Intern' AND EXISTS (
        SELECT 1 FROM Teaching_Assignment
        WHERE AssigneeID = NEW.AssigneeID
          AND Semester = NEW.Semester
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A faculty intern can only be assigned to one course per semester.';
    END IF;
END$$
DELIMITER ;








