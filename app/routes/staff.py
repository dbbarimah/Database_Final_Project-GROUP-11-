import pymysql
from flask import Blueprint, flash, redirect, render_template, request, url_for

from app.auth import require_login_before_request, require_role_before_request
from app.db import get_db
from app.utils import STAFF_ROLE_CHOICES, db_error_message, is_htmx

bp = Blueprint("staff", __name__, url_prefix="/staff")
bp.before_request(require_login_before_request)
bp.before_request(require_role_before_request("db_admin"))


@bp.route("/")
def list_staff():
    db = get_db()
    with db.cursor() as cur:
        cur.execute(
            """SELECT st.StaffID, st.Fname, st.Lname, st.StaffEmail, st.StaffPhone,
                      st.Role, d.DeptCode
                 FROM Staff st JOIN Department d ON d.DepartmentID = st.DepartmentID
                ORDER BY st.Lname"""
        )
        staff = cur.fetchall()
    return render_template("staff/list.html", staff=staff)


@bp.route("/new", methods=["GET", "POST"])
def create_staff():
    db = get_db()
    if request.method == "POST":
        try:
            with db.cursor() as cur:
                cur.execute(
                    """INSERT INTO Staff (Fname, Lname, StaffEmail, StaffPhone, Role, DepartmentID)
                       VALUES (%s, %s, %s, %s, %s, %s)""",
                    (
                        request.form["fname"].strip(),
                        request.form["lname"].strip(),
                        request.form["email"].strip(),
                        request.form.get("phone", "").strip() or None,
                        request.form["role"],
                        request.form["department_id"],
                    ),
                )
            flash("Staff member created.", "success")
            return redirect(url_for("staff.list_staff"))
        except pymysql.MySQLError as exc:
            flash(db_error_message(exc), "danger")

    with db.cursor() as cur:
        cur.execute("SELECT DepartmentID, DeptCode FROM Department ORDER BY DeptCode")
        departments = cur.fetchall()
    return render_template(
        "staff/form.html", staff_member=None, departments=departments, role_choices=STAFF_ROLE_CHOICES
    )


@bp.route("/<int:staff_id>/edit", methods=["GET", "POST"])
def edit_staff(staff_id):
    db = get_db()
    if request.method == "POST":
        try:
            with db.cursor() as cur:
                cur.execute(
                    """UPDATE Staff SET Fname=%s, Lname=%s, StaffEmail=%s, StaffPhone=%s,
                              Role=%s, DepartmentID=%s WHERE StaffID=%s""",
                    (
                        request.form["fname"].strip(),
                        request.form["lname"].strip(),
                        request.form["email"].strip(),
                        request.form.get("phone", "").strip() or None,
                        request.form["role"],
                        request.form["department_id"],
                        staff_id,
                    ),
                )
            flash("Staff member updated.", "success")
            return redirect(url_for("staff.list_staff"))
        except pymysql.MySQLError as exc:
            flash(db_error_message(exc), "danger")

    with db.cursor() as cur:
        cur.execute("SELECT * FROM Staff WHERE StaffID=%s", (staff_id,))
        staff_member = cur.fetchone()
        cur.execute("SELECT DepartmentID, DeptCode FROM Department ORDER BY DeptCode")
        departments = cur.fetchall()
    if staff_member is None:
        flash("Staff member not found.", "warning")
        return redirect(url_for("staff.list_staff"))
    return render_template(
        "staff/form.html", staff_member=staff_member, departments=departments, role_choices=STAFF_ROLE_CHOICES
    )


@bp.route("/<int:staff_id>/delete", methods=["POST"])
def delete_staff(staff_id):
    db = get_db()
    try:
        with db.cursor() as cur:
            cur.execute("DELETE FROM Staff WHERE StaffID=%s", (staff_id,))
    except pymysql.MySQLError as exc:
        if is_htmx():
            return db_error_message(exc), 400
        flash(db_error_message(exc), "danger")
        return redirect(url_for("staff.list_staff"))
    if is_htmx():
        return "", 200
    flash("Staff member deleted.", "success")
    return redirect(url_for("staff.list_staff"))
