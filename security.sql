/* =====================================================================
   GROUP 11 — School Learning Management System
   PHASE 7: SECURITY — User Roles, Privileges and Access Control
   Target: MariaDB 10.4+ (tested on 12.2)   Database: Group11_FinalProject
   =====================================================================

   WHAT THIS FILE DOES
   -------------------
   Creates the four user roles from the project brief and gives each one
   exactly the access it needs:

     db_admin        full control of the schema
     lecturer        view enrollments, grades, attendance and
                     assessments for the courses they teach
     faculty_intern  record grades and attendance for the course they
                     are assigned to
     student         view their own records only

   HOW TO RUN
   ----------
     mariadb -u root -p < schema_fixed.sql
     mariadb -u root -p < data.sql
     mariadb -u root -p < security.sql

   Re-running it is safe. Add --force if you want the client to carry on
   past the one statement that objects to being run twice (Section 11.2).

   NAMING — AVOIDING A CLASH WITH PHASE 6
   --------------------------------------
   Phase 6 also writes a procedure to record a grade. Every procedure
   here is prefixed sp_secure_ so the two do not overwrite each other.
   These are access-control wrappers, not the business procedures Phase 6
   is responsible for.

   TESTED
   ------
   Verified against MariaDB 12.2 with the Phase 4 schema and Phase 5
   data loaded. See Section 11 for the test commands and results.
   ================================================================== */

USE Group11_FinalProject;


/* =====================================================================
   SECTION 1 — SCHEMA OWNER
   =====================================================================
   The views and procedures below are all SQL SECURITY DEFINER: they run
   with the privileges of the account that created them, not the account
   that calls them. That is the mechanism that lets a student read their
   own grade without holding any privilege on the Grade table.

   A MariaDB role cannot be a DEFINER, so a dedicated user account owns
   them. Nobody logs in as this account — it is locked immediately.
   ================================================================== */

CREATE USER IF NOT EXISTS 'lms_owner'@'localhost'
  IDENTIFIED BY 'ChangeMe_Owner#2026';

GRANT ALL PRIVILEGES ON Group11_FinalProject.* TO 'lms_owner'@'localhost';

ALTER USER 'lms_owner'@'localhost' ACCOUNT LOCK;


/* =====================================================================
   SECTION 2 — THE FOUR ROLES
   =====================================================================
   Privileges are granted to roles, never directly to people. Adding a
   new lecturer next semester is then a single GRANT rather than a dozen.

   Note: MariaDB keeps roles and user accounts in the same table
   (mysql.user, distinguished by is_role). So no login account may be
   named 'student', 'lecturer' or 'faculty_intern'. Real accounts are
   named after the person, so this is not a practical restriction.
   ================================================================== */

DROP ROLE IF EXISTS db_admin;
DROP ROLE IF EXISTS lecturer;
DROP ROLE IF EXISTS faculty_intern;
DROP ROLE IF EXISTS student;

CREATE ROLE db_admin;
CREATE ROLE lecturer;
CREATE ROLE faculty_intern;
CREATE ROLE student;


/* =====================================================================
   SECTION 3 — db_admin
   =====================================================================
   Everything inside Group11_FinalProject, and nothing outside it. The
   administrator can manage this application completely without being
   able to read other databases on the same server.
   ================================================================== */

GRANT ALL PRIVILEGES ON Group11_FinalProject.* TO db_admin;

GRANT CREATE USER ON *.* TO db_admin;
GRANT RELOAD, PROCESS, SHOW DATABASES ON *.* TO db_admin;

GRANT LOCK TABLES, SELECT, SHOW VIEW, EVENT, TRIGGER
  ON Group11_FinalProject.* TO db_admin;
GRANT REPLICATION CLIENT ON *.* TO db_admin;


/* =====================================================================
   SECTION 4 — WHO IS ASKING?
   =====================================================================
   Every rule in this phase says "you may see YOUR records", so the
   database has to know which person a connection belongs to.

   MAPPING RULE
     The login name is the local part of the person's institutional
     email address.
        StudentEmail  ama.amoako@ashesi.edu.gh
        login         'ama.amoako'@'%'
     This works with the existing data unchanged. Both StudentEmail and
     StaffEmail are already UNIQUE, so the mapping cannot be ambiguous.

   SESSION_USER(), NOT CURRENT_USER()
     Inside a DEFINER routine, CURRENT_USER() returns the definer
     (lms_owner) rather than the caller. Using it here would make every
     student resolve to lms_owner and see nothing at all.
     SESSION_USER() always returns the account that actually connected.

   SEMESTER IS VARCHAR, NOT CHAR(1)
     The schema stores semester as VARCHAR(7) in the form '2026-S1'.
     An earlier draft of this file declared the semester parameters as
     CHAR(1), which failed at runtime with
         ERROR 1406 (22001): Data too long for column 'p_semester'
     All semester parameters and variables below are VARCHAR(10).
   ================================================================== */

DELIMITER $$

DROP FUNCTION IF EXISTS fn_login$$
CREATE DEFINER = 'lms_owner'@'localhost'
FUNCTION fn_login() RETURNS VARCHAR(100)
  DETERMINISTIC SQL SECURITY DEFINER
BEGIN
  RETURN SUBSTRING_INDEX(SESSION_USER(), '@', 1);
END$$


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


/* ---------------------------------------------------------------------
   fn_may_teach(CourseID, Semester)
   ---------------------------------------------------------------------
   TRUE when the caller appears in Teaching_Assignment for that course
   in that semester, whether as lecturer or as faculty intern.

   This one function is where BR3, BR5 and BR9 are enforced. Everything
   else in the file calls it rather than repeating the logic, so there
   is exactly one place to audit and one place to change.

   The semester is part of the test. An intern who assisted CS301 last
   semester loses access when the new semester's assignments are loaded,
   without anyone having to revoke anything.
   ------------------------------------------------------------------ */
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


/* =====================================================================
   SECTION 5 — REFERENCE DATA
   =====================================================================
   Department and Course carry no personal information — they are the
   institution's public catalogue. Readable by everyone, writable only
   by db_admin.
   ================================================================== */

GRANT SELECT ON Group11_FinalProject.Department
  TO lecturer, faculty_intern, student;
GRANT SELECT ON Group11_FinalProject.Course
  TO lecturer, faculty_intern, student;

/* Teaching_Assignment tells you who teaches what. Staff may see it in
   full; students get only the course and semester columns, not the
   staff assignment. Column-level GRANT is neater than a view here. */
GRANT SELECT ON Group11_FinalProject.Teaching_Assignment
  TO lecturer, faculty_intern;
GRANT SELECT (AssignmentID, CourseID, Semester)
  ON Group11_FinalProject.Teaching_Assignment TO student;


/* =====================================================================
   SECTION 6 — STUDENT ACCESS
   =====================================================================
   This is the part plain GRANT cannot express.

     GRANT SELECT ON Grade TO student;

   would let every student read every row of the Grade table — all
   thirty students' marks. GRANT works on tables, not rows, and MariaDB
   has no row-level security.

   So the base tables stay closed, and each student reads through a view
   that filters on their own identity. The same view returns different
   rows to different people.
   ================================================================== */

CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_my_profile AS
SELECT s.StudentID, s.Fname, s.Lname, s.StudentEmail, s.StudentPhone,
       d.DeptCode, d.DeptName
  FROM Student s
  JOIN Department d ON d.DepartmentID = s.DepartmentID
 WHERE s.StudentID = fn_current_student_id();


CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_my_enrollments AS
SELECT e.EnrollmentID, e.CourseID, e.Semester,
       e.EnrollmentDate, e.EnrollmentStatus,
       c.CourseCode, c.CourseTitle, c.CreditHours
  FROM Enrollment e
  JOIN Course c ON c.CourseID = e.CourseID
 WHERE e.StudentID = fn_current_student_id();


/* Grades for every course, including completed ones — Assumption 9 of
   Phase 1 says students keep access to past results. */
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


CREATE OR REPLACE
  DEFINER = 'lms_owner'@'localhost' SQL SECURITY DEFINER
VIEW v_my_attendance AS
SELECT at.AttendanceID, at.SessionDate, at.AttendanceStatus,
       c.CourseCode, c.CourseTitle, e.Semester
  FROM Attendance at
  JOIN Enrollment e ON e.EnrollmentID = at.EnrollmentID
  JOIN Course     c ON c.CourseID     = e.CourseID
 WHERE e.StudentID = fn_current_student_id();


/* Assessments only for courses the student is CURRENTLY enrolled in.
   The EnrollmentStatus filter is what makes BR10 true rather than
   merely intended: a student whose status changes to Inactive loses
   access immediately, with no revoke required. */
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


/* Course materials, same rule — BR10. */
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


/* ---- Student privileges: views only, never base tables ---------- */
GRANT SELECT ON Group11_FinalProject.v_my_profile          TO student;
GRANT SELECT ON Group11_FinalProject.v_my_enrollments      TO student;
GRANT SELECT ON Group11_FinalProject.v_my_grades           TO student;
GRANT SELECT ON Group11_FinalProject.v_my_attendance       TO student;
GRANT SELECT ON Group11_FinalProject.v_my_assessments      TO student;
GRANT SELECT ON Group11_FinalProject.v_my_course_materials TO student;

GRANT EXECUTE ON FUNCTION Group11_FinalProject.fn_login              TO student;
GRANT EXECUTE ON FUNCTION Group11_FinalProject.fn_current_student_id TO student;


/* =====================================================================
   SECTION 7 — LECTURER AND FACULTY INTERN — READ ACCESS
   =====================================================================
   Same technique, different filter: instead of "my student id", the
   test is "this course, this semester, is mine".
   ================================================================== */

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


/* ---------------------------------------------------------------------
   Assessment and CourseMaterial hang off Course only — they carry no
   semester of their own. So "is this mine?" has to mean "am I assigned
   to this course in any semester?", tested directly against
   Teaching_Assignment.

   An earlier draft called fn_may_teach(CourseID, '1') and (..., '2')
   with the semester written in as a literal. That did not error, it
   just silently returned nothing once the semester format changed to
   '2026-S1' — a worse failure than an error, because it looks like the
   staff member simply has no assessments.

   The underlying modelling question — that an assessment cannot be
   distinguished between semesters — is raised in the Phase 7 document
   as a matter for the group rather than something changed here.
   ------------------------------------------------------------------ */
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


GRANT SELECT ON Group11_FinalProject.v_my_teaching        TO lecturer, faculty_intern;
GRANT SELECT ON Group11_FinalProject.v_class_list         TO lecturer, faculty_intern;
GRANT SELECT ON Group11_FinalProject.v_class_grades       TO lecturer, faculty_intern;
GRANT SELECT ON Group11_FinalProject.v_class_attendance   TO lecturer, faculty_intern;
GRANT SELECT ON Group11_FinalProject.v_class_assessments  TO lecturer, faculty_intern;
GRANT SELECT ON Group11_FinalProject.v_class_materials    TO lecturer, faculty_intern;

GRANT EXECUTE ON FUNCTION Group11_FinalProject.fn_login               TO lecturer, faculty_intern;
GRANT EXECUTE ON FUNCTION Group11_FinalProject.fn_current_staff_id    TO lecturer, faculty_intern;
GRANT EXECUTE ON FUNCTION Group11_FinalProject.fn_may_teach           TO lecturer, faculty_intern;


/* =====================================================================
   SECTION 8 — WRITE ACCESS
   =====================================================================
   The faculty intern must INSERT and UPDATE grades and attendance —
   but only for their assigned course.

   A view cannot do this. Views built on JOINs are not updatable in
   MariaDB, so there is no v_class_grades to INSERT into. Writes
   therefore go through procedures that check the caller's assignment
   before touching anything, while the base tables stay closed.

   This also gives one place to enforce the score limit at entry.
   ================================================================== */

DELIMITER $$

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

  -- BR5: the caller must be assigned to this course this semester
  IF NOT fn_may_teach(v_course, v_semester) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'You are not assigned to this course for this semester.';
  END IF;

  -- The assessment must belong to the same course
  SELECT CourseID, MaxScore INTO v_a_course, v_max
    FROM Assessment WHERE AssessmentID = p_assessment_id;

  IF v_a_course IS NULL OR v_a_course <> v_course THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'That assessment does not belong to this course.';
  END IF;

  -- Score must be within range
  IF p_score < 0 OR p_score > v_max THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Score is outside the permitted range for this assessment.';
  END IF;

  /* One grade per student per assessment. Relies on
     UNIQUE (EnrollmentID, AssessmentID) on Grade. Without that
     constraint this INSERT creates a duplicate row instead of
     correcting the existing one. */
  INSERT INTO Grade (EnrollmentID, AssessmentID, ScoreObtained, DateRecorded)
  VALUES (p_enrollment_id, p_assessment_id, p_score, CURDATE())
  ON DUPLICATE KEY UPDATE
    ScoreObtained = p_score,
    DateRecorded  = CURDATE();
END$$


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


DROP PROCEDURE IF EXISTS sp_secure_add_material$$
CREATE DEFINER = 'lms_owner'@'localhost'
PROCEDURE sp_secure_add_material(
    IN p_course_id INT,
    IN p_semester  VARCHAR(10),
    IN p_title     VARCHAR(150),
    IN p_file_path VARCHAR(255))
  MODIFIES SQL DATA SQL SECURITY DEFINER
BEGIN
  -- BR9: upload only for your own course
  IF NOT fn_may_teach(p_course_id, p_semester) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'You are not assigned to this course for this semester.';
  END IF;

  INSERT INTO CourseMaterial (CourseID, MaterialTitle, FilePath, DateUploaded)
  VALUES (p_course_id, p_title, p_file_path, CURDATE());
END$$

DELIMITER ;

GRANT EXECUTE ON PROCEDURE Group11_FinalProject.sp_secure_record_grade
  TO lecturer, faculty_intern;
GRANT EXECUTE ON PROCEDURE Group11_FinalProject.sp_secure_record_attendance
  TO lecturer, faculty_intern;
GRANT EXECUTE ON PROCEDURE Group11_FinalProject.sp_secure_add_material
  TO lecturer, faculty_intern;

/* What is deliberately NOT granted below db_admin:
     - DELETE on any table. Academic records are not destroyed by
       teaching staff. A withdrawal is a status change on Enrollment.
     - Any privilege at all on the base Grade, Attendance, Enrollment,
       Student or CourseMaterial tables.
     - Any privilege on Staff. Nobody but the administrator reads the
       staff table, so nobody can enumerate colleagues' contact details. */


/* =====================================================================
   SECTION 9 — LOGIN ACCOUNTS
   =====================================================================
   Demonstration accounts built from the real people in data.sql.
   Passwords are placeholders and must be changed before any real use.

   The two-step pattern matters in MariaDB:
       GRANT <role> TO <user>          makes the role available
       SET DEFAULT ROLE <role> FOR ..  activates it on connect

   Without the second statement the role stays dormant, the user has to
   type SET ROLE every session, and it looks as though the grants did
   not work. Note MariaDB uses FOR here; MySQL 8 uses TO.
   ================================================================== */

-- Administrator
CREATE USER IF NOT EXISTS 'lms_dba'@'localhost'
  IDENTIFIED BY 'ChangeMe_Dba#2026';
GRANT db_admin TO 'lms_dba'@'localhost';
SET DEFAULT ROLE db_admin FOR 'lms_dba'@'localhost';

-- Lecturer — Kwame Mensah, StaffID 1
CREATE USER IF NOT EXISTS 'kwame.mensah'@'%'
  IDENTIFIED BY 'ChangeMe_Lect#2026';
GRANT lecturer TO 'kwame.mensah'@'%';
SET DEFAULT ROLE lecturer FOR 'kwame.mensah'@'%';

-- Faculty intern — Michael Addo, StaffID 5
CREATE USER IF NOT EXISTS 'michael.addo'@'%'
  IDENTIFIED BY 'ChangeMe_Intern#2026';
GRANT faculty_intern TO 'michael.addo'@'%';
SET DEFAULT ROLE faculty_intern FOR 'michael.addo'@'%';

-- Students — Ama Amoako (StudentID 1) and Kojo Appiah (StudentID 2),
-- both enrolled in CS101, both graded on the same quiz. They make the
-- clearest possible demonstration: identical query, different results.
CREATE USER IF NOT EXISTS 'ama.amoako'@'%'
  IDENTIFIED BY 'ChangeMe_Stu1#2026';
GRANT student TO 'ama.amoako'@'%';
SET DEFAULT ROLE student FOR 'ama.amoako'@'%';

CREATE USER IF NOT EXISTS 'kojo.appiah'@'%'
  IDENTIFIED BY 'ChangeMe_Stu2#2026';
GRANT student TO 'kojo.appiah'@'%';
SET DEFAULT ROLE student FOR 'kojo.appiah'@'%';

FLUSH PRIVILEGES;


/* =====================================================================
   SECTION 10 — VERIFICATION
   ================================================================== */

SELECT User AS RoleName FROM mysql.user WHERE is_role = 'Y';

SHOW GRANTS FOR student;
SHOW GRANTS FOR lecturer;
SHOW GRANTS FOR faculty_intern;
SHOW GRANTS FOR db_admin;

SELECT User, Host, default_role FROM mysql.user WHERE is_role = 'N';


/* ---------------------------------------------------------------------
   TEST RESULTS — run against MariaDB 12.2
   ---------------------------------------------------------------------
   1. Student sees only their own grade
      mariadb -u ama.amoako -p Group11_FinalProject
        SELECT * FROM v_my_grades;
      -> 1 row: GradeID 1, 16.00, Quiz, CS101, 80.00%          PASS

   2. A different student, identical query, different row
      mariadb -u kojo.appiah -p Group11_FinalProject
        SELECT * FROM v_my_grades;
      -> 1 row: GradeID 2, 14.00, Quiz, CS101, 70.00%          PASS

   3. Student cannot reach the base table
      mariadb -u ama.amoako -p Group11_FinalProject
        SELECT * FROM Grade;
      -> ERROR 1142 (42000): SELECT command denied to user
         'ama.amoako'@'localhost' for table 'grade'            PASS

   4. Faculty intern sees only their assigned class
      mariadb -u michael.addo -p Group11_FinalProject
        SELECT * FROM v_class_list;
      -> 4 rows, all CS301 in 2026-S1, out of 30 enrollments  PASS

   5. Faculty intern refused on another lecturer's course
      mariadb -u michael.addo -p Group11_FinalProject
        CALL sp_secure_record_grade(1, 1, 18);
      -> ERROR 1644 (45000): You are not assigned to this
         course for this semester.                           PASS

   All five confirmed. Two students running a character-for-character
   identical query and receiving different rows is the clearest possible
   demonstration that row-level filtering works. Test 5 is the same idea
   on the write side, and the refusal comes from the database rather than
   from application code.
   ------------------------------------------------------------------ */

/* =====================================================================
   SECTION 11 — PASSWORD AND ACCOUNT POLICY
   =====================================================================
   This section is LAST on purpose. INSTALL SONAME has no IF NOT EXISTS
   in MariaDB, so on a second run it raises

       ERROR 1125 (HY000): Function 'simple_password_check'
                           already exists

   and the mariadb client, reading a file in batch mode, stops at the
   first error. Anything after it would never run. Placed here, an abort
   costs nothing - every other statement in the file has already run.

   Within the section the same rule applies: the ALTER USER statements
   come before INSTALL SONAME, so they always take effect.

   To re-run the whole file without stopping:
       mariadb -u root -p --force < security.sql
   ================================================================== */

/* ---- 11.1  Expiry and resource limits ---------------------------- */

-- Staff and administrator passwords expire quarterly.
ALTER USER 'kwame.mensah'@'%'    PASSWORD EXPIRE INTERVAL 90 DAY;
ALTER USER 'michael.addo'@'%'    PASSWORD EXPIRE INTERVAL 90 DAY;
ALTER USER 'lms_dba'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;

-- Cap resource use on every account, so one runaway client cannot
-- starve the server. Staff limits are higher: they read whole classes.
ALTER USER 'ama.amoako'@'%'
  WITH MAX_QUERIES_PER_HOUR 1000 MAX_USER_CONNECTIONS 3;
ALTER USER 'kojo.appiah'@'%'
  WITH MAX_QUERIES_PER_HOUR 1000 MAX_USER_CONNECTIONS 3;
ALTER USER 'kwame.mensah'@'%'
  WITH MAX_QUERIES_PER_HOUR 5000 MAX_USER_CONNECTIONS 5;
ALTER USER 'michael.addo'@'%'
  WITH MAX_QUERIES_PER_HOUR 5000 MAX_USER_CONNECTIONS 5;

/* KNOWN GAP - no automatic lockout after repeated failed logins.
   MySQL 8 has FAILED_LOGIN_ATTEMPTS / PASSWORD_LOCK_TIME; MariaDB has
   no equivalent (MDEV-7598 is still open). Brute-force throttling must
   happen outside the database - in the Flask application, or with
   fail2ban watching the server log. Recorded here rather than left
   silent. An account can still be locked manually:
       ALTER USER 'ama.amoako'@'%' ACCOUNT LOCK;                     */


/* ---- 11.2  Password strength ------------------------------------- */
/* Enforced by the server, so the rules apply however a password is set,
   including passwords changed later by the users themselves.

   To survive a restart this also has to go in my.cnf:
       [mariadb]
       plugin_load_add = simple_password_check

   If the next statement errors with 1125, the plugin is already loaded
   and the four settings below are already in force. Nothing is wrong. */

INSTALL SONAME 'simple_password_check';

SET GLOBAL simple_password_check_minimal_length    = 12;
SET GLOBAL simple_password_check_digits            = 1;
SET GLOBAL simple_password_check_letters_same_case = 1;
SET GLOBAL simple_password_check_other_characters  = 1;


/* =====================================================================
   END OF PHASE 7
   ================================================================== */
