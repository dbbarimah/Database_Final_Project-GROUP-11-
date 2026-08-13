import pymysql
from flask import Blueprint, flash, redirect, render_template, request, url_for

from app.auth import require_login_before_request, role_required
from app.db import get_db
from app.utils import SEMESTER_PATTERN, db_error_message, is_htmx

bp = Blueprint("teaching_assignment", __name__, url_prefix="/teaching-assignments")
bp.before_request(require_login_before_request)


@bp.route("/")
@role_required("db_admin")
def list_assignments():
    db = get_db()
    with db.cursor() as cur:
        cur.execute(
            """SELECT ta.AssignmentID, ta.Semester, c.CourseCode, c.CourseTitle,
                      CONCAT(c.CourseCode, ' — ', c.CourseTitle) AS CourseLabel,
                      s.Fname, s.Lname, s.Role
                 FROM Teaching_Assignment ta
                 JOIN Course c ON c.CourseID = ta.CourseID
                 JOIN Staff s ON s.StaffID = ta.AssigneeID
                ORDER BY c.CourseCode, ta.Semester DESC, s.Lname"""
        )
        assignments = cur.fetchall()
    return render_template("teaching_assignment/list.html", assignments=assignments)


@bp.route("/new", methods=["GET", "POST"])
@role_required("db_admin")
def create_assignment():
    db = get_db()
    if request.method == "POST":
        semester = request.form["semester"].strip()
        if not SEMESTER_PATTERN.match(semester):
            flash("Semester must look like '2026-S1' or '2026-S2'.", "danger")
        else:
            try:
                with db.cursor() as cur:
                    cur.execute(
                        "INSERT INTO Teaching_Assignment (CourseID, AssigneeID, Semester) VALUES (%s, %s, %s)",
                        (request.form["course_id"], request.form["assignee_id"], semester),
                    )
                flash("Teaching assignment created.", "success")
                return redirect(url_for("teaching_assignment.list_assignments"))
            except pymysql.MySQLError as exc:
                flash(db_error_message(exc), "danger")

    with db.cursor() as cur:
        cur.execute("SELECT CourseID, CourseCode FROM Course ORDER BY CourseCode")
        courses = cur.fetchall()
        cur.execute("SELECT StaffID, Fname, Lname, Role FROM Staff ORDER BY Lname")
        staff = cur.fetchall()
    return render_template("teaching_assignment/form.html", courses=courses, staff=staff)


@bp.route("/<int:assignment_id>/delete", methods=["POST"])
@role_required("db_admin")
def delete_assignment(assignment_id):
    db = get_db()
    try:
        with db.cursor() as cur:
            cur.execute("DELETE FROM Teaching_Assignment WHERE AssignmentID=%s", (assignment_id,))
    except pymysql.MySQLError as exc:
        if is_htmx():
            return db_error_message(exc), 400
        flash(db_error_message(exc), "danger")
        return redirect(url_for("teaching_assignment.list_assignments"))
    if is_htmx():
        return "", 200
    flash("Teaching assignment deleted.", "success")
    return redirect(url_for("teaching_assignment.list_assignments"))


@bp.route("/mine")
@role_required("lecturer", "faculty_intern")
def my_teaching():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_my_teaching ORDER BY Semester DESC, CourseCode")
        assignments = cur.fetchall()
    return render_template("teaching_assignment/mine.html", assignments=assignments)
