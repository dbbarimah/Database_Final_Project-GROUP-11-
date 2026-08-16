from flask import Flask, render_template, request, redirect, url_for, session
import pymysql

app = Flask(__name__)
app.secret_key = 'group11_lms_secret'


def get_connection():
    user = session.get('db_user')
    password = session.get('db_pass')
    return pymysql.connect(
        host='localhost',
        user=user,
        password=password,
        database='Group11_FinalProject',
        cursorclass=pymysql.cursors.DictCursor
    )


@app.route('/')
def index():
    return redirect(url_for('login'))


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']

        # derive the db username from the email local part
        db_user = email.split('@')[0]

        try:
            conn = pymysql.connect(
                host='127.0.0.1',
                port=3306,
                user=db_user,
                password=password,
                database='Group11_FinalProject',
                cursorclass=pymysql.cursors.DictCursor
            )
            # figure out their role
            cursor = conn.cursor()
            cursor.execute("""
                SELECT 'student' AS role FROM Student WHERE StudentEmail = %s
                UNION
                SELECT Role FROM Staff WHERE StaffEmail = %s
            """, (email, email))
            result = cursor.fetchone()
            conn.close()

            session['db_user'] = db_user
            session['db_pass'] = password
            session['email'] = email
            session['role'] = result['role'] if result else 'unknown'

            return redirect(url_for('dashboard'))

        except Exception as e:
            print(f"Login error: {e}")
            return render_template('login.html', error='Invalid email or password.')
    return render_template('login.html')


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))


@app.route('/dashboard')
def dashboard():
    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("SELECT COUNT(*) AS total_students FROM Student")
    total_students = cursor.fetchone()

    cursor.execute("SELECT COUNT(*) AS total_courses FROM Course")
    total_courses = cursor.fetchone()

    cursor.execute("SELECT COUNT(*) AS total_staff FROM Staff")
    total_staff = cursor.fetchone()

    cursor.execute("SELECT COUNT(*) AS total_assessments FROM Assessment")
    total_assessments = cursor.fetchone()

    cursor.execute("""
        SELECT c.CourseCode, c.CourseTitle, d.DeptName
        FROM Course c
        JOIN Department d ON c.DepartmentID = d.DepartmentID
    """)
    courses = cursor.fetchall()

    connection.close()
    return render_template(
        'dashboard.html',
        total_students=total_students,
        total_courses=total_courses,
        total_staff=total_staff,
        total_assessments=total_assessments,
        courses=courses
    )


@app.route('/courses')
def courses():
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("""
        SELECT c.*, d.DeptName 
        FROM Course c 
        JOIN Department d ON c.DepartmentID = d.DepartmentID
    """)
    courses = cursor.fetchall()
    connection.close()
    return render_template('course.html', courses=courses)


@app.route('/student-registration', methods = ['GET', 'POST'])
def student_registration():
    connection = get_connection()
    cursor = connection.cursor()

    if request.method == 'POST':
        fname = request.form['Fname']
        lname = request.form['Lname']
        phone = request.form['StudentPhone']
        email = request.form['StudentEmail']
        department = request.form['DepartmentID']

        cursor.execute("""
            INSERT INTO Student
            (Fname, Lname, StudentPhone, StudentEmail, DepartmentID)
            VALUES (%s, %s, %s, %s, %s)
        """, (fname, lname, phone, email, department))
        
        connection.commit()
        connection.close()
        return redirect(url_for('student_registration'))

    cursor.execute("""
        SELECT s.*, d.DeptName 
        FROM Student s 
        JOIN Department d ON s.DepartmentID = d.DepartmentID
    """)
    students = cursor.fetchall()

    cursor.execute("SELECT * FROM Department")
    departments = cursor.fetchall()

    connection.close()

    return render_template(
        'students.html',
        students=students,
        departments=departments
    )


@app.route('/people')
def people():
    connection= get_connection()
    cursor = connection.cursor()
    cursor.execute("SELECT StudentID, Fname, Lname, StudentEmail FROM Student")
    people = cursor.fetchall()
    connection.close()
    return render_template('people.html', people = people)


@app.route('/lecturers')
def lecturers():
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("SELECT StaffID, Fname, Lname, StaffEmail, StaffPhone FROM Staff WHERE Role = 'Lecturer'")
    lecturers = cursor.fetchall()
    connection.close()
    return render_template('lecturers.html', lecturers = lecturers)


@app.route('/grades')
def grades():
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("""
        SELECT
            s.Fname,
            s.Lname,
            c.CourseCode,
            a.AssessmentType,
            g.ScoreObtained,
            a.MaxScore
        FROM Grade g
        JOIN Enrollment e ON g.EnrollmentID = e.EnrollmentID
        JOIN Student s ON e.StudentID = s.StudentID
        JOIN Course c ON e.CourseID = c.CourseID
        JOIN Assessment a ON g.AssessmentID = a.AssessmentID
    """)
    grades = cursor.fetchall()
    connection.close()
    return render_template('grades.html', grades = grades)


@app.route('/attendance')
def attendance():
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("""
        SELECT
            s.Fname,
            s.Lname,
            c.CourseCode,
            att.SessionDate,
            att.AttendanceStatus
        FROM Attendance att
        JOIN Enrollment e ON att.EnrollmentID = e.EnrollmentID
        JOIN Student s ON e.StudentID = s.StudentID
        JOIN Course c ON e.CourseID = c.CourseID
    """)
    attendance = cursor.fetchall()
    connection.close()
    return render_template('attendance.html', attendance = attendance)


@app.route('/assessments')
def assessments():
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("""
        SELECT
            a.AssessmentID,
            c.CourseCode,
            c.CourseTitle,
            a.AssessmentType,
            a.MaxScore,
            a.WeightPercent,
            a.DueDate
        FROM Assessment a
        JOIN Course c ON a.CourseID = c.CourseID
    """)
    assessments = cursor.fetchall()
    connection.close()
    return render_template('assessments.html', assessments = assessments)


@app.route('/materials')
def materials():
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("""
        SELECT
            cm.MaterialID,
            c.CourseCode,
            c.CourseTitle,
            cm.MaterialTitle,
            cm.FilePath,
            cm.DateUploaded
        FROM CourseMaterial cm
        JOIN Course c ON cm.CourseID = c.CourseID
    """)
    materials = cursor.fetchall()
    connection.close()
    return render_template('materials.html', materials = materials)

if __name__ == '__main__':
    app.run(debug = True)
