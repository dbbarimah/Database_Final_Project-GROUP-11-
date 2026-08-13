import pymysql
from flask import Blueprint, flash, redirect, render_template, request, url_for

from app.auth import require_login_before_request, role_required
from app.db import get_db
from app.utils import ENROLLMENT_STATUS_CHOICES, SEMESTER_PATTERN, db_error_message, is_htmx

bp = Blueprint("enrollment", __name__, url_prefix="/enrollments")
bp.before_request(require_login_before_request)


@bp.route("/")
@role_required("db_admin")
def list_enrollments():
    db = get_db()
    with db.cursor() as cur:
        cur.execute(
            """SELECT e.EnrollmentID, e.Semester, e.EnrollmentDate, e.EnrollmentStatus,
                      s.Fname, s.Lname, c.CourseCode
                 FROM Enrollment e
                 JOIN Student s ON s.StudentID = e.StudentID
                 JOIN Course c ON c.CourseID = e.CourseID
                ORDER BY e.Semester DESC, s.Lname"""
        )
        enrollments = cur.fetchall()
    return render_template("enrollment/list.html", enrollments=enrollments)


@bp.route("/new", methods=["GET", "POST"])
@role_required("db_admin")
def create_enrollment():
    db = get_db()
    if request.method == "POST":
        semester = request.form["semester"].strip()
        if not SEMESTER_PATTERN.match(semester):
            flash("Semester must look like '2026-S1' or '2026-S2'.", "danger")
        else:
            try:
                with db.cursor() as cur:
                    cur.callproc(
                        "sp_EnrollStudent",
                        (
                            request.form["student_id"],
                            request.form["course_id"],
                            semester,
                            request.form["enrollment_date"],
                        ),
                    )
                flash("Student enrolled.", "success")
                return redirect(url_for("enrollment.list_enrollments"))
            except pymysql.MySQLError as exc:
                flash(db_error_message(exc), "danger")

    with db.cursor() as cur:
        cur.execute("SELECT StudentID, Fname, Lname FROM Student ORDER BY Lname")
        students = cur.fetchall()
        cur.execute("SELECT CourseID, CourseCode FROM Course ORDER BY CourseCode")
        courses = cur.fetchall()
    return render_template("enrollment/form.html", students=students, courses=courses)


@bp.route("/<int:enrollment_id>/status", methods=["POST"])
@role_required("db_admin")
def update_status(enrollment_id):
    db = get_db()
    status = request.form["status"]
    if status not in ENROLLMENT_STATUS_CHOICES:
        flash("Invalid enrollment status.", "danger")
        return redirect(url_for("enrollment.list_enrollments"))
    try:
        with db.cursor() as cur:
            cur.execute(
                "UPDATE Enrollment SET EnrollmentStatus=%s WHERE EnrollmentID=%s",
                (status, enrollment_id),
            )
        flash("Enrollment status updated.", "success")
    except pymysql.MySQLError as exc:
        flash(db_error_message(exc), "danger")
    return redirect(url_for("enrollment.list_enrollments"))


@bp.route("/<int:enrollment_id>/delete", methods=["POST"])
@role_required("db_admin")
def delete_enrollment(enrollment_id):
    db = get_db()
    try:
        with db.cursor() as cur:
            cur.execute("DELETE FROM Enrollment WHERE EnrollmentID=%s", (enrollment_id,))
    except pymysql.MySQLError as exc:
        if is_htmx():
            return db_error_message(exc), 400
        flash(db_error_message(exc), "danger")
        return redirect(url_for("enrollment.list_enrollments"))
    if is_htmx():
        return "", 200
    flash("Enrollment deleted.", "success")
    return redirect(url_for("enrollment.list_enrollments"))


@bp.route("/class-list")
@role_required("lecturer", "faculty_intern")
def class_list():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_class_list ORDER BY Semester DESC, CourseCode, Lname")
        rows = cur.fetchall()
    return render_template("enrollment/class_list.html", rows=rows)


@bp.route("/mine")
@role_required("student")
def my_enrollments():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_my_enrollments ORDER BY Semester DESC, CourseCode")
        rows = cur.fetchall()
    return render_template("enrollment/mine.html", rows=rows)
