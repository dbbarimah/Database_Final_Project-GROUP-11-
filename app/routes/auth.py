import pymysql
from flask import Blueprint, flash, redirect, render_template, request, session, url_for

from app.db import try_connect

bp = Blueprint("auth", __name__)


def _display_name(conn, role, username):
    """Best-effort friendly name for the navbar. Students have a
    self-profile view (v_my_profile); staff roles have no equivalent in
    security.sql (nobody but db_admin can read Staff), so we fall back to
    title-casing the login id, e.g. 'kwame.mensah' -> 'Kwame Mensah'."""
    if role == "student":
        try:
            with conn.cursor() as cur:
                cur.execute("SELECT Fname, Lname FROM v_my_profile")
                row = cur.fetchone()
                if row:
                    return f"{row['Fname']} {row['Lname']}"
        except pymysql.MySQLError:
            pass
    return username.replace(".", " ").title()


@bp.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")

        if not username or not password:
            flash("Enter both a username and a password.", "danger")
            return render_template("login.html")

        try:
            conn = try_connect(username, password)
        except pymysql.err.OperationalError:
            flash("Invalid username or password.", "danger")
            return render_template("login.html")

        try:
            with conn.cursor() as cur:
                cur.execute("SELECT CURRENT_ROLE() AS role")
                role = cur.fetchone()["role"]
            display_name = _display_name(conn, role, username)
        finally:
            conn.close()

        if not role:
            flash("This account has no role assigned. Contact the administrator.", "danger")
            return render_template("login.html")

        session.clear()
        session["db_creds"] = {"user": username, "password": password}
        session["role"] = role
        session["display_name"] = display_name
        return redirect(url_for("dashboard.index"))

    return render_template("login.html")


@bp.route("/logout")
def logout():
    session.clear()
    flash("You have been logged out.", "info")
    return redirect(url_for("auth.login"))
