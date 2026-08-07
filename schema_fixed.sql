/* The purpose of this file is to define the SQL Data Definition Language
to create the tables, contraints, indexes, and sequences/idenity columns 
(Phase 4)*/

-- Creating the Database
CREATE DATABASE IF NOT EXISTS Group11_FinalProject;
USE Group11_FinalProject;

-- Creating the Department Table
CREATE TABLE Department(
    DepartmentID INT PRIMARY KEY AUTO_INCREMENT,
    DeptCode VARCHAR(10) NOT NULL UNIQUE,
    DeptName VARCHAR(100) NOT NULL
);

-- Creating the Staff Table
CREATE TABLE Staff(
    StaffID INT AUTO_INCREMENT PRIMARY KEY,
    Fname VARCHAR(50) NOT NULL,
    Lname VARCHAR(50) NOT NULL,
    StaffEmail VARCHAR(100) NOT NULL UNIQUE,
    StaffPhone VARCHAR(10),
    Role VARCHAR(20) NOT NULL,
    DepartmentID INT NOT NULL,
    FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID)
);

-- Altering the Department Table to contain the Heads of Department who also serve as Staff
ALTER TABLE Department
    ADD COLUMN HeadID INT,
    ADD FOREIGN KEY (HeadID) REFERENCES Staff(StaffID);

-- Creating the Student Table
CREATE TABLE Student(
    StudentID INT PRIMARY KEY AUTO_INCREMENT,
    Fname VARCHAR(50) NOT NULL,
    Lname VARCHAR(50) NOT NULL,
    StudentPhone VARCHAR(10),
    StudentEmail VARCHAR(100) NOT NULL UNIQUE,
    DepartmentID INT NOT NULL,
    FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID)
);

-- Creating the Course Table
CREATE TABLE Course(
    CourseID INT AUTO_INCREMENT PRIMARY KEY,
    CourseCode VARCHAR(10) NOT NULL UNIQUE,
    CourseTitle VARCHAR(150) NOT NULL,
    CreditHours DECIMAL(5,2) NOT NULL,
    DepartmentID INT NOT NULL,
    FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID)
);

-- Creating the Teaching_Assignment Table
CREATE TABLE Teaching_Assignment(
    AssignmentID INT PRIMARY KEY AUTO_INCREMENT,
    CourseID INT NOT NULL,
    AssigneeID INT NOT NULL,
    Semester CHAR(1) NOT NULL CHECK (Semester IN ('1','2')),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    FOREIGN KEY (AssigneeID) REFERENCES Staff(StaffID)
);

-- Creating the Enrollment Table
CREATE TABLE Enrollment(
    EnrollmentID INT PRIMARY KEY AUTO_INCREMENT,
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    Semester CHAR(1) NOT NULL CHECK (Semester IN ('1','2')),
    EnrollmentDate DATE NOT NULL,
    EnrollmentStatus VARCHAR(10) NOT NULL,
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);

-- Creating the Attendance Table
CREATE TABLE Attendance(
    AttendanceID INT PRIMARY KEY AUTO_INCREMENT,
    EnrollmentID INT NOT NULL,
    SessionDate DATE NOT NULL,
    AttendanceStatus VARCHAR(10) CHECK (AttendanceStatus IN ('Present','Absent')),
    FOREIGN KEY (EnrollmentID) REFERENCES Enrollment(EnrollmentID)
);

-- Creating the Assessment Table
CREATE TABLE Assessment(
    AssessmentID INT PRIMARY KEY AUTO_INCREMENT,
    CourseID INT NOT NULL,
    AssessmentType VARCHAR(20) NOT NULL CHECK (AssessmentType IN ('Quiz','Assignment','MidSemester','Exam')),
    MaxScore DECIMAL(5,2) NOT NULL CHECK (MaxScore > 0),
    WeightPercent DECIMAL(5,2) NOT NULL CHECK (WeightPercent BETWEEN 0 AND 100),
    DueDate DATE,
    DateUploaded DATE NOT NULL,
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);

-- Creating the Grade Table
CREATE TABLE Grade(
    GradeID INT PRIMARY KEY AUTO_INCREMENT,
    EnrollmentID INT NOT NULL,
    AssessmentID INT NOT NULL,
    ScoreObtained DECIMAL(5,2) NOT NULL CHECK (ScoreObtained >= 0),
    DateRecorded DATE NOT NULL,
    FOREIGN KEY (EnrollmentID) REFERENCES Enrollment(EnrollmentID),
    FOREIGN KEY (AssessmentID) REFERENCES Assessment(AssessmentID)
);

-- Sequences for the Tables
-- Student Table
CREATE INDEX idx_student_department ON Student(DepartmentID);

-- Staff Table
CREATE INDEX idx_staff_department ON Staff(DepartmentID);

-- Course Table
CREATE INDEX idx_course_department ON Course(DepartmentID);

-- Teaching_Assignment Table
CREATE INDEX idx_teaching_course ON Teaching_Assignment(CourseID);
CREATE INDEX idx_teaching_assignee ON Teaching_Assignment(AssigneeID);

-- Enrollment Table
CREATE INDEX idx_enrollment_student ON Enrollment(StudentID);
CREATE INDEX idx_enrollment_course ON Enrollment(CourseID);

-- Attendance Table
CREATE INDEX idx_attendance_enrollment ON Attendance(EnrollmentID);

-- Assessment Table
CREATE INDEX idx_assessment_course ON Assessment(CourseID);

-- Grade Table
CREATE INDEX idx_grade_enrollment ON Grade(EnrollmentID);
CREATE INDEX idx_grade_assessment ON Grade(AssessmentID);
