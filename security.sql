USE Group11_FinalProject;

/* Schema Account
This account owns the secure views and procedures in the database.
It is locked becasue it is only used internally by the database.
*/

CREATE USER IF NOT EXISTS 'lms_owner'@'localhost'
  IDENTIFIED BY 'ChangeMe_LMS1';

GRANT ALL PRIVILEGES ON Group11_FinalProject.* TO 'lms_owner'@'localhost';

ALTER USER 'lms_owner'@'localhost' ACCOUNT LOCK;


-- Creating the User roles for the database
DROP ROLE IF EXISTS db_admin;
DROP ROLE IF EXISTS lecturer;
DROP ROLE IF EXISTS faculty_intern;
DROP ROLE IF EXISTS student;

CREATE ROLE db_admin;
CREATE ROLE lecturer;
CREATE ROLE faculty_intern;
CREATE ROLE student;


-- FUNCTIONALITIES ASSOCIATED WITH DATABASE ADMINISTRATOR
-- Administrator privileges
GRANT ALL PRIVILEGES ON Group11_FinalProject.* TO db_admin;

GRANT CREATE USER ON *.* TO db_admin;
GRANT RELOAD, PROCESS, SHOW DATABASES ON *.* TO db_admin;

GRANT LOCK TABLES, SELECT, SHOW VIEW, EVENT, TRIGGER
  ON Group11_FinalProject.* TO db_admin;
GRANT REPLICATION CLIENT ON *.* TO db_admin;

-- Login and access-control functions
-- Gets the username of the person logging in
DELIMITER $$

DROP FUNCTION IF EXISTS fn_login$$
CREATE DEFINER = 'lms_owner'@'localhost'
FUNCTION fn_login() RETURNS VARCHAR(100)
  DETERMINISTIC SQL SECURITY DEFINER
BEGIN
  RETURN SUBSTRING_INDEX(SESSION_USER(), '@', 1);
END$$

-- Finds the student ID that belongs to the logged-in student
DROP FUNCTION IF EXISTS fn_current_student_id$$
CREATE DEFINER = 'lms_owner'@'localhost'
FUNCTION fn_current_student_id() RETURNS INT
  READS SQL DATA SQL SECURITY DEFINER
BEGIN
  DECLARE v_id INT DEFAULT NULL;
  SELECT StudentID INTO v_id
    FROM Student
   WHERE SUBSTRING_INDEX(StudentEmail, '@', 1) = fn_login()
   LIMIT 1;
  RETURN v_id;
END$$

-- Finds the staff ID thaat belongs to the logged-in Lecturer or Faculty Intern
DROP FUNCTION IF EXISTS fn_current_staff_id$$
CREATE DEFINER = 'lms_owner'@'localhost'
FUNCTION fn_current_staff_id() RETURNS INT
  READS SQL DATA SQL SECURITY DEFINER
BEGIN
  DECLARE v_id INT DEFAULT NULL;
  SELECT StaffID INTO v_id
    FROM Staff
   WHERE SUBSTRING_INDEX(StaffEmail, '@', 1) = fn_login()
   LIMIT 1;
  RETURN v_id;
END$$

-- Checks whether the logged-in staff is assigned to teach a specific course in a specific semester
DROP FUNCTION IF EXISTS fn_may_teach$$
CREATE DEFINER = 'lms_owner'@'localhost'
FUNCTION fn_may_teach(p_course_id INT, p_semester VARCHAR(10)) RETURNS BOOLEAN
  READS SQL DATA SQL SECURITY DEFINER
BEGIN
  DECLARE v_hit INT DEFAULT 0;
  SELECT COUNT(*) INTO v_hit
    FROM Teaching_Assignment
   WHERE CourseID   = p_course_id
     AND Semester   = p_semester
     AND AssigneeID = fn_current_staff_id();
  RETURN v_hit > 0;
END$$

DELIMITER ;


-- Giving lecturers, faculty interns, and students permission to view basic course information
GRANT SELECT ON Group11_FinalProject.Department
  TO lecturer, faculty_intern, student;
GRANT SELECT ON Group11_FinalProject.Course
  TO lecturer, faculty_intern, student;

GRANT SELECT ON Group11_FinalProject.Teaching_Assignment
  TO lecturer, faculty_intern;
GRANT SELECT (AssignmentID, CourseID, Semester)
  ON Group11_FinalProject.Teaching_Assignment TO student;



-- FUNCTIONALITIES ASSOCIATED WITH STUDENT
-- Showing the courses the logged-in student is enrolled in
CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_my_profile AS
SELECT s.StudentID, s.Fname, s.Lname, s.StudentEmail, s.StudentPhone,
       d.DeptCode, d.DeptName
  FROM Student s
  JOIN Department d ON d.DepartmentID = s.DepartmentID
 WHERE s.StudentID = fn_current_student_id();

-- Showing the courses the logged-in student is enrolled in
CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_my_enrollments AS
SELECT e.EnrollmentID, e.CourseID, e.Semester,
       e.EnrollmentDate, e.EnrollmentStatus,
       c.CourseCode, c.CourseTitle, c.CreditHours
  FROM Enrollment e
  JOIN Course c ON c.CourseID = e.CourseID
 WHERE e.StudentID = fn_current_student_id();

-- Showing the logged-in student's grades
CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_my_grades AS
SELECT g.GradeID, g.ScoreObtained, g.DateRecorded,
       a.AssessmentType, a.MaxScore, a.WeightPercent,
       ROUND(g.ScoreObtained / a.MaxScore * 100, 2) AS PercentScore,
       c.CourseCode, c.CourseTitle, e.Semester
  FROM Grade g
  JOIN Enrollment e ON e.EnrollmentID = g.EnrollmentID
  JOIN Assessment a ON a.AssessmentID = g.AssessmentID
  JOIN Course     c ON c.CourseID     = e.CourseID
 WHERE e.StudentID = fn_current_student_id();

-- Showing the logged-in student's attendace records
CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_my_attendance AS
SELECT at.AttendanceID, at.SessionDate, at.AttendanceStatus,
       c.CourseCode, c.CourseTitle, e.Semester
  FROM Attendance at
  JOIN Enrollment e ON e.EnrollmentID = at.EnrollmentID
  JOIN Course     c ON c.CourseID     = e.CourseID
 WHERE e.StudentID = fn_current_student_id();

-- Showing the assessments for the logged-in student's active courses
CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_my_assessments AS
SELECT a.AssessmentID, a.AssessmentType, a.MaxScore, a.WeightPercent,
       a.DueDate, a.DateUploaded,
       c.CourseCode, c.CourseTitle, e.Semester
  FROM Assessment a
  JOIN Course     c ON c.CourseID   = a.CourseID
  JOIN Enrollment e ON e.CourseID   = a.CourseID
 WHERE e.StudentID        = fn_current_student_id()
   AND e.EnrollmentStatus = 'Active';

-- Showing the learning materials for the logged-in student's active courses
CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_my_course_materials AS
SELECT m.MaterialID, m.MaterialTitle, m.FilePath, m.DateUploaded,
       c.CourseCode, c.CourseTitle, e.Semester
  FROM CourseMaterial m
  JOIN Course     c ON c.CourseID = m.CourseID
  JOIN Enrollment e ON e.CourseID = m.CourseID
 WHERE e.StudentID        = fn_current_student_id()
   AND e.EnrollmentStatus = 'Active';


-- Student view and function privileges
GRANT SELECT ON Group11_FinalProject.v_my_profile          TO student;
GRANT SELECT ON Group11_FinalProject.v_my_enrollments      TO student;
GRANT SELECT ON Group11_FinalProject.v_my_grades           TO student;
GRANT SELECT ON Group11_FinalProject.v_my_attendance       TO student;
GRANT SELECT ON Group11_FinalProject.v_my_assessments      TO student;
GRANT SELECT ON Group11_FinalProject.v_my_course_materials TO student;

GRANT EXECUTE ON FUNCTION Group11_FinalProject.fn_login              TO student;
GRANT EXECUTE ON FUNCTION Group11_FinalProject.fn_current_student_id TO student;



-- FUNCTIONALITIES ASSOCIATED WITH LECTURERS AND FACULTY INTERNS
-- Showing the courses assigned to the logged-in lectuer or faculty intern
CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_my_teaching AS
SELECT ta.AssignmentID, ta.CourseID, ta.Semester,
       c.CourseCode, c.CourseTitle, c.CreditHours,
       d.DeptCode, s.Role
  FROM Teaching_Assignment ta
  JOIN Course     c ON c.CourseID     = ta.CourseID
  JOIN Department d ON d.DepartmentID = c.DepartmentID
  JOIN Staff      s ON s.StaffID      = ta.AssigneeID
 WHERE ta.AssigneeID = fn_current_staff_id();

-- Showing the students enrolled in the lecturer's or faculty intern's courses
CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_class_list AS
SELECT e.EnrollmentID, e.StudentID, e.CourseID, e.Semester,
       e.EnrollmentDate, e.EnrollmentStatus,
       st.Fname, st.Lname, st.StudentEmail,
       c.CourseCode, c.CourseTitle
  FROM Enrollment e
  JOIN Student st ON st.StudentID = e.StudentID
  JOIN Course  c  ON c.CourseID   = e.CourseID
 WHERE fn_may_teach(e.CourseID, e.Semester);

-- Showing the grades for students in their assigned courses
CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_class_grades AS
SELECT g.GradeID, g.EnrollmentID, g.AssessmentID,
       g.ScoreObtained, g.DateRecorded,
       st.StudentID, st.Fname, st.Lname,
       a.AssessmentType, a.MaxScore, a.WeightPercent,
       c.CourseCode, e.Semester
  FROM Grade g
  JOIN Enrollment e  ON e.EnrollmentID = g.EnrollmentID
  JOIN Student    st ON st.StudentID   = e.StudentID
  JOIN Assessment a  ON a.AssessmentID = g.AssessmentID
  JOIN Course     c  ON c.CourseID     = e.CourseID
 WHERE fn_may_teach(e.CourseID, e.Semester);

-- Showing attendance for students in their assigned courses
CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_class_attendance AS
SELECT at.AttendanceID, at.EnrollmentID, at.SessionDate,
       at.AttendanceStatus,
       st.StudentID, st.Fname, st.Lname,
       c.CourseCode, e.Semester
  FROM Attendance at
  JOIN Enrollment e  ON e.EnrollmentID = at.EnrollmentID
  JOIN Student    st ON st.StudentID   = e.StudentID
  JOIN Course     c  ON c.CourseID     = e.CourseID
 WHERE fn_may_teach(e.CourseID, e.Semester);

-- Showing assessments for their assigned courses
CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_class_assessments AS
SELECT a.AssessmentID, a.CourseID, a.AssessmentType,
       a.MaxScore, a.WeightPercent, a.DueDate, a.DateUploaded,
       c.CourseCode, c.CourseTitle
  FROM Assessment a
  JOIN Course c ON c.CourseID = a.CourseID
 WHERE EXISTS (
         SELECT 1 FROM Teaching_Assignment ta
          WHERE ta.CourseID   = a.CourseID
            AND ta.AssigneeID = fn_current_staff_id());

-- Showing Course Materials for their assigned courses
CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_class_materials AS
SELECT m.MaterialID, m.CourseID, m.MaterialTitle,
       m.FilePath, m.DateUploaded,
       c.CourseCode, c.CourseTitle
  FROM CourseMaterial m
  JOIN Course c ON c.CourseID = m.CourseID
 WHERE EXISTS (
         SELECT 1 FROM Teaching_Assignment ta
          WHERE ta.CourseID   = m.CourseID
            AND ta.AssigneeID = fn_current_staff_id());


-- Lecturer and faculty intern privileges
GRANT SELECT ON Group11_FinalProject.v_my_teaching        TO lecturer, faculty_intern;
GRANT SELECT ON Group11_FinalProject.v_class_list         TO lecturer, faculty_intern;
GRANT SELECT ON Group11_FinalProject.v_class_grades       TO lecturer, faculty_intern;
GRANT SELECT ON Group11_FinalProject.v_class_attendance   TO lecturer, faculty_intern;
GRANT SELECT ON Group11_FinalProject.v_class_assessments  TO lecturer, faculty_intern;
GRANT SELECT ON Group11_FinalProject.v_class_materials    TO lecturer, faculty_intern;

GRANT EXECUTE ON FUNCTION Group11_FinalProject.fn_login               TO lecturer, faculty_intern;
GRANT EXECUTE ON FUNCTION Group11_FinalProject.fn_current_staff_id    TO lecturer, faculty_intern;
GRANT EXECUTE ON FUNCTION Group11_FinalProject.fn_may_teach           TO lecturer, faculty_intern;




-- Securing Grades, Attendance, and Course Material Procedures
DELIMITER $$

  -- Safely recording a student’s grade for an assigned course
DROP PROCEDURE IF EXISTS sp_secure_record_grade$$
CREATE DEFINER = 'lms_owner'@'localhost'
PROCEDURE sp_secure_record_grade(
    IN p_enrollment_id INT,
    IN p_assessment_id INT,
    IN p_score         DECIMAL(5,2))
  MODIFIES SQL DATA SQL SECURITY DEFINER
BEGIN
  DECLARE v_course   INT;
  DECLARE v_semester VARCHAR(10);
  DECLARE v_a_course INT;
  DECLARE v_max      DECIMAL(5,2);

  SELECT CourseID, Semester INTO v_course, v_semester
    FROM Enrollment WHERE EnrollmentID = p_enrollment_id;

  IF v_course IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No such enrollment.';
  END IF;
  IF NOT fn_may_teach(v_course, v_semester) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'You are not assigned to this course for this semester.';
  END IF;
  SELECT CourseID, MaxScore INTO v_a_course, v_max
    FROM Assessment WHERE AssessmentID = p_assessment_id;

  IF v_a_course IS NULL OR v_a_course <> v_course THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'That assessment does not belong to this course.';
  END IF;
  IF p_score < 0 OR p_score > v_max THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Score is outside the permitted range for this assessment.';
  END IF;

  
  INSERT INTO Grade (EnrollmentID, AssessmentID, ScoreObtained, DateRecorded)
  VALUES (p_enrollment_id, p_assessment_id, p_score, CURDATE())
  ON DUPLICATE KEY UPDATE
    ScoreObtained = p_score,
    DateRecorded  = CURDATE();
END$$

-- Safely recording a student’s attendance for an assigned course
DROP PROCEDURE IF EXISTS sp_secure_record_attendance$$
CREATE DEFINER = 'lms_owner'@'localhost'
PROCEDURE sp_secure_record_attendance(
    IN p_enrollment_id INT,
    IN p_session_date  DATE,
    IN p_status        VARCHAR(10))
  MODIFIES SQL DATA SQL SECURITY DEFINER
BEGIN
  DECLARE v_course   INT;
  DECLARE v_semester VARCHAR(10);

  SELECT CourseID, Semester INTO v_course, v_semester
    FROM Enrollment WHERE EnrollmentID = p_enrollment_id;

  IF v_course IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No such enrollment.';
  END IF;

  IF NOT fn_may_teach(v_course, v_semester) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'You are not assigned to this course for this semester.';
  END IF;

  IF p_status NOT IN ('Present','Absent') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Attendance status must be Present or Absent.';
  END IF;

  INSERT INTO Attendance (EnrollmentID, SessionDate, AttendanceStatus)
  VALUES (p_enrollment_id, p_session_date, p_status)
  ON DUPLICATE KEY UPDATE AttendanceStatus = p_status;
END$$

-- Safely adding a Course Material to an assigned course
DROP PROCEDURE IF EXISTS sp_secure_add_material$$
CREATE DEFINER = 'lms_owner'@'localhost'
PROCEDURE sp_secure_add_material(
    IN p_course_id INT,
    IN p_semester  VARCHAR(10),
    IN p_title     VARCHAR(150),
    IN p_file_path VARCHAR(255))
  MODIFIES SQL DATA SQL SECURITY DEFINER
BEGIN
  IF NOT fn_may_teach(p_course_id, p_semester) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'You are not assigned to this course for this semester.';
  END IF;

  INSERT INTO CourseMaterial (CourseID, MaterialTitle, FilePath, DateUploaded)
  VALUES (p_course_id, p_title, p_file_path, CURDATE());
END$$

DELIMITER ;


-- Procedure privileges
-- Gives the lecturers and faculty interns permission to use the secure grade, attendance and material procedures
GRANT EXECUTE ON PROCEDURE Group11_FinalProject.sp_secure_record_grade
  TO lecturer, faculty_intern;
GRANT EXECUTE ON PROCEDURE Group11_FinalProject.sp_secure_record_attendance
  TO lecturer, faculty_intern;
GRANT EXECUTE ON PROCEDURE Group11_FinalProject.sp_secure_add_material
  TO lecturer, faculty_intern;



-- Demonstration login accounts
-- Creates sample accounts for testing each role: admin, lecturer, intern, and student
CREATE USER IF NOT EXISTS 'lms_dba'@'localhost'
  IDENTIFIED BY 'ChangeMe_Dba#2026';
GRANT db_admin TO 'lms_dba'@'localhost';
SET DEFAULT ROLE db_admin FOR 'lms_dba'@'localhost';
CREATE USER IF NOT EXISTS 'kwame.mensah'@'%'
  IDENTIFIED BY 'ChangeMe_Lect#2026';
GRANT lecturer TO 'kwame.mensah'@'%';
SET DEFAULT ROLE lecturer FOR 'kwame.mensah'@'%';
CREATE USER IF NOT EXISTS 'michael.addo'@'%'
  IDENTIFIED BY 'ChangeMe_Intern#2026';
GRANT faculty_intern TO 'michael.addo'@'%';
SET DEFAULT ROLE faculty_intern FOR 'michael.addo'@'%';
CREATE USER IF NOT EXISTS 'ama.amoako'@'%'
  IDENTIFIED BY 'ChangeMe_Stu1#2026';
GRANT student TO 'ama.amoako'@'%';
SET DEFAULT ROLE student FOR 'ama.amoako'@'%';

CREATE USER IF NOT EXISTS 'kojo.appiah'@'%'
  IDENTIFIED BY 'ChangeMe_Stu2#2026';
GRANT student TO 'kojo.appiah'@'%';
SET DEFAULT ROLE student FOR 'kojo.appiah'@'%';

FLUSH PRIVILEGES;


-- Verification queries
-- Checks that the roles, permissions, and accounts were created correctly
SELECT User AS RoleName FROM mysql.user WHERE is_role = 'Y';

SHOW GRANTS FOR student;
SHOW GRANTS FOR lecturer;
SHOW GRANTS FOR faculty_intern;
SHOW GRANTS FOR db_admin;

SELECT User, Host, default_role FROM mysql.user WHERE is_role = 'N';


-- Password expiry and account limits
ALTER USER 'kwame.mensah'@'%'    PASSWORD EXPIRE INTERVAL 90 DAY;
ALTER USER 'michael.addo'@'%'    PASSWORD EXPIRE INTERVAL 90 DAY;
ALTER USER 'lms_dba'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;
ALTER USER 'ama.amoako'@'%'
  WITH MAX_QUERIES_PER_HOUR 1000 MAX_USER_CONNECTIONS 3;
ALTER USER 'kojo.appiah'@'%'
  WITH MAX_QUERIES_PER_HOUR 1000 MAX_USER_CONNECTIONS 3;
ALTER USER 'kwame.mensah'@'%'
  WITH MAX_QUERIES_PER_HOUR 5000 MAX_USER_CONNECTIONS 5;
ALTER USER 'michael.addo'@'%'
  WITH MAX_QUERIES_PER_HOUR 5000 MAX_USER_CONNECTIONS 5;


-- Password strength rules
INSTALL SONAME 'simple_password_check';

SET GLOBAL simple_password_check_minimal_length    = 12;
SET GLOBAL simple_password_check_digits            = 1;
SET GLOBAL simple_password_check_letters_same_case = 1;
SET GLOBAL simple_password_check_other_characters  = 1;

-- Secure procedure for lecturers and faculty interns to create assessments for their assigned courses
DROP PROCEDURE IF EXISTS sp_secure_create_assessment;
DELIMITER $$
CREATE DEFINER = 'lms_owner'@'localhost'
PROCEDURE sp_secure_create_assessment(
    IN p_course_id      INT,
    IN p_semester       VARCHAR(10),
    IN p_type           VARCHAR(20),
    IN p_max_score      DECIMAL(5,2),
    IN p_weight_percent DECIMAL(5,2),
    IN p_due_date       DATE)
  MODIFIES SQL DATA SQL SECURITY DEFINER
BEGIN
    IF NOT fn_may_teach(p_course_id, p_semester) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'You are not assigned to this course for this semester.';
    END IF;

    INSERT INTO Assessment (CourseID, AssessmentType, MaxScore, WeightPercent, DueDate, DateUploaded)
    VALUES (p_course_id, p_type, p_max_score, p_weight_percent, p_due_date, CURDATE());
END$$
DELIMITER ;
