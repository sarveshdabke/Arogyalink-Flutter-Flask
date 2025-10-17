import os
from werkzeug.utils import secure_filename
from flask import Blueprint, current_app, request, jsonify, render_template, url_for
from models import Doctor, OPDSlot, db, Patient, Admin # Assuming Admin and Patient are defined in models.py
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from flask_cors import CORS
from flask_mail import Mail, Message
from datetime import date, datetime, timedelta
import random
import logging
from werkzeug.security import check_password_hash
from sqlalchemy.exc import OperationalError
import secrets # New import for secure token generation

# Setup logging
logging.basicConfig(level=logging.INFO)

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'pdf'}
mail = Mail() 
otp_storage = {}

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS
def generate_slots(doctor_id, hospital_id, start_time_str, end_time_str, days_to_generate=7, start_date=None):
   
    if not start_date:
        start_date = date.today()

    # Helper function to parse time strings
    def parse_time_str(time_str):
        try:
            # Try 24-hour format
            return datetime.strptime(time_str, "%H:%M").time()
        except ValueError:
            # Try 12-hour format with AM/PM
            return datetime.strptime(time_str, "%I %p").time()

    start_time_obj = parse_time_str(start_time_str)
    end_time_obj = parse_time_str(end_time_str)

    for day_offset in range(days_to_generate):
        slot_date = start_date + timedelta(days=day_offset)
        current_time = datetime.combine(slot_date, start_time_obj)
        end_datetime = datetime.combine(slot_date, end_time_obj)

        while current_time + timedelta(minutes=20) <= end_datetime:
            # Check if slot already exists to avoid duplicates
            existing = OPDSlot.query.filter_by(
                doctor_id=doctor_id,
                appointment_date=slot_date.strftime("%Y-%m-%d"),
                start_time=current_time.strftime("%H:%M")
            ).first()

            if not existing:
                slot = OPDSlot(
                    doctor_id=doctor_id,
                    hospital_id=hospital_id,
                    appointment_date=slot_date.strftime("%Y-%m-%d"),
                    start_time=current_time.strftime("%H:%M"),
                    end_time=(current_time + timedelta(minutes=20)).strftime("%H:%M"),
                    is_booked=False
                )
                db.session.add(slot)

            current_time += timedelta(minutes=20)

    db.session.commit()

auth_bp = Blueprint('auth', __name__)
CORS(auth_bp)

# ------------------ Patient Registration ------------------ #
@auth_bp.route('/api/patient/register', methods=['POST'])
def patient_register():
    data = request.get_json()
    try:
        # Required fields
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')

        if not username or not email or not password:
            return jsonify({'message': 'Username, email, and password are required'}), 400

        if Patient.query.filter_by(username=username).first():
            return jsonify({'message': 'Username already exists'}), 409
        if Patient.query.filter_by(email=email).first():
            return jsonify({'message': 'Email already exists'}), 409

        # Optional/additional fields
        date_of_birth = data.get('date_of_birth')
        age = data.get('age') # <--- RETRIEVED AGE HERE
        gender = data.get('gender')
        mobile_number = data.get('mobile_number')
        residential_address = data.get('residential_address')
        emergency_contact_name = data.get('emergency_contact_name')
        emergency_contact_number = data.get('emergency_contact_number')
        blood_group = data.get('blood_group')
        known_allergies = data.get('known_allergies')
        chronic_illnesses = data.get('chronic_illnesses')
        current_medications = data.get('current_medications')
        past_surgeries = data.get('past_surgeries')
        vaccination_details = data.get('vaccination_details')
        country = data.get('country')
        state = data.get('state')

        new_patient = Patient(
            username=username,
            email=email,
            date_of_birth=date_of_birth,
            age=age, # <--- PASSED AGE HERE
            gender=gender,
            mobile_number=mobile_number,
            residential_address=residential_address,
            emergency_contact_name=emergency_contact_name,
            emergency_contact_number=emergency_contact_number,
            blood_group=blood_group,
            known_allergies=known_allergies,
            chronic_illnesses=chronic_illnesses,
            current_medications=current_medications,
            past_surgeries=past_surgeries,
            vaccination_details=vaccination_details,
            country=country,
            state=state
        )
        new_patient.set_password(password)

        db.session.add(new_patient)
        db.session.commit()

        return jsonify({'success': True, 'message': 'Patient registered successfully'}), 201
    except OperationalError as e:
        db.session.rollback()
        logging.error("Database is locked error:", exc_info=True)
        return jsonify({'success': False, 'message': 'A temporary database error occurred. Please try again.'}), 503
    except Exception as e:
        db.session.rollback()
        logging.error("An unexpected error occurred during patient registration:", exc_info=True)
        return jsonify({'success': False, 'message': 'An internal error occurred. Please try again.'}), 500
# ------------------ Patient Login ------------------ #
@auth_bp.route('/api/patient/login', methods=['POST'])
def patient_login():
    data = request.get_json()
    identifier = data.get('identifier')
    password = data.get('password')

    if not identifier or not password:
        return jsonify({'message': 'Identifier and password are required'}), 400

    patient = Patient.query.filter_by(username=identifier).first() or Patient.query.filter_by(email=identifier).first()

    if patient and patient.check_password(password):
        access_token = create_access_token(identity=str(patient.id))
        return jsonify(access_token=access_token, user=patient.to_dict()), 200

    return jsonify({'message': 'Invalid identifier or password'}), 401

# ------------------ Admin Registration ------------------ #
@auth_bp.route('/api/admin/register', methods=['POST'])
def admin_register():
    try:
        logging.info("--- Admin Registration Attempt ---")
        logging.info("Request Headers: %s", request.headers)
        logging.info("Request Form Data: %s", request.form)
        logging.info("Request Files: %s", request.files)

        # --- STEP 1: Access Text Fields using request.form ---
        hospital_name = request.form.get('hospital_name')
        email = request.form.get('email')
        password = request.form.get('password')
        license_number = request.form.get('license_number')
        upi_id = request.form.get('upi_id')
        admission_fees_str = request.form.get('admission_fees') # ✅ Get the string value

        admission_fees = None
        if admission_fees_str:
            try:
                admission_fees = float(admission_fees_str) # Convert to float
            except (ValueError, TypeError):
                return jsonify({'message': 'Admission Fees must be a valid number.'}), 400

        try:
            latitude = float(request.form.get('latitude'))
            longitude = float(request.form.get('longitude'))
        except (ValueError, TypeError):
            return jsonify({'message': 'Latitude and Longitude must be valid numbers.'}), 400

        if not hospital_name or not email or not password or not license_number:
            logging.warning("Missing required fields.")
            return jsonify({'message': 'Hospital Name, email, password, and license number are required'}), 400

        # Check if UPI ID and Admission Fees are provided
        if not upi_id:
            logging.warning("UPI ID not provided.")
            return jsonify({'message': 'UPI ID is required for payments'}), 400

        if admission_fees is None:
            logging.warning("Admission Fees not provided.")
            return jsonify({'message': 'Admission Fees are required'}), 400

        # Check for existing admin email BEFORE file operations
        logging.info("Checking for existing admin with email: %s", email)
        if Admin.query.filter_by(email=email).first():
            logging.warning("Email already exists: %s", email)
            return jsonify({'message': 'An admin with this email already exists'}), 409

        # --- STEP 2: Handle Files and read binary data directly ---
        registration_certificate_binary = None
        admin_id_proof_binary = None
        hospital_logo_binary = None
        reg_cert_filename = None
        admin_id_proof_filename = None

        # Handle Registration Certificate (read binary data)
        reg_cert = request.files.get('registration_doc')
        if reg_cert and reg_cert.filename != '' and allowed_file(reg_cert.filename):
            registration_certificate_binary = reg_cert.read()
            reg_cert_filename = secure_filename(reg_cert.filename)
            logging.info("Registration certificate read into binary data.")

        # Handle Admin ID Proof (read binary data)
        admin_id_proof_file = request.files.get('admin_id')
        if admin_id_proof_file and admin_id_proof_file.filename != '' and allowed_file(admin_id_proof_file.filename):
            admin_id_proof_binary = admin_id_proof_file.read()
            admin_id_proof_filename = secure_filename(admin_id_proof_file.filename)
            logging.info("Admin ID proof read into binary data.")

        # Handle Hospital Logo (read binary data)
        hospital_logo = request.files.get('logo')
        if hospital_logo and hospital_logo.filename != '' and allowed_file(hospital_logo.filename):
            hospital_logo_binary = hospital_logo.read()
            logging.info("Hospital logo read into binary data.")

        # ✅ NEW: Generate secure tokens for approval links
        approval_token = secrets.token_urlsafe(32)
        rejection_token = secrets.token_urlsafe(32)

        # --- STEP 3: Create and save the new Admin/Hospital entry ---
        new_admin = Admin(
            email=email,
            hospital_name=hospital_name,
            hospital_type=request.form.get('hospital_type'),
            owner_name=request.form.get('owner_name'),
            contact=request.form.get('contact'),
            alt_contact=request.form.get('alt_contact'),
            address=request.form.get('address'),
            state=request.form.get('state'),
            country=request.form.get('country'),
            latitude=latitude,
            longitude=longitude,
            # Note: request.form.get returns a string, so we check for 'true' (case-insensitive)
            emergency=request.form.get('emergency', 'false').lower() == 'true',
            departments=request.form.get('departments'),
            opd_available=request.form.get('opd_available', 'false').lower() == 'true',
            opd_start_time=request.form.get('opd_start_time'),
            opd_end_time=request.form.get('opd_end_time'),
            license_number=license_number,
            upi_id=upi_id,
            admission_fees=admission_fees, # ✅ Store new field
            status='pending',
            registration_certificate=registration_certificate_binary,
            admin_id_proof=admin_id_proof_binary,
            hospital_logo=hospital_logo_binary,
            approval_token=approval_token,
            rejection_token=rejection_token
        )
        logging.info("New Admin object created for hospital: %s", new_admin.hospital_name)
        new_admin.set_password(password)

        db.session.add(new_admin)
        db.session.commit()
        logging.info("New Admin registration successful for email: %s", email)

        # --- STEP 4: Send the email with clickable approval/rejection links ---
        try:
            # Assumes 'auth.approve_admin_with_token' and 'auth.reject_admin_with_token' are defined
            approval_url = url_for('auth.approve_admin_with_token', token=approval_token, _external=True)
            rejection_url = url_for('auth.reject_admin_with_token', token=rejection_token, _external=True)

            msg = Message(
                subject="New Admin Registration for Approval",
                sender=current_app.config['MAIL_USERNAME'],
                recipients=['dabkesarvesh7@gmail.com']
            )

            msg.html = f"""
                <h2>New Admin Registration Request</h2>
                <p>A new admin has registered and is awaiting your approval.</p>
                <ul>
                    <li><b>Hospital Name:</b> {hospital_name}</li>
                    <li><b>License Number:</b> {license_number}</li>
                    <li><b>Registered Email:</b> {email}</li>
                    <li><b>UPI ID:</b> {upi_id}</li>
                    <li><b>Admission Fees:</b> {admission_fees}</li>
                </ul>
                <p>To review the request and documents, please use the links below.</p>
                <br>
                <a href="{approval_url}" target="_blank">Approve</a> |
                <a href="{rejection_url}" target="_blank">Reject</a>
            """

            if registration_certificate_binary and reg_cert_filename:
                msg.attach(reg_cert_filename, 'application/octet-stream', registration_certificate_binary)

            if admin_id_proof_binary and admin_id_proof_filename:
                msg.attach(admin_id_proof_filename, 'application/octet-stream', admin_id_proof_binary)

            mail.send(msg)
            logging.info("Approval email with links sent successfully.")

        except Exception as email_error:
            logging.error(f"Failed to send approval email: {email_error}", exc_info=True)
            return jsonify({'success': True, 'message': 'Hospital registration successful, but email notification failed. The account is pending approval.'}), 201

        return jsonify({'success': True, 'message': 'Hospital registration successful. An approval email has been sent.'}), 201

    except OperationalError as e:
        db.session.rollback()
        logging.error("Database is locked error:", exc_info=True)
        return jsonify({'success': False, 'message': 'A temporary database error occurred. Please try again.'}), 503
    except Exception as e:
        db.session.rollback()
        logging.error("An unexpected error occurred during admin registration:", exc_info=True)
        return jsonify({'success': False, 'message': 'An internal error occurred. Please try again.'}), 500
# ------------------ Admin Login ------------------ #
@auth_bp.route('/api/admin/login', methods=['POST'])
def admin_login():
    data = request.get_json()
    identifier = data.get('identifier')
    password = data.get('password')

    if not identifier or not password:
        return jsonify({'message': 'Identifier and password are required'}), 400

    admin = Admin.query.filter_by(email=identifier).first()
    
    # --- Debugging Log to inspect the database value ---
    if admin:
        # Normalize the status string to remove leading/trailing whitespace and convert to lowercase
        normalized_status = admin.status.strip().lower()
        logging.info("Login attempt for admin: %s. Status from DB (normalized) is: '%s'", admin.email, normalized_status)
    else:
        logging.warning("Login attempt failed: Admin with identifier %s not found.", identifier)
    # --- End Debugging Log ---

    if admin and admin.check_password(password):
        # Now compare against the normalized status
        if admin.status and admin.status.strip().lower() == 'approved':
            access_token = create_access_token(identity=str(admin.id))
            return jsonify(access_token=access_token, user=admin.to_dict()), 200
        elif admin.status and admin.status.strip().lower() == 'pending':
            return jsonify({'message': 'Your registration is awaiting approval. Please check back later.'}), 401
        else:
            return jsonify({'message': 'Your account is not active.'}), 401

    return jsonify({'message': 'Invalid identifier or password'}), 401


# ------------------ Admin Approval Routes (Token-Based) ------------------ #
@auth_bp.route('/api/admin/approve-with-token/<string:token>', methods=['GET'])
def approve_admin_with_token(token):
    # This route is unprotected and intended for use with the email link
    admin_to_approve = Admin.query.filter_by(approval_token=token).first()

    if not admin_to_approve:
        return jsonify({'success': False, 'message': 'Invalid or expired token.'}), 400

    if admin_to_approve.status == 'approved':
        return jsonify({'success': False, 'message': 'Admin is already approved.'}), 400

    try:
        # Update the status and invalidate the tokens
        admin_to_approve.status = 'approved'
        admin_to_approve.approval_token = None
        admin_to_approve.rejection_token = None
        db.session.commit()
        
        # Send confirmation email
        msg = Message(
            subject="Your ArogyaLink Account Has Been Approved",
            sender=current_app.config['MAIL_USERNAME'],
            recipients=[admin_to_approve.email]
        )
        msg.html = f"""
            <p>Dear Admin,</p>
            <p>Your registration request for {admin_to_approve.hospital_name} has been approved. You can now log in to your ArogyaLink account.</p>
            <p>Thank you!</p>
        """
        mail.send(msg)
        
        # Return a simple success page or JSON response
        return jsonify({'success': True, 'message': 'Admin approved and confirmation email sent'}), 200
    except Exception as e:
        db.session.rollback()
        logging.error(f"Error approving admin: {e}", exc_info=True)
        return jsonify({'success': False, 'message': 'An error occurred during approval'}), 500

@auth_bp.route('/api/admin/reject-with-token/<string:token>', methods=['GET'])
def reject_admin_with_token(token):
    # This route is unprotected and intended for use with the email link
    admin_to_reject = Admin.query.filter_by(rejection_token=token).first()

    if not admin_to_reject:
        return jsonify({'success': False, 'message': 'Invalid or expired token.'}), 400

    if admin_to_reject.status == 'rejected':
        return jsonify({'success': False, 'message': 'Admin is already rejected.'}), 400

    try:
        # Update the status and invalidate the tokens
        admin_to_reject.status = 'rejected'
        admin_to_reject.approval_token = None
        admin_to_reject.rejection_token = None
        db.session.commit()
        
        # Send rejection email
        msg = Message(
            subject="Your ArogyaLink Registration Request",
            sender=current_app.config['MAIL_USERNAME'],
            recipients=[admin_to_reject.email]
        )
        msg.html = f"""
            <p>Dear Admin,</p>
            <p>We regret to inform you that your registration request for {admin_to_reject.hospital_name} has been rejected.</p>
            <p>If you believe this is an error, please contact support.</p>
        """
        mail.send(msg)
        
        # Return a simple success page or JSON response
        return jsonify({'success': True, 'message': 'Admin rejected and notification email sent'}), 200
    except Exception as e:
        db.session.rollback()
        logging.error(f"Error rejecting admin: {e}", exc_info=True)
        return jsonify({'success': False, 'message': 'An error occurred during rejection'}), 500


# ------------------ JWT Protected Route ------------------ #
@auth_bp.route('/api/protected', methods=['GET'])
@jwt_required()
def protected():
    current_user_identity = get_jwt_identity()
    return jsonify(logged_in_as=current_user_identity), 200

@auth_bp.route('/api/forgot-password', methods=['POST'])
def forgot_password():
    data = request.get_json()
    email = data.get('email')

    user = Patient.query.filter_by(email=email).first() or Admin.query.filter_by(email=email).first()
    if not user:
        return jsonify({'success': False, 'message': 'Email not registered'}), 400

    otp = str(random.randint(100000, 999999))
    expiry = datetime.utcnow() + timedelta(minutes=5)
    otp_storage[email] = {"otp": otp, "expiry": expiry}

    msg = Message('Password Reset OTP',
                  sender=current_app.config['MAIL_USERNAME'],
                  recipients=[email])
    msg.body = f"Your OTP is {otp}. It will expire in 5 minutes."
    mail.send(msg)

    return jsonify({'success': True, 'message': 'OTP sent to your email'}), 200

@auth_bp.route('/api/verify-otp', methods=['POST'])
def verify_otp():
    data = request.get_json()
    email = data.get('email')
    otp = data.get('otp')

    record = otp_storage.get(email)
    if not record:
        return jsonify({'success': False, 'message': 'No OTP found'}), 400

    if record['otp'] == otp and datetime.utcnow() < record['expiry']:
        return jsonify({'success': True, 'message': 'OTP verified'}), 200
    else:
        return jsonify({'success': False, 'message': 'Invalid or expired OTP'}), 400

@auth_bp.route('/api/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json()
    email = data.get('email')
    new_password = data.get('new_password')

    record = otp_storage.get(email)
    if not record:
        return jsonify({'success': False, 'message': 'OTP verification required'}), 400

    user = Patient.query.filter_by(email=email).first() or Admin.query.filter_by(email=email).first()
    if not user:
        return jsonify({'success': False, 'message': 'User not found'}), 400

    user.set_password(new_password)
    db.session.commit()

    otp_storage.pop(email, None)

    return jsonify({'success': True, 'message': 'Password reset successful'}), 200

@auth_bp.route('/api/doctor/login', methods=['POST'])
def doctor_login():
    data = request.get_json()
    print("RAW DATA RECEIVED:", data)   # 👈 Debug
    print("HEADERS:", request.headers) 

    if not data:
        return jsonify({'success': False, 'message': 'No data provided'}), 400

    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'success': False, 'message': 'Email and password are required'}), 400

    doctor = Doctor.query.filter_by(email=email).first()

    if not doctor:
        return jsonify({'success': False, 'message': 'Doctor not found'}), 404

    # Password check
    if not check_password_hash(doctor.password_hash, password):
        return jsonify({'success': False, 'message': 'Invalid password'}), 401

    # First login → status pending → active
    if doctor.status == "pending":
        doctor.status = "active"
        db.session.commit()

    # --- Slot generation if doctor is active ---
    if doctor.status == "active":
        existing_slots = OPDSlot.query.filter(
            OPDSlot.doctor_id == doctor.id,
            OPDSlot.appointment_date >= date.today()
        ).all()

        if not existing_slots:
            hospital = Admin.query.get(doctor.hospital_id)
            generate_slots(
                doctor_id=doctor.id,
                hospital_id=doctor.hospital_id,
                start_time_str=hospital.opd_start_time,
                end_time_str=hospital.opd_end_time
            )

    # Generate JWT token (valid for 1 day)
    access_token = create_access_token(
    identity=str(doctor.id),  # 👈 force string
    expires_delta=timedelta(days=1)
)


    return jsonify({
        'success': True,
        'message': 'Login successful',
        'access_token': access_token,
        'doctor': {
            'id': doctor.id,
            'name': doctor.name,
            'email': doctor.email,
            'specialization': doctor.specialization,
            'status': doctor.status
        }
    }), 200