import pymysql
from flask import Blueprint, flash, redirect, render_template, request, url_for

from app.auth import current_role, require_login_before_request, role_required
from app.db import get_db
from app.utils import db_error_message, is_htmx

bp = Blueprint("department", __name__, url_prefix="/departments")
bp.before_request(require_login_before_request)


@bp.route("/")
def list_departments():
    db = get_db()
    with db.cursor() as cur:
        if current_role() == "db_admin":
            # Only db_admin has any grant on Staff (security.sql), so the
            # head-of-department name can only be resolved here.
            cur.execute(
                """SELECT d.DepartmentID, d.DeptCode, d.DeptName,
                          s.Fname AS HeadFname, s.Lname AS HeadLname
                     FROM Department d
                     LEFT JOIN Staff s ON s.StaffID = d.HeadID
                    ORDER BY d.DeptCode"""
            )
        else:
            cur.execute(
                "SELECT DepartmentID, DeptCode, DeptName FROM Department ORDER BY DeptCode"
            )
        departments = cur.fetchall()
    return render_template("department/list.html", departments=departments)


@bp.route("/new", methods=["GET", "POST"])
@role_required("db_admin")
def create_department():
    db = get_db()
    if request.method == "POST":
        try:
            with db.cursor() as cur:
                cur.execute(
                    "INSERT INTO Department (DeptCode, DeptName, HeadID) VALUES (%s, %s, %s)",
                    (
                        request.form["dept_code"].strip(),
                        request.form["dept_name"].strip(),
                        request.form.get("head_id") or None,
                    ),
                )
            flash("Department created.", "success")
            return redirect(url_for("department.list_departments"))
        except pymysql.MySQLError as exc:
            flash(db_error_message(exc), "danger")

    with db.cursor() as cur:
        cur.execute("SELECT StaffID, Fname, Lname FROM Staff ORDER BY Lname")
        staff = cur.fetchall()
    return render_template("department/form.html", department=None, staff=staff)


@bp.route("/<int:department_id>/edit", methods=["GET", "POST"])
@role_required("db_admin")
def edit_department(department_id):
    db = get_db()
    if request.method == "POST":
        try:
            with db.cursor() as cur:
                cur.execute(
                    "UPDATE Department SET DeptCode=%s, DeptName=%s, HeadID=%s WHERE DepartmentID=%s",
                    (
                        request.form["dept_code"].strip(),
                        request.form["dept_name"].strip(),
                        request.form.get("head_id") or None,
                        department_id,
                    ),
                )
            flash("Department updated.", "success")
            return redirect(url_for("department.list_departments"))
        except pymysql.MySQLError as exc:
            flash(db_error_message(exc), "danger")

    with db.cursor() as cur:
        cur.execute("SELECT * FROM Department WHERE DepartmentID=%s", (department_id,))
        department = cur.fetchone()
        cur.execute("SELECT StaffID, Fname, Lname FROM Staff ORDER BY Lname")
        staff = cur.fetchall()
    if department is None:
        flash("Department not found.", "warning")
        return redirect(url_for("department.list_departments"))
    return render_template("department/form.html", department=department, staff=staff)


@bp.route("/<int:department_id>/delete", methods=["POST"])
@role_required("db_admin")
def delete_department(department_id):
    db = get_db()
    try:
        with db.cursor() as cur:
            cur.execute("DELETE FROM Department WHERE DepartmentID=%s", (department_id,))
    except pymysql.MySQLError as exc:
        if is_htmx():
            return db_error_message(exc), 400
        flash(db_error_message(exc), "danger")
        return redirect(url_for("department.list_departments"))
    if is_htmx():
        return "", 200
    flash("Department deleted.", "success")
    return redirect(url_for("department.list_departments"))
