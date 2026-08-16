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



