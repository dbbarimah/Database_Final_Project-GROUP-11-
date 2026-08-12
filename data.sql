/* The purpose of this file is to enter the queries to insert the data after
the tables have been created (Phase 5)
At least 30 entries for the major tables.
Does not need to be real or existing data.

NOTE: Semester values updated to the 'YYYY-S1'/'YYYY-S2' format required by
the CHECK constraint in the current schema.sql (Semester REGEXP '^[0-9]{4}-S[12]$').
The old CHAR(1) '1'/'2' values ('S1' = Jan-ish dates, 'S2' = Jun/Jul-onward
dates below) have been mapped to '2026-S1' and '2026-S2' respectively.
*/
USE Group11_FinalProject;

-- Inserting Data into the Department Table
INSERT INTO Department (DepartmentID, DeptCode, DeptName, HeadID) VALUES
(1, 'CS',  'Computer Science', NULL),
(2, 'BUS', 'Business Administration', NULL),
(3, 'ENG', 'Engineering', NULL),
(4, 'SOC', 'Social Sciences', NULL);

-- Inserting Data into the Staff Table
INSERT INTO Staff (StaffID, Fname, Lname, StaffEmail, StaffPhone, Role, DepartmentID) VALUES
(1, 'Kwame',   'Mensah',    'kwame.mensah@ashesi.edu.gh',   '0241111001', 'Lecturer',       1),
(2, 'Akosua',  'Boateng',   'akosua.boateng@ashesi.edu.gh', '0241111002', 'Lecturer',       2),
(3, 'Daniel',  'Asare',     'daniel.asare@ashesi.edu.gh',    '0241111003', 'Lecturer',       3),
(4, 'Efua',    'Owusu',     'efua.owusu@ashesi.edu.gh',      '0241111004', 'Lecturer',       4),
(5, 'Michael', 'Addo',      'michael.addo@ashesi.edu.gh',    '0241111005', 'Faculty Intern', 1),
(6, 'Abena',   'Ofori',     'abena.ofori@ashesi.edu.gh',     '0241111006', 'Faculty Intern', 2),
(7, 'Samuel',  'Agyeman',   'samuel.agyeman@ashesi.edu.gh',  '0241111007', 'Faculty Intern', 3),
(8, 'Nana',    'Darko',     'nana.darko@ashesi.edu.gh',      '0241111008', 'Faculty Intern', 4),
(9, 'Linda',   'Ansah',     'linda.ansah@ashesi.edu.gh',     '0241111009', 'Lecturer',       1),
(10,'Joseph',  'Amankwah',  'joseph.amankwah@ashesi.edu.gh', '0241111010', 'Lecturer',       2),
(11,'Grace',   'Tetteh',    'grace.tetteh@ashesi.edu.gh',    '0241111011', 'Lecturer',       3),
(12,'Peter',   'Quaye',     'peter.quaye@ashesi.edu.gh',     '0241111012', 'Lecturer',       4);

/* Assign one lecturer as the head of each department. */
UPDATE Department SET HeadID = 1 WHERE DepartmentID = 1;
UPDATE Department SET HeadID = 2 WHERE DepartmentID = 2;
UPDATE Department SET HeadID = 3 WHERE DepartmentID = 3;
UPDATE Department SET HeadID = 4 WHERE DepartmentID = 4;

-- Inserting Data into the Student
INSERT INTO Student (StudentID, Fname, Lname, StudentPhone, StudentEmail, DepartmentID) VALUES
(1,  'Ama',       'Amoako',      '0202000001', 'ama.amoako@ashesi.edu.gh',       1),
(2,  'Kojo',      'Appiah',      '0202000002', 'kojo.appiah@ashesi.edu.gh',      1),
(3,  'Yaa',       'Bonsu',       '0202000003', 'yaa.bonsu@ashesi.edu.gh',        1),
(4,  'Kofi',      'Acheampong',  '0202000004', 'kofi.acheampong@ashesi.edu.gh',  1),
(5,  'Adwoa',     'Baah',        '0202000005', 'adwoa.baah@ashesi.edu.gh',       1),
(6,  'Kwesi',     'Antwi',       '0202000006', 'kwesi.antwi@ashesi.edu.gh',      1),
(7,  'Esi',       'Nyarko',      '0202000007', 'esi.nyarko@ashesi.edu.gh',       1),
(8,  'Yaw',       'Arthur',      '0202000008', 'yaw.arthur@ashesi.edu.gh',       1),
(9,  'Akua',      'Frimpong',    '0202000009', 'akua.frimpong@ashesi.edu.gh',    2),
(10, 'Nana',      'Osei',        '0202000010', 'nana.osei@ashesi.edu.gh',        2),
(11, 'Abigail',   'Koomson',     '0202000011', 'abigail.koomson@ashesi.edu.gh',  2),
(12, 'Isaac',     'Lamptey',     '0202000012', 'isaac.lamptey@ashesi.edu.gh',    2),
(13, 'Priscilla', 'Adu',         '0202000013', 'priscilla.adu@ashesi.edu.gh',    2),
(14, 'Emmanuel',  'Sarpong',     '0202000014', 'emmanuel.sarpong@ashesi.edu.gh', 2),
(15, 'Mabel',     'Dapaah',      '0202000015', 'mabel.dapaah@ashesi.edu.gh',     2),
(16, 'George',    'Ankomah',     '0202000016', 'george.ankomah@ashesi.edu.gh',   2),
(17, 'Serwaa',    'Poku',        '0202000017', 'serwaa.poku@ashesi.edu.gh',      3),
(18, 'Richard',   'Bediako',     '0202000018', 'richard.bediako@ashesi.edu.gh',  3),
(19, 'Naana',     'Lartey',      '0202000019', 'naana.lartey@ashesi.edu.gh',     3),
(20, 'Kelvin',    'Asiedu',      '0202000020', 'kelvin.asiedu@ashesi.edu.gh',    3),
(21, 'Gifty',     'Aidoo',       '0202000021', 'gifty.aidoo@ashesi.edu.gh',      3),
(22, 'Felix',     'Opoku',       '0202000022', 'felix.opoku@ashesi.edu.gh',      3),
(23, 'Doris',     'Ababio',      '0202000023', 'doris.ababio@ashesi.edu.gh',     3),
(24, 'Martin',    'Kyei',        '0202000024', 'martin.kyei@ashesi.edu.gh',      3),
(25, 'Joana',     'Adjei',       '0202000025', 'joana.adjei@ashesi.edu.gh',      4),
(26, 'Elvis',     'Tawiah',      '0202000026', 'elvis.tawiah@ashesi.edu.gh',     4),
(27, 'Sandra',    'Agyapong',    '0202000027', 'sandra.agyapong@ashesi.edu.gh',  4),
(28, 'David',     'Nartey',      '0202000028', 'david.nartey@ashesi.edu.gh',     4),
(29, 'Belinda',   'Acquah',      '0202000029', 'belinda.acquah@ashesi.edu.gh',   4),
(30, 'Francis',   'Tandoh',      '0202000030', 'francis.tandoh@ashesi.edu.gh',   4);

-- Inserting Data into the Course Table
INSERT INTO Course (CourseID, CourseCode, CourseTitle, CreditHours, DepartmentID) VALUES
(1,  'CS101',  'Introduction to Computing',        3.00, 1),
(2,  'CS201',  'Data Structures and Algorithms',   3.00, 1),
(3,  'CS301',  'Database Systems',                  3.00, 1),
(4,  'BUS101', 'Principles of Management',          3.00, 2),
(5,  'BUS205', 'Marketing Management',              3.00, 2),
(6,  'BUS310', 'Corporate Finance',                 3.00, 2),
(7,  'ENG101', 'Engineering Mathematics',           4.00, 3),
(8,  'ENG220', 'Digital Systems',                   3.00, 3),
(9,  'ENG305', 'Control Systems',                   3.00, 3),
(10, 'SOC101', 'Introduction to Sociology',         3.00, 4),
(11, 'SOC210', 'Research Methods',                  3.00, 4),
(12, 'SOC320', 'Development Studies',               3.00, 4);

-- Inserting Data into the Teaching_Assignment Table
INSERT INTO Teaching_Assignment (AssignmentID, CourseID, AssigneeID, Semester) VALUES
(1,  1,  1, '2026-S1'),
(2,  2,  9, '2026-S1'),
(3,  3,  1, '2026-S1'),
(4,  4,  2, '2026-S1'),
(5,  5, 10, '2026-S1'),
(6,  6,  2, '2026-S2'),
(7,  7,  3, '2026-S1'),
(8,  8, 11, '2026-S1'),
(9,  9,  3, '2026-S2'),
(10, 10, 4, '2026-S1'),
(11, 11,12, '2026-S1'),
(12, 12, 4, '2026-S2'),
(13, 3,  5, '2026-S1'),
(14, 5,  6, '2026-S1'),
(15, 8,  7, '2026-S1'),
(16, 11, 8, '2026-S1');

-- Inserting Data into the Enrollment Table
INSERT INTO Enrollment (EnrollmentID, StudentID, CourseID, Semester, EnrollmentDate, EnrollmentStatus) VALUES
(1,  1,  1,  '2026-S1', '2026-01-10', 'Active'),
(2,  2,  1,  '2026-S1', '2026-01-10', 'Active'),
(3,  3,  1,  '2026-S1', '2026-01-11', 'Active'),
(4,  4,  2,  '2026-S1', '2026-01-11', 'Active'),
(5,  5,  2,  '2026-S1', '2026-01-12', 'Active'),
(6,  6,  2,  '2026-S1', '2026-01-12', 'Active'),
(7,  7,  3,  '2026-S1', '2026-01-13', 'Active'),
(8,  8,  3,  '2026-S1', '2026-01-13', 'Active'),
(9,  9,  3,  '2026-S1', '2026-01-14', 'Active'),
(10, 10, 4,  '2026-S1', '2026-01-10', 'Active'),
(11, 11, 4,  '2026-S1', '2026-01-11', 'Active'),
(12, 12, 5,  '2026-S1', '2026-01-12', 'Active'),
(13, 13, 5,  '2026-S1', '2026-01-13', 'Active'),
(14, 14, 6,  '2026-S2', '2026-06-15', 'Active'),
(15, 15, 6,  '2026-S2', '2026-06-16', 'Active'),
(16, 16, 7,  '2026-S1', '2026-01-10', 'Active'),
(17, 17, 7,  '2026-S1', '2026-01-11', 'Active'),
(18, 18, 8,  '2026-S1', '2026-01-12', 'Active'),
(19, 19, 8,  '2026-S1', '2026-01-13', 'Active'),
(20, 20, 9,  '2026-S2', '2026-06-15', 'Active'),
(21, 21, 9,  '2026-S2', '2026-06-16', 'Active'),
(22, 22, 10, '2026-S1', '2026-01-10', 'Active'),
(23, 23, 10, '2026-S1', '2026-01-11', 'Active'),
(24, 24, 11, '2026-S1', '2026-01-12', 'Active'),
(25, 25, 11, '2026-S1', '2026-01-13', 'Active'),
(26, 26, 12, '2026-S2', '2026-06-15', 'Active'),
(27, 27, 12, '2026-S2', '2026-06-16', 'Active'),
(28, 28, 3,  '2026-S1', '2026-01-15', 'Active'),
(29, 29, 5,  '2026-S1', '2026-01-15', 'Active'),
(30, 30, 8,  '2026-S1', '2026-01-15', 'Active');

-- Inserting Data into the Attendance Table
INSERT INTO Attendance (AttendanceID, EnrollmentID, SessionDate, AttendanceStatus) VALUES
(1,  1,  '2026-02-02', 'Present'),
(2,  2,  '2026-02-02', 'Present'),
(3,  3,  '2026-02-02', 'Absent'),
(4,  4,  '2026-02-03', 'Present'),
(5,  5,  '2026-02-03', 'Present'),
(6,  6,  '2026-02-03', 'Absent'),
(7,  7,  '2026-02-04', 'Present'),
(8,  8,  '2026-02-04', 'Present'),
(9,  9,  '2026-02-04', 'Present'),
(10, 10, '2026-02-05', 'Present'),
(11, 11, '2026-02-05', 'Absent'),
(12, 12, '2026-02-06', 'Present'),
(13, 13, '2026-02-06', 'Present'),
(14, 14, '2026-07-06', 'Present'),
(15, 15, '2026-07-06', 'Absent'),
(16, 16, '2026-02-09', 'Present'),
(17, 17, '2026-02-09', 'Present'),
(18, 18, '2026-02-10', 'Present'),
(19, 19, '2026-02-10', 'Absent'),
(20, 20, '2026-07-07', 'Present'),
(21, 21, '2026-07-07', 'Present'),
(22, 22, '2026-02-11', 'Present'),
(23, 23, '2026-02-11', 'Absent'),
(24, 24, '2026-02-12', 'Present'),
(25, 25, '2026-02-12', 'Present'),
(26, 26, '2026-07-08', 'Present'),
(27, 27, '2026-07-08', 'Absent'),
(28, 28, '2026-02-13', 'Present'),
(29, 29, '2026-02-13', 'Present'),
(30, 30, '2026-02-13', 'Present');

-- Inserting Data into the Assessment Table
INSERT INTO Assessment (AssessmentID, CourseID, AssessmentType, MaxScore, WeightPercent, DueDate, DateUploaded) VALUES
(1,  1,  'Quiz',        20.00, 20.00, '2026-02-20', '2026-02-01'),
(2,  1,  'Assignment',  30.00, 30.00, '2026-03-10', '2026-02-15'),
(3,  1,  'Exam',       100.00, 50.00, '2026-05-20', '2026-05-01'),
(4,  2,  'Quiz',        20.00, 20.00, '2026-02-22', '2026-02-02'),
(5,  2,  'MidSemester', 50.00, 30.00, '2026-03-25', '2026-03-01'),
(6,  2,  'Exam',       100.00, 50.00, '2026-05-22', '2026-05-01'),
(7,  3,  'Assignment',  40.00, 30.00, '2026-03-15', '2026-02-20'),
(8,  3,  'MidSemester', 50.00, 30.00, '2026-03-30', '2026-03-05'),
(9,  3,  'Exam',       100.00, 40.00, '2026-05-25', '2026-05-01'),
(10, 4,  'Quiz',        20.00, 20.00, '2026-02-25', '2026-02-05'),
(11, 4,  'Assignment',  30.00, 30.00, '2026-03-18', '2026-02-25'),
(12, 4,  'Exam',       100.00, 50.00, '2026-05-27', '2026-05-01'),
(13, 5,  'Quiz',        20.00, 20.00, '2026-02-26', '2026-02-06'),
(14, 5,  'Assignment',  30.00, 30.00, '2026-03-20', '2026-02-26'),
(15, 5,  'Exam',       100.00, 50.00, '2026-05-28', '2026-05-01'),
(16, 6,  'Quiz',        20.00, 20.00, '2026-07-20', '2026-07-01'),
(17, 6,  'Assignment',  30.00, 30.00, '2026-08-15', '2026-07-20'),
(18, 6,  'Exam',       100.00, 50.00, '2026-11-20', '2026-11-01'),
(19, 7,  'Quiz',        20.00, 20.00, '2026-02-27', '2026-02-07'),
(20, 7,  'MidSemester', 50.00, 30.00, '2026-03-28', '2026-03-02'),
(21, 7,  'Exam',       100.00, 50.00, '2026-05-29', '2026-05-01'),
(22, 8,  'Quiz',        20.00, 20.00, '2026-02-28', '2026-02-08'),
(23, 8,  'Assignment',  30.00, 30.00, '2026-03-22', '2026-02-28'),
(24, 8,  'Exam',       100.00, 50.00, '2026-05-30', '2026-05-01'),
(25, 9,  'Assignment',  40.00, 30.00, '2026-08-20', '2026-07-20'),
(26, 9,  'MidSemester', 50.00, 30.00, '2026-09-25', '2026-09-01'),
(27, 9,  'Exam',       100.00, 40.00, '2026-11-25', '2026-11-01'),
(28, 10, 'Quiz',        20.00, 20.00, '2026-03-01', '2026-02-10'),
(29, 10, 'Assignment',  30.00, 30.00, '2026-03-25', '2026-03-01'),
(30, 10, 'Exam',       100.00, 50.00, '2026-06-01', '2026-05-01'),
(31, 11, 'Quiz',        20.00, 20.00, '2026-03-02', '2026-02-11'),
(32, 11, 'MidSemester', 50.00, 30.00, '2026-03-29', '2026-03-03'),
(33, 11, 'Exam',       100.00, 50.00, '2026-06-02', '2026-05-01'),
(34, 12, 'Assignment',  40.00, 30.00, '2026-08-22', '2026-07-22'),
(35, 12, 'MidSemester', 50.00, 30.00, '2026-09-28', '2026-09-02'),
(36, 12, 'Exam',       100.00, 40.00, '2026-11-28', '2026-11-01');

-- Inserting Data into the Grade Table
INSERT INTO Grade (GradeID, EnrollmentID, AssessmentID, ScoreObtained, DateRecorded) VALUES
(1,  1,  1,  16.00, '2026-02-22'),
(2,  2,  1,  14.00, '2026-02-22'),
(3,  3,  1,  18.00, '2026-02-22'),
(4,  4,  4,  15.00, '2026-02-24'),
(5,  5,  4,  17.00, '2026-02-24'),
(6,  6,  4,  13.00, '2026-02-24'),
(7,  7,  7,  34.00, '2026-03-18'),
(8,  8,  7,  31.00, '2026-03-18'),
(9,  9,  7,  37.00, '2026-03-18'),
(10, 10, 10, 17.00, '2026-02-27'),
(11, 11, 10, 14.00, '2026-02-27'),
(12, 12, 13, 16.00, '2026-02-28'),
(13, 13, 13, 18.00, '2026-02-28'),
(14, 14, 16, 15.00, '2026-07-22'),
(15, 15, 16, 13.00, '2026-07-22'),
(16, 16, 19, 17.00, '2026-03-01'),
(17, 17, 19, 15.00, '2026-03-01'),
(18, 18, 22, 18.00, '2026-03-02'),
(19, 19, 22, 12.00, '2026-03-02'),
(20, 20, 25, 35.00, '2026-08-22'),
(21, 21, 25, 32.00, '2026-08-22'),
(22, 22, 28, 16.00, '2026-03-03'),
(23, 23, 28, 14.00, '2026-03-03'),
(24, 24, 31, 17.00, '2026-03-04'),
(25, 25, 31, 15.00, '2026-03-04'),
(26, 26, 34, 34.00, '2026-08-24'),
(27, 27, 34, 30.00, '2026-08-24'),
(28, 28, 7,  36.00, '2026-03-18'),
(29, 29, 13, 19.00, '2026-02-28'),
(30, 30, 22, 16.00, '2026-03-02');
