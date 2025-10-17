from flask import Flask
from flask_migrate import Migrate
from config import Config
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from models import db
from flask_mail import Mail
from routes.admin import admin_routes
from routes.auth_routes import auth_bp
from routes.patient import patient_bp 
from routes.doctor import doctor_routes
from feedback import feedback_bp 

app = Flask(__name__, static_folder='static', static_url_path='/static') # ✅ Fix 1: Correct __name__
app.config.from_object(Config)
migrate = Migrate(app, db)

# Initialize Extensions
db.init_app(app)
jwt = JWTManager(app)
mail = Mail(app)
# ✅ Fix 2: Allow all origins for testing
CORS(app, resources={r"/api/*": {"origins": "*"}})

# Register Blueprints
app.register_blueprint(auth_bp)
app.register_blueprint(patient_bp, url_prefix='/api/patient')
app.register_blueprint(admin_routes, url_prefix='/api/admin')
app.register_blueprint(doctor_routes, url_prefix='/api/doctor')
app.register_blueprint(feedback_bp, url_prefix='/api/feedback')

if __name__ == '__main__':  # ✅ Fix 1 continued
    with app.app_context():
        db.create_all()
    print("JWT Expiry:", app.config["JWT_ACCESS_TOKEN_EXPIRES"])
    app.run(host='0.0.0.0', port=5000, debug=True)