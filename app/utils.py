import re

import pymysql
from flask import request

SEMESTER_PATTERN = re.compile(r"^[0-9]{4}-S[12]$")

ENROLLMENT_STATUS_CHOICES = ["Active", "Inactive", "Completed"]
ATTENDANCE_STATUS_CHOICES = ["Present", "Absent"]
ASSESSMENT_TYPE_CHOICES = ["Quiz", "Assignment", "MidSemester", "Exam"]
STAFF_ROLE_CHOICES = ["Lecturer", "Faculty Intern"]


def db_error_message(exc):
    """Turn a pymysql exception into a message safe to flash straight to
    the user. Business-rule violations (SIGNAL SQLSTATE '45000' from a
    trigger or sp_secure_* procedure) already read like a sentence -- e.g.
    'You are not assigned to this course for this semester.' -- so those
    are shown verbatim. Anything else gets a generic wrapper rather than
    leaking raw SQL internals.
    """
    if isinstance(exc, (pymysql.err.IntegrityError, pymysql.err.InternalError, pymysql.err.OperationalError)):
        if len(exc.args) >= 2 and isinstance(exc.args[1], str):
            return exc.args[1]
    return "A database error occurred and the action could not be completed."


def is_htmx():
    return request.headers.get("HX-Request") == "true"

def letter_grade(percent):
    if percent is None:
        return "N/A"
    if percent >= 90:
        return "A+"
    if percent >= 85:
        return "A"
    if percent >= 80:
        return "B+"
    if percent >= 75:
        return "B"
    if percent >= 70:
        return "C+"
    if percent >= 65:
        return "C"
    if percent >= 60:
        return "D+"
    if percent >= 55:
        return "D"
    return "F"