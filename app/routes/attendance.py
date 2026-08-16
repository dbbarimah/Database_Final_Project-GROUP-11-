import pymysql
from flask import Blueprint, flash, redirect, render_template, request, url_for

from app.auth import require_login_before_request, role_required
from app.db import get_db
from app.utils import ATTENDANCE_STATUS_CHOICES, db_error_message, is_htmx

bp = Blueprint("attendance", __name__, url_prefix="/attendance")
bp.before_request(require_login_before_request)


@bp.route("/")
@role_required("db_admin")
def list_attendance():
    db = get_db()
    with db.cursor() as cur:
        cur.execute(
            """SELECT at.AttendanceID, at.SessionDate, at.AttendanceStatus,
                      s.Fname, s.Lname, c.CourseCode, e.Semester
                 FROM Attendance at
                 JOIN Enrollment e ON e.EnrollmentID = at.EnrollmentID
                 JOIN Student s ON s.StudentID = e.StudentID
                 JOIN Course c ON c.CourseID = e.CourseID
                ORDER BY at.SessionDate DESC"""
        )
        rows = cur.fetchall()
    return render_template("attendance/list.html", rows=rows)


@bp.route("/<int:attendance_id>/delete", methods=["POST"])
@role_required("db_admin")
def delete_attendance(attendance_id):
    db = get_db()
    try:
        with db.cursor() as cur:
            cur.execute("DELETE FROM Attendance WHERE AttendanceID=%s", (attendance_id,))
    except pymysql.MySQLError as exc:
        if is_htmx():
            return db_error_message(exc), 400
        flash(db_error_message(exc), "danger")
        return redirect(url_for("attendance.list_attendance"))
    if is_htmx():
        return "", 200
    flash("Attendance record deleted.", "success")
    return redirect(url_for("attendance.list_attendance"))


@bp.route("/class")
@role_required("lecturer", "faculty_intern")
def class_attendance():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_class_attendance ORDER BY SessionDate DESC")
        rows = cur.fetchall()
        cur.execute("SELECT * FROM v_my_teaching ORDER BY Semester DESC, CourseCode")
        teaching = cur.fetchall()
    return render_template("attendance/class.html", rows=rows, teaching=teaching)


@bp.route("/record")
@role_required("lecturer", "faculty_intern")
def record_attendance():
    db = get_db()
    course_id = request.args.get("course_id", type=int)
    semester = request.args.get("semester", "")
    session_date = request.args.get("session_date", "")

    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_my_teaching ORDER BY Semester DESC, CourseCode")
        teaching = cur.fetchall()
        roster = []
        if course_id and semester:
            cur.execute(
                """SELECT * FROM v_class_list WHERE CourseID=%s AND Semester=%s
                    ORDER BY Lname""",
                (course_id, semester),
            )
            roster = cur.fetchall()
            if session_date:
                # Pre-fill with whatever's already recorded for this date,
                # so picking a past session shows the existing roll call.
                cur.execute(
                    "SELECT EnrollmentID, AttendanceStatus FROM v_class_attendance WHERE SessionDate=%s",
                    (session_date,),
                )
                existing = {row["EnrollmentID"]: row["AttendanceStatus"] for row in cur.fetchall()}
                for r in roster:
                    r["ExistingStatus"] = existing.get(r["EnrollmentID"])

    return render_template(
        "attendance/record.html",
        teaching=teaching,
        roster=roster,
        course_id=course_id,
        semester=semester,
        session_date=session_date,
        status_choices=ATTENDANCE_STATUS_CHOICES,
    )


@bp.route("/cell", methods=["POST"])
@role_required("lecturer", "faculty_intern")
def save_cell():
    db = get_db()
    enrollment_id = request.form["enrollment_id"]
    session_date = request.form.get("session_date", "").strip()
    status = request.form.get("status", "")
    error = None
    saved = False
    if not session_date:
        error = "Pick a session date above first."
    elif status:
        try:
            with db.cursor() as cur:
                cur.callproc("sp_secure_record_attendance", (enrollment_id, session_date, status))
            saved = True
        except pymysql.MySQLError as exc:
            error = db_error_message(exc)
    return render_template(
        "attendance/_cell.html",
        enrollment_id=enrollment_id,
        status=status,
        error=error,
        saved=saved,
        status_choices=ATTENDANCE_STATUS_CHOICES,
    )


@bp.route("/mine")
@role_required("student")
def my_attendance():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_my_attendance ORDER BY SessionDate DESC")
        rows = cur.fetchall()
    return render_template("attendance/mine.html", rows=rows)
