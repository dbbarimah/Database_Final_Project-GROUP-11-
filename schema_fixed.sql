CREATE DATABASE IF NOT EXISTS Group11_FinalProject;
USE Group11_FinalProject;

CREATE TABLE Department(
    DepartmentID INT PRIMARY KEY AUTO_INCREMENT,
    DeptCode VARCHAR(10) NOT NULL UNIQUE,
    DeptName VARCHAR(100) NOT NULL
);

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

ALTER TABLE Department
    ADD COLUMN HeadID INT,
    ADD FOREIGN KEY (HeadID) REFERENCES Staff(StaffID);

CREATE TABLE Student(
    StudentID INT PRIMARY KEY AUTO_INCREMENT,
    Fname VARCHAR(50) NOT NULL,
    Lname VARCHAR(50) NOT NULL,
    StudentPhone VARCHAR(10),
    StudentEmail VARCHAR(100) NOT NULL UNIQUE,
    DepartmentID INT NOT NULL,
    FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID)
);

CREATE TABLE Course(
    CourseID INT AUTO_INCREMENT PRIMARY KEY,
    CourseCode VARCHAR(10) NOT NULL UNIQUE,
    CourseTitle VARCHAR(150) NOT NULL,
    CreditHours DECIMAL(5,2) NOT NULL,
    DepartmentID INT NOT NULL,
    FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID)
);

CREATE TABLE Teaching_Assignment(
    AssignmentID INT PRIMARY KEY AUTO_INCREMENT,
    CourseID INT NOT NULL,
    AssigneeID INT NOT NULL,
    Semester CHAR(1) NOT NULL CHECK (Semester IN ('1','2')),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    FOREIGN KEY (AssigneeID) REFERENCES Staff(StaffID)
);

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

CREATE TABLE Attendance(
    AttendanceID INT PRIMARY KEY AUTO_INCREMENT,
    EnrollmentID INT NOT NULL,
    SessionDate DATE NOT NULL,
    AttendanceStatus VARCHAR(10) CHECK (AttendanceStatus IN ('Present','Absent')),
    FOREIGN KEY (EnrollmentID) REFERENCES Enrollment(EnrollmentID)
);

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

CREATE TABLE Grade(
    GradeID INT PRIMARY KEY AUTO_INCREMENT,
    EnrollmentID INT NOT NULL,
    AssessmentID INT NOT NULL,
    ScoreObtained DECIMAL(5,2) NOT NULL CHECK (ScoreObtained >= 0),
    DateRecorded DATE NOT NULL,
    FOREIGN KEY (EnrollmentID) REFERENCES Enrollment(EnrollmentID),
    FOREIGN KEY (AssessmentID) REFERENCES Assessment(AssessmentID)
);
