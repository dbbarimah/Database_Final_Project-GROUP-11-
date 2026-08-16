


-- 3 Triggers
-- Trigger 1: Prevents a student from being enrolled in the same course twice in the same semester.
DROP TRIGGER IF EXISTS trg_PreventDuplicateEnrollment;
DELIMITER //
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
END //
DELIMITER ;


-- Trigger 2: Prevents a grade from being recorded if it exceeds the maximum score for that assessment.
DROP TRIGGER IF EXISTS trg_ValidateGradeScore;
DELIMITER //
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
END //
DELIMITER ;


-- Trigger 3: Updates a student's enrollment status to Completed once their exam grade has been recorded
DROP TRIGGER IF EXISTS trg_CompleteEnrollmentOnExam;
DELIMITER //
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
END //
DELIMITER ;


-- Additional Trigger 4: Prevents a faculty intern from being assigned to more than one course per semester
DROP TRIGGER IF EXISTS trg_OneFIPerSemester;
DELIMITER //
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
END //
DELIMITER ;


-- Additional Trigger 5: Prevents assessment weights from exceeding 100% per course
DROP TRIGGER IF EXISTS trg_ValidateAssessmentWeight;
DELIMITER //

CREATE TRIGGER trg_ValidateAssessmentWeight
BEFORE INSERT ON Assessment
FOR EACH ROW
BEGIN
    IF (
        SELECT COALESCE(SUM(WeightPercent), 0)
        FROM Assessment
        WHERE CourseID = NEW.CourseID
    ) + NEW.WeightPercent > 100 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Total assessment weight cannot exceed 100%.';
    END IF;
END //

DELIMITER ;


-- Additional Trigger 6: Prevents duplicate Exam or MidSemester assessments
DELIMITER //

CREATE OR REPLACE TRIGGER trg_UniqueExamAndMidSemester
BEFORE INSERT ON Assessment
FOR EACH ROW
BEGIN
    IF NEW.AssessmentType IN ('Exam', 'MidSemester') AND EXISTS (
        SELECT 1 FROM Assessment
        WHERE CourseID = NEW.CourseID
          AND AssessmentType = NEW.AssessmentType
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A course can only have one Exam and one MidSemester assessment.';
    END IF;
END//

DELIMITER ;



-- Additional Trigger 7: Prevents the total assessment weight for a course from exceeding 100%
CREATE OR REPLACE TRIGGER trg_ValidateAssessmentWeightDELIMITER //

CREATE OR REPLACE TRIGGER trg_ValidateAssessmentWeight
BEFORE INSERT ON Assessment
FOR EACH ROW
BEGIN
    DECLARE v_TotalWeight DECIMAL(5,2);

    SELECT COALESCE(SUM(WeightPercent), 0)
    INTO v_TotalWeight
    FROM Assessment
    WHERE CourseID = NEW.CourseID;

    IF v_TotalWeight + NEW.WeightPercent > 100 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Total assessment weight for this course cannot exceed 100%.';
    END IF;
END//

DELIMITER ;
