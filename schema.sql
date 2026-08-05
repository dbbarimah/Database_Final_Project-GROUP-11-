/* The purpose of this file is to create the tables of the database (Phase 4).
Enforce constraints
Add indexes
Add sequences
*/


MariaDB [(none)]> USE Group11_FinalProject;
Database changed

  
MariaDB [Group11_FinalProject]> CREATE TABLE DEPARTMENT(
    -> DepartmentID INT PRIMARY KEY AUTO_INCREMENT,
    -> DeptCode VARCHAR(10) NOT NULL UNIQUE,
    -> DeptName VARCHAR(100) NOT NULL
    -> );
Query OK, 0 rows affected (0.035 sec)

  
MariaDB [Group11_FinalProject]> CREATE TABLE STAFF(
    -> StaffID INT AUTO_INCREMENT PRIMARY KEY,
    -> Fname VARCHAR(50) NOT NULL,
    -> Lname VARCHAR(50) NOT NULL,
    -> StaffEmail VARCHAR(100) NOT NULL UNIQUE,
    -> StaffPhone VARCHAR(10),
    -> Role VARCHAR(20) NOT NULL,
    -> DepartmentID INT NOT NULL,
    -> FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID)
    -> );
Query OK, 0 rows affected (0.028 sec)


MariaDB [Group11_FinalProject]> ALTER TABLE Department
    -> ADD COLUMN HeadID INT,
    -> ADD FOREIGN KEY (HeadID) REFERENCES Staff(StaffID);
Query OK, 0 rows affected (0.050 sec)              
Records: 0  Duplicates: 0  Warnings: 0

  
MariaDB [Group11_FinalProject]> CREATE TABLE STUDENT(
    -> StudentID INT PRIMARY KEY AUTO_INCREMENT,
    -> Fname VARCHAR(50) NOT NULL,
    -> Lname VARCHAR(50) NOT NULL,
    -> StudentPhone VARCHAR(10),
    -> StudentEmail VARCHAR(100) NOT NULL UNIQUE,
    -> DepartmentID INT NOT NULL,
    -> FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID)
    -> );
Query OK, 0 rows affected (0.027 sec)


MariaDB [Group11_FinalProject]> CREATE TABLE COURSE(                                                         -> CourseID INT AUTO_INCREMENT PRIMARY KEY,                                                              -> CourseCode VARCHAR(10) NOT NULL UNIQUE,
    -> CourseTitle VARCHAR(150) NOT NULL,
    -> CreditHours DECIMAL(5,2) NOT NULL,
    -> DepartmentID INT NOT NULL,
    -> FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID)                                        -> );
Query OK, 0 rows affected (0.032 sec)


MariaDB [Group11_FinalProject]> CREATE TABLE Teaching_Assignment(
    -> AssignmentID INT PRIMARY KEY AUTO_INCREMENT,
    -> CourseID INT NOT NULL,
    -> AssigneeID INT NOT NULL,
    -> Semester CHAR(1)  NOT NULL CHECK (Semester IN ('1','2')),
    -> FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    -> FOREIGN KEY (AssigneeID) REFERENCES Staff(StaffID)
    -> );
Query OK, 0 rows affected (0.030 sec)

MariaDB [Group11_FinalProject]> CREATE TABLE Enrollment(
    -> EnrollmentID INT PRIMARY KEY AUTO_INCREMENT, 
    -> CourseID INT NOT NULL,
    -> Semester CHAR(1) NOT NULL CHECK(Semester IN ('1','2')),
    -> EnrollmentDate DATE NOT NULL,
    -> EnrollmentStatus VARCHAR(5) NOT NULL,
    -> FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
    -> );
Query OK, 0 rows affected (0.033 sec)

  
MariaDB [Group11_FinalProject]> CREATE TABLE ATTENDANCE(                                                     -> AttendanceID INT PRIMARY KEY AUTO_INCREMENT,
    -> EnrollmentID INT NOT NULL,
    -> SessionDate DATE NOT NULL,
    -> AttendanceStatus VARCHAR(10) CHECK (AttendanceStatus IN ('Present','Absent')),                        -> FOREIGN KEY (EnrollmentID) REFERENCES Enrollment(EnrollmentID)
    -> );
Query OK, 0 rows affected (0.026 sec)


MariaDB [Group11_FinalProject]> CREATE TABLE ASSESSMENT(
    -> AssessmentID INT PRIMARY KEY AUTO_INCREMENT,
    -> CourseID INT NOT NULL,
    -> AssessmentType VARCHAR(20) NOT NULL CHECK(AssessmentType IN ('Quiz','Assignment','MidSemester','Exam')),
    -> MaxScore DECIMAL(5,2) NOT NULL CHECK (MaxScore > 0),
    -> WeightPercent DECIMAL(5,2) NOT NULL CHECK (WeightPercent BETWEEN 0 AND 100),
    -> DueDate DATE,
    -> DateUploaded DATE NOT NULL
    -> FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
    -> );
Query OK, 0 rows affected (0.030 sec)

  
MariaDB [Group11_FinalProject]> CREATE TABLE GRADE(
    -> GradeID INT PRIMARY KEY AUTO_INCREMENT,
    -> EnrollmentID INT NOT NULL,
    -> AssessmentID INT NOT NULL,
    -> ScoreObtained DECIMAL(5,2) NOT NULL CHECK (ScoreObtained >= 0),
    -> DateRecorded DATE NOT NULL
    -> );
Query OK, 0 rows affected (0.028 sec)

