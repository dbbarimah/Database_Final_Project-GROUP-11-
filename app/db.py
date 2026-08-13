import pymysql
from flask import current_app, g, session


def get_db():
    """Open a PyMySQL connection as the logged-in user's own MariaDB
    account, for the duration of this request. A fresh connection per
    request (rather than one kept alive per session) means row-level
    access is always enforced by whatever that account is currently
    granted -- nothing cached from an earlier request.
    """
    if "db" not in g:
        creds = session.get("db_creds")
        g.db = pymysql.connect(
            host=current_app.config["DB_HOST"],
            port=current_app.config["DB_PORT"],
            user=creds["user"],
            password=creds["password"],
            database=current_app.config["DB_NAME"],
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=True,
        )
    return g.db


def close_db(exception=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()


def try_connect(username, password):
    """Used only by the login form: attempt a connection with credentials
    that are not yet trusted. Raises pymysql.err.OperationalError if they
    are wrong. Caller is responsible for closing the returned connection.
    """
    return pymysql.connect(
        host=current_app.config["DB_HOST"],
        port=current_app.config["DB_PORT"],
        user=username,
        password=password,
        database=current_app.config["DB_NAME"],
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True,
    )


def init_app(app):
    app.teardown_appcontext(close_db)
