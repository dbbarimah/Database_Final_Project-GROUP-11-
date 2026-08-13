import os

from flask import Flask
from flask_session import Session
from flask_wtf import CSRFProtect

from app import db
from app.config import Config

csrf = CSRFProtect()


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    Config.INSTANCE_DIR.mkdir(exist_ok=True)
    Config.UPLOAD_FOLDER.mkdir(exist_ok=True)
    os.makedirs(Config.SESSION_FILE_DIR, exist_ok=True)

    Session(app)
    csrf.init_app(app)
    db.init_app(app)

    from app.routes.auth import bp as auth_bp
    from app.routes.dashboard import bp as dashboard_bp
    from app.routes.department import bp as department_bp
    from app.routes.course import bp as course_bp
    from app.routes.staff import bp as staff_bp
    from app.routes.student import bp as student_bp
    from app.routes.teaching_assignment import bp as teaching_assignment_bp
    from app.routes.enrollment import bp as enrollment_bp
    from app.routes.attendance import bp as attendance_bp
    from app.routes.assessment import bp as assessment_bp
    from app.routes.grade import bp as grade_bp
    from app.routes.course_material import bp as course_material_bp
    from app.routes.reports import bp as reports_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(dashboard_bp)
    app.register_blueprint(department_bp)
    app.register_blueprint(course_bp)
    app.register_blueprint(staff_bp)
    app.register_blueprint(student_bp)
    app.register_blueprint(teaching_assignment_bp)
    app.register_blueprint(enrollment_bp)
    app.register_blueprint(attendance_bp)
    app.register_blueprint(assessment_bp)
    app.register_blueprint(grade_bp)
    app.register_blueprint(course_material_bp)
    app.register_blueprint(reports_bp)

    from app.auth import current_display_name, current_login, current_role

    @app.context_processor
    def inject_user():
        return {
            "current_role": current_role(),
            "current_login": current_login(),
            "current_display_name": current_display_name(),
        }

    from app.errors import register_error_handlers

    register_error_handlers(app)

    return app
