from flask import Blueprint, render_template

from app.auth import require_login_before_request, require_role_before_request
from app.db import get_db

bp = Blueprint("reports", __name__, url_prefix="/reports")
bp.before_request(require_login_before_request)
bp.before_request(require_role_before_request("db_admin"))


def _attach_course_labels(db, raw_rows):
    """vw_AttendanceSummary only exposes a raw CourseID, no code/title --
    look those up separately rather than touching the Phase 6 view."""
    with db.cursor() as cur:
        cur.execute("SELECT CourseID, CourseCode, CourseTitle FROM Course")
        course_map = {row["CourseID"]: row for row in cur.fetchall()}
    for r in raw_rows:
        course = course_map.get(r["CourseID"], {})
        r["CourseCode"] = course.get("CourseCode", "—")
        r["CourseTitle"] = course.get("CourseTitle", "—")
    return raw_rows


REPORTS = {
    "student-averages": {
        "title": "Student Course Averages",
        "view": "vw_StudentCourseAverage",
        "group_by": lambda r: r["CourseTitle"],
        "group_label": "Course",
        "sort": lambda r: (r["CourseTitle"], r["Semester"], r["Lname"]),
        "columns": [
            ("Student", lambda r: f"{r['Fname']} {r['Lname']}"),
            ("Semester", lambda r: r["Semester"]),
            ("Weighted Average", lambda r: r["WeightedAverage"]),
        ],
    },
    "enrollment-summary": {
        "title": "Course Enrollment Summary",
        "view": "vw_CourseEnrollmentSummary",
        "group_by": lambda r: f"{r['CourseCode']} — {r['CourseTitle']}",
        "group_label": "Course",
        "sort": lambda r: (r["CourseCode"], r["Semester"]),
        "columns": [
            ("Semester", lambda r: r["Semester"]),
            ("Students Enrolled", lambda r: r["StudentsEnrolled"]),
        ],
    },
    "teaching-load": {
        "title": "Staff Teaching Load",
        "view": "vw_StaffTeachingLoad",
        "columns": [
            ("Staff", lambda r: f"{r['Fname']} {r['Lname']}"),
            ("Role", lambda r: r["Role"]),
            ("Semester", lambda r: r["Semester"]),
            ("Courses Assigned", lambda r: r["CoursesAssigned"]),
        ],
    },
    "attendance-summary": {
        "title": "Attendance Summary",
        "view": "vw_AttendanceSummary",
        "enrich": _attach_course_labels,
        "group_by": lambda r: f"{r['CourseCode']} — {r['CourseTitle']}",
        "group_label": "Course",
        "sort": lambda r: (r["CourseCode"], r["StudentName"]),
        "columns": [
            ("Student", lambda r: r["StudentName"]),
            ("Sessions Recorded", lambda r: r["SessionsRecorded"]),
            ("Sessions Present", lambda r: r["SessionsPresent"]),
            ("Attendance Rate %", lambda r: r["AttendanceRatePct"]),
        ],
    },
    "department-overview": {
        "title": "Department Overview",
        "view": "vw_DepartmentOverview",
        "columns": [
            ("Code", lambda r: r["DeptCode"]),
            ("Name", lambda r: r["DeptName"]),
            ("Head", lambda r: r["HeadOfDepartment"] or "—"),
            ("Staff", lambda r: r["StaffCount"]),
            ("Students", lambda r: r["StudentCount"]),
            ("Courses", lambda r: r["CourseCount"]),
        ],
    },
    "course-materials": {
        "title": "Course Material Summary",
        "view": "vw_CourseMaterialSummary",
        "columns": [
            ("Course", lambda r: f"{r['CourseCode']} — {r['CourseTitle']}"),
            ("Material Count", lambda r: r["MaterialCount"]),
            ("Last Uploaded", lambda r: r["LastUploaded"] or "—"),
        ],
    },
}


@bp.route("/")
def index():
    return render_template("reports/index.html", reports=REPORTS)


@bp.route("/<report_key>")
def show(report_key):
    spec = REPORTS.get(report_key)
    if spec is None:
        return render_template("404.html"), 404

    db = get_db()
    with db.cursor() as cur:
        cur.execute(f"SELECT * FROM {spec['view']}")
        raw_rows = cur.fetchall()

    if "enrich" in spec:
        raw_rows = spec["enrich"](db, raw_rows)

    if "group_by" in spec:
        group_by_fn = spec["group_by"]
        sort_fn = spec.get("sort", group_by_fn)
        for r in raw_rows:
            r["_group_key"] = group_by_fn(r)
        raw_rows.sort(key=lambda r: tuple(str(v) for v in sort_fn(r)))
        return render_template(
            "reports/grouped.html",
            title=spec["title"],
            columns=spec["columns"],
            rows=raw_rows,
            group_by="_group_key",
            group_label=spec.get("group_label", "Group"),
            report_key=report_key,
        )

    headers = [h for h, _ in spec["columns"]]
    rows = [[getter(r) for _, getter in spec["columns"]] for r in raw_rows]
    return render_template(
        "reports/show.html", title=spec["title"], headers=headers, rows=rows, report_key=report_key
    )
