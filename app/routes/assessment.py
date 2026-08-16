import pymysql
from flask import Blueprint, flash, redirect, render_template, request, url_for

from app.auth import require_login_before_request, role_required
from app.db import get_db
from app.utils import ASSESSMENT_TYPE_CHOICES, db_error_message, is_htmx

bp = Blueprint("assessment", __name__, url_prefix="/assessments")
bp.before_request(require_login_before_request)


@bp.route("/")
@role_required("db_admin")
def list_assessments():
    db = get_db()
    with db.cursor() as cur:
        cur.execute(
            """SELECT a.AssessmentID, a.AssessmentType, a.MaxScore, a.WeightPercent,
                      a.DueDate, c.CourseCode,
                      CONCAT(c.CourseCode, ' — ', c.CourseTitle) AS CourseLabel
                 FROM Assessment a JOIN Course c ON c.CourseID = a.CourseID
                ORDER BY c.CourseCode, a.DueDate"""
        )
        assessments = cur.fetchall()
    return render_template("assessment/list.html", assessments=assessments)


@bp.route("/new", methods=["GET", "POST"])
@role_required("lecturer", "faculty_intern")
def create_assessment():
    db = get_db()
    if request.method == "POST":
        try:
            with db.cursor() as cur:
                cur.execute(
                    """INSERT INTO Assessment (CourseID, AssessmentType, MaxScore, WeightPercent, DueDate, DateUploaded)
                       VALUES (%s, %s, %s, %s, %s, CURDATE())""",
                    (
                        request.form["course_id"],
                        request.form["assessment_type"],
                        request.form["max_score"],
                        request.form["weight_percent"],
                        request.form.get("due_date") or None,
                    ),
                )
            flash("Assessment created.", "success")
            return redirect(url_for("assessment.class_assessments"))
        except pymysql.MySQLError as exc:
            flash(db_error_message(exc), "danger")

    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_my_teaching ORDER BY Semester DESC, CourseCode")
        teaching = cur.fetchall()
    return render_template(
        "assessment/form.html", assessment=None, teaching=teaching, type_choices=ASSESSMENT_TYPE_CHOICES
    )


@bp.route("/<int:assessment_id>/edit", methods=["GET", "POST"])
@role_required("lecturer", "faculty_intern")
def edit_assessment(assessment_id):
    db = get_db()
    if request.method == "POST":
        try:
            with db.cursor() as cur:
                cur.execute(
                    """UPDATE Assessment SET CourseID=%s, AssessmentType=%s, MaxScore=%s,
                              WeightPercent=%s, DueDate=%s WHERE AssessmentID=%s""",
                    (
                        request.form["course_id"],
                        request.form["assessment_type"],
                        request.form["max_score"],
                        request.form["weight_percent"],
                        request.form.get("due_date") or None,
                        assessment_id,
                    ),
                )
            flash("Assessment updated.", "success")
            return redirect(url_for("assessment.class_assessments"))
        except pymysql.MySQLError as exc:
            flash(db_error_message(exc), "danger")

    with db.cursor() as cur:
        cur.execute("SELECT * FROM Assessment WHERE AssessmentID=%s", (assessment_id,))
        assessment = cur.fetchone()
        cur.execute("SELECT * FROM v_my_teaching ORDER BY Semester DESC, CourseCode")
        teaching = cur.fetchall()
    if assessment is None:
        flash("Assessment not found.", "warning")
        return redirect(url_for("assessment.class_assessments"))
    return render_template(
        "assessment/form.html", assessment=assessment, teaching=teaching, type_choices=ASSESSMENT_TYPE_CHOICES
    )


@bp.route("/<int:assessment_id>/delete", methods=["POST"])
@role_required("db_admin")
def delete_assessment(assessment_id):
    db = get_db()
    try:
        with db.cursor() as cur:
            cur.execute("DELETE FROM Assessment WHERE AssessmentID=%s", (assessment_id,))
    except pymysql.MySQLError as exc:
        if is_htmx():
            return db_error_message(exc), 400
        flash(db_error_message(exc), "danger")
        return redirect(url_for("assessment.list_assessments"))
    if is_htmx():
        return "", 200
    flash("Assessment deleted.", "success")
    return redirect(url_for("assessment.list_assessments"))


@bp.route("/class")
@role_required("lecturer", "faculty_intern")
def class_assessments():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_class_assessments ORDER BY DueDate")
        rows = cur.fetchall()
    return render_template("assessment/class.html", rows=rows)


@bp.route("/mine")
@role_required("student")
def my_assessments():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_my_assessments ORDER BY DueDate")
        rows = cur.fetchall()
    return render_template("assessment/mine.html", rows=rows)