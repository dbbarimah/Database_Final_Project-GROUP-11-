import pymysql
from flask import Blueprint, flash, redirect, render_template, request, url_for

from app.auth import require_login_before_request, role_required
from app.db import get_db
from app.utils import db_error_message, is_htmx, letter_grade

bp = Blueprint("grade", __name__, url_prefix="/grades")
bp.before_request(require_login_before_request)


@bp.route("/")
@role_required("db_admin")
def list_grades():
    db = get_db()
    with db.cursor() as cur:
        cur.execute(
            """SELECT g.GradeID, g.ScoreObtained, g.DateRecorded,
                      s.Fname, s.Lname, c.CourseCode, a.AssessmentType, a.MaxScore,
                      CONCAT(c.CourseCode, ' — ', c.CourseTitle) AS CourseLabel
                 FROM Grade g
                 JOIN Enrollment e ON e.EnrollmentID = g.EnrollmentID
                 JOIN Student s ON s.StudentID = e.StudentID
                 JOIN Course c ON c.CourseID = e.CourseID
                 JOIN Assessment a ON a.AssessmentID = g.AssessmentID
                ORDER BY c.CourseCode, g.DateRecorded DESC"""
        )
        grades = cur.fetchall()
    return render_template("grade/list.html", grades=grades)


@bp.route("/<int:grade_id>/delete", methods=["POST"])
@role_required("db_admin")
def delete_grade(grade_id):
    db = get_db()
    try:
        with db.cursor() as cur:
            cur.execute("DELETE FROM Grade WHERE GradeID=%s", (grade_id,))
    except pymysql.MySQLError as exc:
        if is_htmx():
            return db_error_message(exc), 400
        flash(db_error_message(exc), "danger")
        return redirect(url_for("grade.list_grades"))
    if is_htmx():
        return "", 200
    flash("Grade deleted.", "success")
    return redirect(url_for("grade.list_grades"))


@bp.route("/class")
@role_required("lecturer", "faculty_intern")
def class_grades():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_class_grades ORDER BY DateRecorded DESC")
        rows = cur.fetchall()
        cur.execute("SELECT * FROM v_my_teaching ORDER BY Semester DESC, CourseCode")
        teaching = cur.fetchall()
    return render_template("grade/class.html", rows=rows, teaching=teaching)


@bp.route("/record")
@role_required("lecturer", "faculty_intern")
def record_grade():
    db = get_db()
    course_id = request.args.get("course_id", type=int)
    semester = request.args.get("semester", "")
    assessment_id = request.args.get("assessment_id", type=int)

    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_my_teaching ORDER BY Semester DESC, CourseCode")
        teaching = cur.fetchall()
        class_assessments = []
        roster = []
        if course_id:
            cur.execute("SELECT * FROM v_class_assessments WHERE CourseID=%s", (course_id,))
            class_assessments = cur.fetchall()
        if course_id and semester and assessment_id:
            cur.execute(
                "SELECT * FROM v_class_list WHERE CourseID=%s AND Semester=%s ORDER BY Lname",
                (course_id, semester),
            )
            roster = cur.fetchall()
            cur.execute(
                "SELECT EnrollmentID, ScoreObtained FROM v_class_grades WHERE AssessmentID=%s",
                (assessment_id,),
            )
            existing = {row["EnrollmentID"]: row["ScoreObtained"] for row in cur.fetchall()}
            for r in roster:
                r["ExistingScore"] = existing.get(r["EnrollmentID"])

    return render_template(
        "grade/record.html",
        teaching=teaching,
        class_assessments=class_assessments,
        roster=roster,
        course_id=course_id,
        semester=semester,
        assessment_id=assessment_id,
    )


@bp.route("/cell", methods=["POST"])
@role_required("lecturer", "faculty_intern")
def save_cell():
    db = get_db()
    enrollment_id = request.form["enrollment_id"]
    assessment_id = request.form["assessment_id"]
    score = request.form.get("score", "").strip()
    error = None
    saved = False
    if score:
        try:
            with db.cursor() as cur:
                cur.callproc("sp_secure_record_grade", (enrollment_id, assessment_id, score))
            saved = True
        except pymysql.MySQLError as exc:
            error = db_error_message(exc)
    return render_template(
        "grade/_cell.html",
        enrollment_id=enrollment_id,
        assessment_id=assessment_id,
        score=score,
        error=error,
        saved=saved,
    )


@bp.route("/mine")
@role_required("student")
def my_grades():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_my_grades ORDER BY DateRecorded DESC")
        rows = cur.fetchall()
    return render_template("grade/mine.html", rows=rows, letter_grade=letter_grade)