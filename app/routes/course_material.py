import uuid

import pymysql
from flask import Blueprint, current_app, flash, redirect, render_template, request, send_from_directory, url_for
from werkzeug.utils import secure_filename

from app.auth import current_role, require_login_before_request, role_required
from app.db import get_db
from app.utils import db_error_message, is_htmx

bp = Blueprint("course_material", __name__, url_prefix="/materials")
bp.before_request(require_login_before_request)


def _save_upload(file_storage):
    filename = secure_filename(file_storage.filename)
    stored_name = f"{uuid.uuid4().hex}_{filename}"
    file_storage.save(current_app.config["UPLOAD_FOLDER"] / stored_name)
    return stored_name


@bp.route("/")
@role_required("db_admin")
def list_materials():
    db = get_db()
    with db.cursor() as cur:
        cur.execute(
            """SELECT m.MaterialID, m.MaterialTitle, m.FilePath, m.DateUploaded, c.CourseCode
                 FROM CourseMaterial m JOIN Course c ON c.CourseID = m.CourseID
                ORDER BY m.DateUploaded DESC"""
        )
        materials = cur.fetchall()
    return render_template("course_material/list.html", materials=materials)


@bp.route("/new", methods=["GET", "POST"])
@role_required("db_admin")
def create_material():
    db = get_db()
    if request.method == "POST":
        upload = request.files.get("file")
        if not upload or not upload.filename:
            flash("Choose a file to upload.", "danger")
        else:
            try:
                stored_name = _save_upload(upload)
                with db.cursor() as cur:
                    cur.execute(
                        """INSERT INTO CourseMaterial (CourseID, MaterialTitle, FilePath, DateUploaded)
                           VALUES (%s, %s, %s, CURDATE())""",
                        (request.form["course_id"], request.form["title"].strip(), stored_name),
                    )
                flash("Course material uploaded.", "success")
                return redirect(url_for("course_material.list_materials"))
            except pymysql.MySQLError as exc:
                flash(db_error_message(exc), "danger")

    with db.cursor() as cur:
        cur.execute("SELECT CourseID, CourseCode FROM Course ORDER BY CourseCode")
        courses = cur.fetchall()
    return render_template("course_material/form.html", courses=courses)


@bp.route("/<int:material_id>/delete", methods=["POST"])
@role_required("db_admin")
def delete_material(material_id):
    db = get_db()
    try:
        with db.cursor() as cur:
            cur.execute("DELETE FROM CourseMaterial WHERE MaterialID=%s", (material_id,))
    except pymysql.MySQLError as exc:
        if is_htmx():
            return db_error_message(exc), 400
        flash(db_error_message(exc), "danger")
        return redirect(url_for("course_material.list_materials"))
    if is_htmx():
        return "", 200
    flash("Course material deleted.", "success")
    return redirect(url_for("course_material.list_materials"))


@bp.route("/class")
@role_required("lecturer", "faculty_intern")
def class_materials():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_class_materials ORDER BY DateUploaded DESC")
        rows = cur.fetchall()
        cur.execute("SELECT * FROM v_my_teaching ORDER BY Semester DESC, CourseCode")
        teaching = cur.fetchall()
    return render_template("course_material/class.html", rows=rows, teaching=teaching)


@bp.route("/class/new", methods=["GET", "POST"])
@role_required("lecturer", "faculty_intern")
def upload_class_material():
    db = get_db()
    if request.method == "POST":
        upload = request.files.get("file")
        if not upload or not upload.filename:
            flash("Choose a file to upload.", "danger")
        else:
            try:
                stored_name = _save_upload(upload)
                with db.cursor() as cur:
                    cur.callproc(
                        "sp_secure_add_material",
                        (
                            request.form["course_id"],
                            request.form["semester"],
                            request.form["title"].strip(),
                            stored_name,
                        ),
                    )
                flash("Course material uploaded.", "success")
                return redirect(url_for("course_material.class_materials"))
            except pymysql.MySQLError as exc:
                flash(db_error_message(exc), "danger")

    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_my_teaching ORDER BY Semester DESC, CourseCode")
        teaching = cur.fetchall()
    return render_template("course_material/upload.html", teaching=teaching)


@bp.route("/mine")
@role_required("student")
def my_materials():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("SELECT * FROM v_my_course_materials ORDER BY DateUploaded DESC")
        rows = cur.fetchall()
    return render_template("course_material/mine.html", rows=rows)


@bp.route("/download/<path:stored_name>")
def download(stored_name):
    db = get_db()
    role = current_role()
    with db.cursor() as cur:
        if role == "db_admin":
            cur.execute("SELECT MaterialTitle FROM CourseMaterial WHERE FilePath=%s", (stored_name,))
        elif role == "student":
            cur.execute("SELECT MaterialTitle FROM v_my_course_materials WHERE FilePath=%s", (stored_name,))
        elif role in ("lecturer", "faculty_intern"):
            cur.execute("SELECT MaterialTitle FROM v_class_materials WHERE FilePath=%s", (stored_name,))
        else:
            cur.execute("SELECT NULL WHERE FALSE")
        row = cur.fetchone()

    if row is None:
        flash("That file isn't available to you.", "danger")
        return redirect(url_for("dashboard.index"))

    return send_from_directory(
        current_app.config["UPLOAD_FOLDER"], stored_name, as_attachment=True
    )
