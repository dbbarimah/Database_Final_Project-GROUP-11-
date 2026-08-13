from flask import Blueprint, render_template

from app.auth import current_role, require_login_before_request
from app.db import get_db

bp = Blueprint("dashboard", __name__)
bp.before_request(require_login_before_request)

# Decorative course-card banner tones -- deliberately distinct from the
# functional status colors (ok/warn/danger/info) so a course's assigned
# color is never mistaken for a status signal.
BANNER_CLASSES = ["navy", "bronze", "forest", "slate", "plum"]


def _banner_class(course_code):
    return BANNER_CLASSES[sum(ord(c) for c in course_code) % len(BANNER_CLASSES)]


@bp.route("/")
def index():
    role = current_role()
    db = get_db()
    context = {"role": role}

    with db.cursor() as cur:
        if role == "db_admin":
            cur.execute("SELECT COUNT(*) AS n FROM Student")
            context["student_count"] = cur.fetchone()["n"]
            cur.execute("SELECT COUNT(*) AS n FROM Staff")
            context["staff_count"] = cur.fetchone()["n"]
            cur.execute("SELECT COUNT(*) AS n FROM Course")
            context["course_count"] = cur.fetchone()["n"]
            cur.execute("SELECT COUNT(*) AS n FROM Enrollment")
            context["enrollment_count"] = cur.fetchone()["n"]
            cur.execute("SELECT * FROM vw_DepartmentOverview")
            context["departments"] = cur.fetchall()

        elif role in ("lecturer", "faculty_intern"):
            cur.execute("SELECT * FROM v_my_teaching ORDER BY Semester DESC, CourseCode")
            teaching = cur.fetchall()
            for t in teaching:
                t["BannerClass"] = _banner_class(t["CourseCode"])
            context["teaching"] = teaching

        elif role == "student":
            cur.execute("SELECT * FROM v_my_profile")
            context["profile"] = cur.fetchone()
            cur.execute(
                "SELECT * FROM v_my_enrollments ORDER BY Semester DESC, CourseCode"
            )
            enrollments = cur.fetchall()
            for e in enrollments:
                e["BannerClass"] = _banner_class(e["CourseCode"])
            context["enrollments"] = enrollments

    return render_template("dashboard.html", **context)
