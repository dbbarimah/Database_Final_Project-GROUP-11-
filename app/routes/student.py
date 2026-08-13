import pymysql
from flask import Blueprint, flash, redirect, render_template, request, url_for

from app.auth import require_login_before_request, role_required
from app.db import get_db
from app.utils import db_error_message, is_htmx

bp = Blueprint("student", __name__, url_prefix="/students")
bp.before_request(require_login_before_request)


@bp.route("/")
@role_required("db_admin")
def list_students():
    db = get_db()
    with db.cursor() as cur:
        cur.execute(
            """SELECT s.StudentID, s.Fname, s.Lname, s.StudentEmail, s.StudentPhone, d.DeptCode
                 FROM Student s JOIN Department d ON d.DepartmentID = s.DepartmentID
                ORDER BY s.Lname"""
        )
        students = cur.fetchall()
    return render_template("student/list.html", students=students)


@bp.route("/new", methods=["GET", "POST"])
@role_required("db_admin")
def create_student():
    db = get_db()
    if request.method == "POST":
        try:
            with db.cursor() as cur:
                cur.execute(
                    """INSERT INTO Student (Fname, Lname, StudentPhone, StudentEmail, DepartmentID)
                       VALUES (%s, %s, %s, %s, %s)""",
                    (
                        request.form["fname"].strip(),
                        request.form["lname"].strip(),
                        request.form.get("phone", "").strip() or None,
                        request.form["email"].strip(),
                        request.form["department_id"],
                    ),
                )
            flash("Student created.", "success")
            return redirect(url_for("student.list_students"))
        except pymysql.MySQLError as exc:
            flash(db_error_message(exc), "danger")

    with db.cursor() as cur:
        cur.execute("SELECT DepartmentID, DeptCode FROM Department ORDER BY DeptCode")
        departments = cur.fetchall()
    return render_template("student/form.html", student=None, departments=departments)


@bp.route("/<int:student_id>/edit", methods=["GET", "POST"])
@role_required("db_admin")
def edit_student(student_id):
    db = get_db()
    if request.method == "POST":
        try:
            with db.cursor() as cur:
                cur.execute(
                    """UPDATE Student SET Fname=%s, Lname=%s, StudentPhone=%s,
                              StudentEmail=%s, DepartmentID=%s WHERE StudentID=%s""",
                    (
                        request.form["fname"].strip(),
                        request.form["lname"].strip(),
                        request.form.get("phone", "").strip() or None,
                        request.form["email"].strip(),
                        request.form["department_id"],
                        student_id,
                    ),
                )
            flash("Student updated.", "success")
            return redirect(url_for("student.list_students"))
        except pymysql.MySQLError as exc:
            flash(db_error_message(exc), "danger")

    with db.cursor() as cur:
        cur.execute("SELECT * FROM Student WHERE StudentID=%s", (student_id,))
        student = cur.fetchone()
        cur.execute("SELECT DepartmentID, DeptCode FROM Department ORDER BY DeptCode")
        departments = cur.fetchall()
    if student is None:
        flash("Student not found.", "warning")
        return redirect(url_for("student.list_students"))
    return render_template("student/form.html", student=student, departments=departments)


@bp.route("/<int:student_id>/delete", methods=["POST"])
@role_required("db_admin")
def delete_student(student_id):
    db = get_db()
    try:
        with db.cursor() as cur:
            cur.execute("DELETE FROM Student WHERE StudentID=%s", (student_id,))
    except pymysql.MySQLError as exc:
        if is_htmx():
            return db_error_message(exc), 400
        flash(db_error_message(exc), "danger")
        return redirect(url_for("student.list_students"))
    if is_htmx():
        return "", 200
    flash("Student deleted.", "success")
    return redirect(url_for("student.list_students"))


@bp.route("/<int:student_id>/transcript")
@role_required("db_admin")
def transcript(student_id):
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM Student WHERE StudentID=%s", (student_id,))
        student = cur.fetchone()
        if student is None:
            flash("Student not found.", "warning")
            return redirect(url_for("student.list_students"))
        cur.callproc("sp_GetStudentTranscript", (student_id,))
        rows = cur.fetchall()
    return render_template("student/transcript.html", student=student, rows=rows)


@bp.route("/profile")
@role_required("student")
def my_profile():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_my_profile")
        profile = cur.fetchone()
    return render_template("student/profile.html", profile=profile)
