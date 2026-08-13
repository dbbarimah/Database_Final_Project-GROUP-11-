from functools import wraps

from flask import abort, flash, redirect, session, url_for


def current_role():
    return session.get("role")


def current_login():
    """The local part of the account's email, e.g. 'ama.amoako' -- also
    the MariaDB username."""
    return session.get("db_creds", {}).get("user")


def current_display_name():
    return session.get("display_name") or current_login()


def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if "db_creds" not in session:
            return redirect(url_for("auth.login"))
        return view(*args, **kwargs)

    return wrapped


def require_login_before_request():
    """Registered as a blueprint-level before_request hook on every
    blueprint except auth itself, so individual view functions don't each
    need @login_required."""
    if "db_creds" not in session:
        return redirect(url_for("auth.login"))


def role_required(*roles):
    """UX-level gating only -- hides/blocks routes a role has no business
    reaching. The database is the real enforcement: even if this check is
    somehow bypassed, the underlying GRANTs in security.sql still decide
    what the connection can actually do.
    """

    def decorator(view):
        @wraps(view)
        def wrapped(*args, **kwargs):
            if current_role() not in roles:
                flash("You don't have access to that page.", "danger")
                abort(403)
            return view(*args, **kwargs)

        return wrapped

    return decorator


def require_role_before_request(*roles):
    """Like role_required, but returns a plain callable for use with
    bp.before_request(...) instead of decorating a single view -- for
    blueprints (e.g. Staff) that are gated to one role in their entirety.
    """

    def check():
        if current_role() not in roles:
            flash("You don't have access to that page.", "danger")
            abort(403)

    return check
