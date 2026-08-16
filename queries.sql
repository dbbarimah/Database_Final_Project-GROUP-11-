USE Group11_FinalProject;

/* The purpose of this file is to implement the advanced SQL queries (Phase 6)
10 advanced queries
5 views
3 stored procedures
2 user-defined functions
3 triggers implemeneting business rules
*/

-- 10 Advanced Queries
-- Query 1: List of all students enrolled in a specific course for a specific semester
SELECT
    s.StudentID,
    s.Fname,
    s.Lname,
    c.CourseCode,
    c.CourseTitle,
    e.Semester,
    e.EnrollmentStatus
FROM Enrollment e
JOIN Student s ON s.StudentID = e.StudentID
JOIN Course c ON c.CourseID = e.CourseID
WHERE e.CourseID = 3
  AND e.Semester = '2026-S1'
ORDER BY s.Lname, s.Fname;


-- Query 2: List all courses with their assigned lecturer and faculty intern for each semester
SELECT
    c.CourseCode,
    c.CourseTitle,
    ta.Semester,
    st.Fname,
    st.Lname,
    st.Role
FROM Teaching_Assignment ta
JOIN Course c ON c.CourseID = ta.CourseID
JOIN Staff st ON st.StaffID = ta.AssigneeID
ORDER BY ta.Semester, c.CourseCode, st.Role;


-- Query 3: Get the weighted average score for each student in each course
SELECT
    s.StudentID,
    s.Fname,
    s.Lname,
    c.CourseCode,
    c.CourseTitle,
    e.Semester,
    ROUND(SUM((g.ScoreObtained / a.MaxScore) * a.WeightPercent), 2) AS WeightedAverage
FROM Enrollment e
JOIN Student s ON s.StudentID = e.StudentID
JOIN Course c ON c.CourseID = e.CourseID
JOIN Grade g ON g.EnrollmentID = e.EnrollmentID
JOIN Assessment a ON a.AssessmentID = g.AssessmentID
GROUP BY e.EnrollmentID, s.StudentID, s.Fname, s.Lname, c.CourseCode, c.CourseTitle, e.Semester
ORDER BY e.Semester, c.CourseCode;


-- Query 4: Find students with an attendance rate below 60% in any course
SELECT
    s.StudentID,
    s.Fname,
    s.Lname,
    c.CourseCode,
    c.CourseTitle,
    ROUND(100 * SUM(CASE WHEN att.AttendanceStatus = 'Present' THEN 1 ELSE 0 END) / COUNT(att.AttendanceID), 2) AS AttendanceRate
FROM Enrollment e
JOIN Student s ON s.StudentID = e.StudentID
JOIN Course c ON c.CourseID = e.CourseID
JOIN Attendance att ON att.EnrollmentID = e.EnrollmentID
GROUP BY e.EnrollmentID, s.StudentID, s.Fname, s.Lname, c.CourseCode, c.CourseTitle
HAVING AttendanceRate < 60
ORDER BY AttendanceRate;


-- Query 5: Count the number of assessments per course and their total weight
SELECT
    c.CourseCode,
    c.CourseTitle,
    COUNT(a.AssessmentID) AS TotalAssessments,
    SUM(a.WeightPercent) AS TotalWeight
FROM Course c
JOIN Assessment a ON a.CourseID = c.CourseID
GROUP BY c.CourseID, c.CourseCode, c.CourseTitle
ORDER BY c.CourseCode;


-- Query 6: Find the top scoring student per course based on weighted average
SELECT
    c.CourseCode,
    c.CourseTitle,
    s.Fname,
    s.Lname,
    ROUND(SUM((g.ScoreObtained / a.MaxScore) * a.WeightPercent), 2) AS WeightedAverage
FROM Enrollment e
JOIN Student s ON s.StudentID = e.StudentID
JOIN Course c ON c.CourseID = e.CourseID
JOIN Grade g ON g.EnrollmentID = e.EnrollmentID
JOIN Assessment a ON a.AssessmentID = g.AssessmentID
GROUP BY e.EnrollmentID, c.CourseID, c.CourseCode, c.CourseTitle, s.Fname, s.Lname
HAVING WeightedAverage = (
    SELECT ROUND(SUM((g2.ScoreObtained / a2.MaxScore) * a2.WeightPercent), 2)
    FROM Enrollment e2
    JOIN Grade g2 ON g2.EnrollmentID = e2.EnrollmentID
    JOIN Assessment a2 ON a2.AssessmentID = g2.AssessmentID
    WHERE e2.CourseID = c.CourseID
    GROUP BY e2.EnrollmentID
    ORDER BY 1 DESC
    LIMIT 1
)
ORDER BY c.CourseCode;


-- Query 7: List all courses and the course materials uploaded for them
SELECT
    c.CourseCode,
    c.CourseTitle,
    COALESCE(cm.MaterialTitle, 'No materials uploaded') AS MaterialTitle,
    cm.DateUploaded
FROM Course c
LEFT JOIN CourseMaterial cm ON cm.CourseID = c.CourseID
ORDER BY c.CourseCode, cm.DateUploaded;


-- Query 8: Show the number of courses each faculty intern is assigned to and the course details
SELECT
    st.StaffID,
    st.Fname,
    st.Lname,
    c.CourseCode,
    c.CourseTitle,
    ta.Semester
FROM Teaching_Assignment ta
JOIN Staff st ON st.StaffID = ta.AssigneeID
JOIN Course c ON c.CourseID = ta.CourseID
WHERE st.Role = 'Faculty Intern'
ORDER BY st.Lname, ta.Semester;


-- Query 9: List students who have not submitted a specific assessment (no grade recorded)
SELECT
    s.StudentID,
    s.Fname,
    s.Lname,
    c.CourseCode,
    a.AssessmentType,
    a.DueDate
FROM Enrollment e
JOIN Student s ON s.StudentID = e.StudentID
JOIN Course c ON c.CourseID = e.CourseID
JOIN Assessment a ON a.CourseID = e.CourseID
WHERE a.AssessmentID = 1
  AND NOT EXISTS (
      SELECT 1 FROM Grade g
      WHERE g.EnrollmentID = e.EnrollmentID
        AND g.AssessmentID = a.AssessmentID
  )
ORDER BY s.Lname, s.Fname;


-- Query 10: Show the full grade breakdown for each student per course listing each assessment score
SELECT
    s.StudentID,
    s.Fname,
    s.Lname,
    c.CourseCode,
    c.CourseTitle,
    a.AssessmentType,
    g.ScoreObtained,
    a.MaxScore,
    a.WeightPercent,
    ROUND((g.ScoreObtained / a.MaxScore) * a.WeightPercent, 2) AS WeightedScore
FROM Grade g
JOIN Enrollment e ON e.EnrollmentID = g.EnrollmentID
JOIN Student s ON s.StudentID = e.StudentID
JOIN Course c ON c.CourseID = e.CourseID
JOIN Assessment a ON a.AssessmentID = g.AssessmentID
ORDER BY s.Lname, c.CourseCode, a.AssessmentType;




