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
    with db.cursor() as cur:
        cur.execute(
            """SELECT c.CourseID, c.CourseCode, c.CourseTitle, c.CreditHours, d.DeptCode
                 FROM Course c JOIN Department d ON d.DepartmentID = c.DepartmentID
                ORDER BY c.CourseCode"""
        )
        courses = cur.fetchall()
    return render_template("course/list.html", courses=courses)


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
