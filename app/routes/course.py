import pymysql
from flask import Blueprint, flash, redirect, render_template, request, url_for

from app.auth import require_login_before_request, role_required
from app.db import get_db
from app.utils import db_error_message, is_htmx

bp = Blueprint("course", __name__, url_prefix="/courses")
bp.before_request(require_login_before_request)


@bp.route("/")
def list_courses():
    db = get_db()
    from app.auth import current_role
    role = current_role()
    with db.cursor() as cur:
        if role == "student":
            cur.execute(
                """SELECT e.CourseID, e.CourseCode, e.CourseTitle, e.CreditHours, e.Semester,
                          e.EnrollmentStatus
                     FROM v_my_enrollments e
                    ORDER BY e.Semester DESC, e.CourseCode"""
            )
        else:
            cur.execute(
                """SELECT c.CourseID, c.CourseCode, c.CourseTitle, c.CreditHours, d.DeptCode
                     FROM Course c JOIN Department d ON d.DepartmentID = c.DepartmentID
                    ORDER BY c.CourseCode"""
            )
        courses = cur.fetchall()
    return render_template("course/list.html", courses=courses, role=role)


@bp.route("/<int:course_id>")
@role_required("student")
def course_detail(course_id):
    db = get_db()
    from app.utils import letter_grade
    with db.cursor() as cur:
        cur.execute(
            "SELECT * FROM v_my_enrollments WHERE CourseID=%s", (course_id,)
        )
        enrollment = cur.fetchone()
        if enrollment is None:
            flash("You are not enrolled in this course.", "warning")
            return redirect(url_for("course.list_courses"))
        cur.execute(
            "SELECT * FROM v_my_assessments WHERE CourseCode=%s ORDER BY DueDate",
            (enrollment["CourseCode"],)
        )
        assessments = cur.fetchall()
        cur.execute(
            "SELECT * FROM v_my_grades WHERE CourseCode=%s ORDER BY DateRecorded",
            (enrollment["CourseCode"],)
        )
        grades = cur.fetchall()
        cur.execute(
            "SELECT * FROM v_my_course_materials WHERE CourseCode=%s ORDER BY DateUploaded DESC",
            (enrollment["CourseCode"],)
        )
        materials = cur.fetchall()
    return render_template(
        "course/detail.html",
        enrollment=enrollment,
        assessments=assessments,
        grades=grades,
        materials=materials,
        letter_grade=letter_grade
    )


@bp.route("/new", methods=["GET", "POST"])
@role_required("db_admin")
def create_course():
    db = get_db()
    if request.method == "POST":
        try:
            with db.cursor() as cur:
                cur.execute(
                    "INSERT INTO Course (CourseCode, CourseTitle, CreditHours, DepartmentID) VALUES (%s, %s, %s, %s)",
                    (
                        request.form["course_code"].strip(),
                        request.form["course_title"].strip(),
                        request.form["credit_hours"],
                        request.form["department_id"],
                    ),
                )
            flash("Course created.", "success")
            return redirect(url_for("course.list_courses"))
        except pymysql.MySQLError as exc:
            flash(db_error_message(exc), "danger")

    with db.cursor() as cur:
        cur.execute("SELECT DepartmentID, DeptCode FROM Department ORDER BY DeptCode")
        departments = cur.fetchall()
    return render_template("course/form.html", course=None, departments=departments)


@bp.route("/<int:course_id>/edit", methods=["GET", "POST"])
@role_required("db_admin")
def edit_course(course_id):
    db = get_db()
    if request.method == "POST":
        try:
            with db.cursor() as cur:
                cur.execute(
                    "UPDATE Course SET CourseCode=%s, CourseTitle=%s, CreditHours=%s, DepartmentID=%s WHERE CourseID=%s",
                    (
                        request.form["course_code"].strip(),
                        request.form["course_title"].strip(),
                        request.form["credit_hours"],
                        request.form["department_id"],
                        course_id,
                    ),
                )
            flash("Course updated.", "success")
            return redirect(url_for("course.list_courses"))
        except pymysql.MySQLError as exc:
            flash(db_error_message(exc), "danger")

    with db.cursor() as cur:
        cur.execute("SELECT * FROM Course WHERE CourseID=%s", (course_id,))
        course = cur.fetchone()
        cur.execute("SELECT DepartmentID, DeptCode FROM Department ORDER BY DeptCode")
        departments = cur.fetchall()
    if course is None:
        flash("Course not found.", "warning")
        return redirect(url_for("course.list_courses"))
    return render_template("course/form.html", course=course, departments=departments)


@bp.route("/<int:course_id>/delete", methods=["POST"])
@role_required("db_admin")
def delete_course(course_id):
    db = get_db()
    try:
        with db.cursor() as cur:
            cur.execute("DELETE FROM Course WHERE CourseID=%s", (course_id,))
    except pymysql.MySQLError as exc:
        if is_htmx():
            return db_error_message(exc), 400
        flash(db_error_message(exc), "danger")
        return redirect(url_for("course.list_courses"))
    if is_htmx():
        return "", 200
    flash("Course deleted.", "success")
    return redirect(url_for("course.list_courses"))
