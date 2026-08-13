import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-only-insecure-key")

    DB_HOST = os.environ.get("DB_HOST", "127.0.0.1")
    DB_PORT = int(os.environ.get("DB_PORT", "3306"))
    DB_NAME = os.environ.get("DB_NAME", "group11_finalproject")

    INSTANCE_DIR = BASE_DIR / "instance"
    UPLOAD_FOLDER = INSTANCE_DIR / "uploads"
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16 MB per uploaded file

    SESSION_TYPE = "filesystem"
    SESSION_FILE_DIR = str(INSTANCE_DIR / "flask_session")
    SESSION_PERMANENT = False
