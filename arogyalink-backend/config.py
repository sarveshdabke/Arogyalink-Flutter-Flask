from datetime import timedelta
import os

# config.py
class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'your_super_secret_key'
    SQLALCHEMY_DATABASE_URI = 'sqlite:///C:/Users/Main/arogyalink-backend/instance/site.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'your_jwt_secret_key'
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=45)

    # ✅ Email Configuration
    MAIL_SERVER = 'smtp.gmail.com'
    MAIL_PORT = 587
    MAIL_USE_TLS = True
    MAIL_USERNAME = os.environ.get('EMAIL_USER') or 'vaultlocker.official@gmail.com'
    MAIL_PASSWORD = os.environ.get('EMAIL_PASS') or 'dfcu rmmj qnwe oylz'
