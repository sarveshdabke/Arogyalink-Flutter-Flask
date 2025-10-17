# A simple, self-contained example of a Flask endpoint.
# This code assumes you have a running Flask app with JWT authentication.
import base64
from datetime import datetime
from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from flask_cors import CORS
# Assuming you have a database model for both Patient and Admin
# NOTE: The EditedProfile model has been removed, as we will now use
# the Patient model for all profile data.
from models import HospitalizationAdmission, HospitalizationBill, OPDAppointment, OPDSlot, Patient, Admin, Appointment, BedPartition, Doctor
from models import db
from flask_mail import Mail, Message
from flask import current_app

mail = Mail()
# Corrected Blueprint registration
patient_bp = Blueprint('patient', __name__)
CORS(patient_bp)

@patient_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_patient_profile():
    identity = get_jwt_identity()
    patient = Patient.query.get(int(identity))

    if not patient:
        return jsonify({'message': 'Patient not found'}), 404

    return jsonify(patient.to_dict()), 200

@patient_bp.route('/update_profile_with_image', methods=['POST'])
@jwt_required()
def update_profile_with_image():
    """
    Updates the patient profile, including a profile image.
    This now updates the Patient table directly, removing the need for EditedProfile.
    """
    try:
        user_id = int(get_jwt_identity())
        
        # Find the patient in the Patient table
        patient = Patient.query.get(user_id)
        if not patient:
            return jsonify({"success": False, "message": "Patient not found"}), 404

        # Read the new profile image if provided
        image_file = request.files.get('profile_image')
        if image_file:
            image_blob = image_file.read()
            # Update the patient's profile_image field
            patient.profile_image = image_blob

        # Create a dictionary of the form data to update the patient object
        profile_data = {
            'username': request.form.get('username'),
            'email': request.form.get('email'),
            'date_of_birth': request.form.get('date_of_birth'),
            'gender': request.form.get('gender'),
            'mobile_number': request.form.get('mobile_number'),
            'residential_address': request.form.get('residential_address'),
            'emergency_contact_name': request.form.get('emergency_contact_name'),
            'emergency_contact_number': request.form.get('emergency_contact_number'),
            'blood_group': request.form.get('blood_group'),
            'known_allergies': request.form.get('known_allergies'),
            'chronic_illnesses': request.form.get('chronic_illnesses'),
            'current_medications': request.form.get('current_medications'),
            'past_surgeries': request.form.get('past_surgeries'),
            'vaccination_details': request.form.get('vaccination_details'),
            'country': request.form.get('country'),
            'state': request.form.get('state')
        }

        # Update the patient object with the new data
        for key, value in profile_data.items():
            if value is not None:
                setattr(patient, key, value)

        db.session.commit()
        return jsonify({"success": True, "message": "Profile updated successfully"})

    except Exception as e:
        # Rollback the session in case of an error
        db.session.rollback()
        return jsonify({"success": False, "message": str(e)}), 500

@patient_bp.route('/get_profile_with_image', methods=['GET'])
@jwt_required()
def get_profile_with_image():
    """
    Retrieves the patient's profile, including the profile image.
    This now only queries the Patient table, as EditedProfile is no longer used.
    """
    try:
        # Get user ID from JWT token
        user_id = int(get_jwt_identity())

        # Find the patient in the Patient table
        patient = Patient.query.get(user_id)

        if patient:
            profile_dict = patient.to_dict()

            # Convert profile image to Base64 if it exists
            if profile_dict.get('profile_image'):
                profile_dict['profile_image'] = base64.b64encode(profile_dict['profile_image']).decode('utf-8')

            return jsonify({"success": True, "data": profile_dict}), 200

        # If user not found
        return jsonify({"success": False, "message": "User not found"}), 404

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


@patient_bp.route('/search_hospital', methods=['GET'])
@jwt_required()
def search_hospital():
    try:
        name = request.args.get('name', '')
        if not name:
            return jsonify({"success": False, "message": "Name query is required"}), 400

        # Hospital -> Admin
        hospitals = Admin.query.filter(Admin.hospital_name.ilike(f"%{name}%")).all()

        return jsonify({
            "success": True,
            "hospitals": [hospital.to_dict() for hospital in hospitals]
        }), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


@patient_bp.route('/hospital/<int:hospital_id>', methods=['GET'])
@jwt_required()
def get_hospital_profile(hospital_id):
    try:
        # Hospital -> Admin
        hospital = Admin.query.get(hospital_id)
        if not hospital:
            return jsonify({"success": False, "message": "Hospital not found"}), 404

        return jsonify({"success": True, "data": hospital.to_dict()}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


# ✅ Get ALL hospitals
@patient_bp.route('/hospital', methods=['GET'])
@jwt_required()
def get_all_hospitals():
    try:
        hospitals = Admin.query.all()
        hospital_list = []

        for hospital in hospitals:
            # ✅ Check if hospital has at least one doctor
            has_doctors = Doctor.query.filter_by(hospital_id=hospital.id).count() > 0

            # ✅ Check if hospital has at least one bed partition
            has_partitions = BedPartition.query.filter_by(hospital_id=hospital.id).count() > 0

            # ✅ Skip hospitals that don't meet both conditions
            if not (has_doctors and has_partitions):
                continue

            # ✅ Calculate available beds for valid hospitals
            partitions = BedPartition.query.filter_by(hospital_id=hospital.id).all()
            available_beds = sum(p.available_beds for p in partitions)

            hospital_dict = hospital.to_dict()
            hospital_dict['available_beds'] = available_beds

            hospital_list.append(hospital_dict)

        return jsonify({
            "success": True,
            "hospitals": hospital_list
        }), 200

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

# New endpoint to fetch all appointments for the patient
@patient_bp.route('/appointments', methods=['GET'])
@jwt_required()
def get_patient_appointments():
    """
    Fetches all appointments for the authenticated patient.
    """
    try:
        user_id = int(get_jwt_identity())
        
        # Query the database for all appointments associated with this patient
        appointments = Appointment.query.filter_by(patient_id=user_id).all()
        
        # Convert the list of Appointment objects to a list of dictionaries
        # Each dictionary should also include the related hospital and doctor data
        appointment_list = []
        for appointment in appointments:
            appointment_data = appointment.to_dict()
            
            # Fetch and add the doctor's name (or other info)
            # You might need to adjust this depending on your database schema
            # For this example, we'll assume the doctor is linked to the hospital's admin
            doctor = Admin.query.get(appointment.hospital_id)
            if doctor:
                appointment_data['doctor'] = {
                    'username': doctor.owner_name  # Or the field for the doctor's name
                }
            
            appointment_list.append(appointment_data)
        
        return jsonify({
            'success': True,
            'appointments': appointment_list
        }), 200

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500
    
    # A new route in patient.py to get doctors by admin ID and specialization
# In your patient.py file, replace the existing get_doctors_by_admin function with this:

@patient_bp.route('/hospital/<int:hospital_id>/doctors', methods=['GET'])
def get_doctors_by_hospital(hospital_id):
    """
    Fetches all doctors associated with a specific hospital.
    """
    # We are using hospital_id directly from the URL path
    # The 'admin_id' query parameter is no longer needed for this specific route.
    
    doctors = Doctor.query.filter_by(hospital_id=hospital_id).all()
    
    if not doctors:
        # It's good practice to return a specific message if no doctors are found for a valid hospital ID.
        # This is different from a 404, which means the endpoint itself wasn't found.
        return jsonify({
            'success': True, 
            'message': 'No doctors found for this hospital.',
            'data': []
        }), 200

    return jsonify({
        'success': True,
        'data': [doctor.to_dict() for doctor in doctors]
    }), 200

@patient_bp.route('/hospital/<int:hospital_id>/departments', methods=['GET'])
@jwt_required()
def get_hospital_departments(hospital_id):
    """
    Fetches the list of departments for a specific hospital.
    Returns a JSON list of department names.
    """
    try:
        hospital = Admin.query.get(hospital_id)
        if not hospital:
            return jsonify({"success": False, "message": "Hospital not found"}), 404

        # Assuming `departments` is stored as a string "OPD,ICU,Heart"
        departments_str = hospital.departments or ""
        departments_list = [d.strip() for d in departments_str.split(",") if d.strip()]

        return jsonify({"success": True, "data": departments_list}), 200

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500
    
@patient_bp.route('/get_opd_slots', methods=['GET'])
@jwt_required()
def get_opd_slots():
    try:
        doctor_id = request.args.get('doctor_id')
        appointment_date = request.args.get('date')

        if not doctor_id or not appointment_date:
            return jsonify({"success": False, "message": "doctor_id and date are required"}), 400

        # Fetch only free slots for that doctor & date
        slots = OPDSlot.query.filter_by(
            doctor_id=doctor_id,
            appointment_date=appointment_date,
            is_booked=False
        ).all()

        return jsonify({
            "success": True,
            "data": [slot.to_dict() for slot in slots]
        }), 200

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

@patient_bp.route('/book_opd_appointment', methods=['POST'])
@jwt_required()
def book_opd_appointment():
    try:
        user_id = int(get_jwt_identity())  # Logged-in patient ID
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'message': 'No data provided'}), 400
        
        hospital_id = int(data.get('hospitalId') or data.get('hospital_id'))
        doctor_id   = int(data.get('doctorId') or data.get('doctor_id'))
        appointment_date = (data.get('appointmentDate') or "").strip()
        start_time = (data.get('startTime') or "").strip()
        end_time = (data.get('endTime') or "").strip()
        is_emergency = data.get('isEmergency', False)

        if not all([hospital_id, doctor_id, appointment_date, start_time, end_time]):
            return jsonify({'success': False, 'message': 'Missing required fields'}), 400

        # Check if OPD slot exists
        opd_slot = OPDSlot.query.filter_by(
            hospital_id=hospital_id,
            doctor_id=doctor_id,
            appointment_date=appointment_date,
            start_time=start_time,
            end_time=end_time
        ).first()

        # If emergency and slot doesn't exist, create it
        if not opd_slot and is_emergency:
            opd_slot = OPDSlot(
                hospital_id=hospital_id,
                doctor_id=doctor_id,
                appointment_date=appointment_date,
                start_time=start_time,
                end_time=end_time,
                is_booked=False
            )
            db.session.add(opd_slot)
            db.session.commit()

        if not opd_slot:
            return jsonify({'success': False, 'message': 'Selected slot not found'}), 404

        if opd_slot.is_booked:
            return jsonify({'success': False, 'message': 'This slot is already booked'}), 409

        opd_slot.is_booked = True

        # --- FIXED: Token number based on slot order ---
        slots = OPDSlot.query.filter_by(
            doctor_id=doctor_id,
            appointment_date=appointment_date
        ).order_by(OPDSlot.start_time).all()

        slot_list = [s.start_time for s in slots]
        try:
            token_number = slot_list.index(start_time) + 1
        except ValueError:
            return jsonify({'success': False, 'message': 'Invalid slot time'}), 400
        # ------------------------------------------------

        new_appointment = OPDAppointment(
            hospital_id=hospital_id,
            doctor_id=doctor_id,
            patient_id=user_id,
            patient_name=data.get('patientName'),
            patient_age=data.get('patientAge'),
            patient_contact=data.get('patientContact'),
            patient_email=data.get('patientEmail'),
            gender=data.get('patientGender'),
            appointment_date=appointment_date,
            start_time=start_time,
            end_time=end_time,
            symptoms=data.get('symptoms'),
            is_emergency=is_emergency,
            token_number=token_number
        )

        db.session.add(new_appointment)
        db.session.commit()

        return jsonify({
            'success': True,
            'message': 'Appointment booked successfully!',
            'token_number': token_number
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500

@patient_bp.route('/opd_appointments', methods=['GET'])
@jwt_required()
def get_patient_opd_appointments():
    try:
        user_id = int(get_jwt_identity())

        # Get today's date
        today = datetime.now().date()

        # Fetch all appointments of the patient from today onwards
        appointments = OPDAppointment.query.filter(
            OPDAppointment.patient_id == user_id,
            OPDAppointment.appointment_date >= today
        ).order_by(OPDAppointment.token_number.asc()).all()

        appointment_list = []
        for appt in appointments:
            # ---- (1) Find current token for this doctor + date ----
            doctor_appts = OPDAppointment.query.filter_by(
                doctor_id=appt.doctor_id,
                appointment_date=appt.appointment_date,
                is_booked=True
            ).order_by(OPDAppointment.token_number.asc()).all()

            current_appt = next((a for a in doctor_appts if a.status.lower() == "pending"), None)
            current_token = current_appt.token_number if current_appt else None

            # ---- (2) Calculate position in queue ----
            position_in_queue = (appt.token_number - current_token) if current_token else appt.token_number


            # ---- (3) Keep your existing status mapping ----
            if appt.status.lower() == 'completed':
                status = 'completed'
            elif appt.status.lower() == 'current':
                status = 'current'
            else:
                status = 'upcoming'

            # ---- (4) Total tokens for this doctor on the same date ----
            total_tokens = len(doctor_appts)
            hospital = Admin.query.get(appt.hospital_id)
            doctor = Doctor.query.get(appt.doctor_id)
            appointment_list.append({
                'id': appt.id,
                'hospital_id': appt.hospital_id,
                'hospital_name': hospital.hospital_name if hospital else "Unknown",
                'doctor_id': appt.doctor_id,
                'doctor_name': doctor.name if doctor else "Unknown",
                'appointment_date': appt.appointment_date,
                'start_time': appt.start_time,
                'end_time': appt.end_time,
                'token_number': appt.token_number,
                'current_token': current_token,        # 👈 added
                'position_in_queue': position_in_queue, # 👈 added
                'total_tokens': total_tokens,
                'status': status,
                'symptoms': appt.symptoms,
                'is_emergency': appt.is_emergency
            })

        return jsonify({
            'success': True,
            'data': appointment_list
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500

@patient_bp.route('/patients/opd_report', methods=['GET'])
@jwt_required()
def get_opd_report():
    try:
        # JWT se current patient id lena
        patient_id = int(get_jwt_identity())

        # Patient ke sare appointments lana
        appointments = OPDAppointment.query.filter_by(patient_id=patient_id).all()

        if not appointments:
            return jsonify({"message": "No appointments found"}), 404

        result = []
        for appt in appointments:
            if appt.prescription_created_by:  # prescription generate ho chuka hai
                result.append(appt.to_dict())

        if not result:
            return jsonify({"message": "Prescription not generated yet"}), 200

        return jsonify(result), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@patient_bp.route('/patients/bill_report', methods=['GET'])
@jwt_required()
def get_bill_report():
    try:
        patient_id = int(get_jwt_identity())

        # Fetch all appointments of this patient
        appointments = OPDAppointment.query.filter_by(patient_id=patient_id).all()

        if not appointments:
            return jsonify({"message": "No appointments found"}), 404

        result = []
        for appt in appointments:
            if appt.bill_generated:  # only include if bill is generated
                hospital = Admin.query.get(appt.hospital_id)
                doctor = Doctor.query.get(appt.doctor_id)
                
                result.append({
    'id': appt.id,
    'hospital_id': appt.hospital_id,
    'hospital_name': hospital.hospital_name if hospital else "Unknown",
    'doctor_id': appt.doctor_id,
    'doctor_name': doctor.name if doctor else "Unknown",
    'appointment_date': appt.appointment_date,
    'visiting_fee': appt.visiting_fee,
    'checkup_fee': appt.checkup_fee,
    'tax_percent': appt.tax_percent,
    'total_amount': appt.total_amount,
    'bill_generated_at': appt.bill_generated_at.strftime("%Y-%m-%d %H:%M:%S") if appt.bill_generated_at else None,
    'bill_pdf_path': appt.bill_pdf_path,

    # New fields
    'status': appt.status if appt.status else "Pending",
    'referral_reason': appt.referral_reason if appt.referral_reason else None,
    'bill_paid': appt.bill_paid  # <-- Add this
})

        if not result:
            return jsonify({"message": "Bill not generated yet"}), 200

        return jsonify(result), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@patient_bp.route('/pay_bill/<int:bill_id>', methods=['POST'])
@jwt_required()
def pay_bill(bill_id):
    try:
        patient_id = int(get_jwt_identity())
        bill = OPDAppointment.query.filter_by(id=bill_id, patient_id=patient_id).first()

        if not bill:
            return jsonify({"success": False, "message": "Bill not found"}), 404

        if not bill.bill_generated:
            return jsonify({"success": False, "message": "Bill not generated yet"}), 400

        # Get payment mode from request
        data = request.get_json()
        payment_mode = data.get('payment_mode')  # expected: "cash" or "upi"

        if payment_mode not in ['cash', 'upi']:
            return jsonify({"success": False, "message": "Invalid payment mode"}), 400

        # Update bill as paid and store mode
        bill.bill_paid = True
        bill.payment_mode = payment_mode
        db.session.commit()

        # If UPI, return UPI info for redirect
        upi_info = None
        if payment_mode == "upi":
            hospital = bill.hospital
            if hospital.upi_id:
                upi_info = {
                    "upi_id": hospital.upi_id,
                    "amount": bill.total_amount,
                    "note": f"Payment for {hospital.hospital_name}"
                }

        return jsonify({
            "success": True,
            "message": "Bill paid successfully",
            "upi_info": upi_info
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"success": False, "message": str(e)}), 500

# ----------------- Hospitalization Create Endpoint ----------------- #
@patient_bp.route('/patients/<int:patient_id>/hospitalization', methods=['POST'])
def create_hospitalization(patient_id):
    try:
        data = request.get_json()

        # --- IMPORTANT: Logging for debugging (Keep this until everything works) ---
        print(f"Received Hospitalization Data: {data}")
        # -------------------------------------------------------------------------

        new_admission = HospitalizationAdmission(
            patient_id = patient_id,
            hospital_id = data.get("hospital_id"),
            opd_appointment_id = data.get("opd_appointment_id"),
            
            # Referring Doctor ID
            referring_doctor_id = data.get("referring_doctor_id"),
            
            # Patient Details
            patient_name = data.get("patient_name"),
            patient_age = data.get("age"), # Flutter sends 'age'
            gender = data.get("gender"),
            contact_number = data.get("contact"), # Flutter sends 'contact'
            email = data.get("email"),
            
            # Admission Details
            admission_date = data.get("admission_date"),
            reason_symptoms = data.get("reason"),
            
            # --- ✅ FIX 1: Insurance/Payment Mapping ---
            insurance_provider = data.get("insurance_provider"),
            insurance_policy_number = data.get("policy_number"), # MODEL expects 'insurance_policy_number', input key is 'policy_number'
            payment_mode = data.get("payment_mode"),
            
            # --- ✅ FIX 2: Emergency Contact Mapping ---
            guardian_name = data.get("emergency_name"),           # MODEL expects 'guardian_name', input key is 'emergency_name'
            guardian_relationship = data.get("emergency_relation"), # MODEL expects 'guardian_relationship', input key is 'emergency_relation'
            guardian_contact_number = data.get("emergency_contact"), # MODEL expects 'guardian_contact_number', input key is 'emergency_contact'
            
            # --- ✅ FIX 3: Medical Notes/History Mapping ---
            special_instructions = data.get("special_instructions"),
            allergies = data.get("allergies"),                           # Input key 'allergies' maps to model column 'allergies'
            past_surgeries = data.get("past_surgeries"),
            current_medications = data.get("medications"),               # Input key 'medications' maps to model column 'current_medications'
            # ----------------------------------------
            
            status = "Pending"
        )

        db.session.add(new_admission)
        db.session.commit()

        return jsonify({
            "success": True,
            "message": "Hospitalization admission created successfully",
            "hospitalization_id": new_admission.id
        }), 201

    except Exception as e:
        db.session.rollback()
        # Log the error for server-side debugging
        print(f"An error occurred during hospitalization creation: {e}") 
        return jsonify({"success": False, "message": f"Error: {str(e)}"}), 500

@patient_bp.route('/my_hospitalizations', methods=['GET'])
@jwt_required()
def get_my_hospitalizations():
    patient_id = get_jwt_identity()  # Logged-in patient ID

    # Query all hospitalizations for this patient
    admissions = HospitalizationAdmission.query.filter_by(patient_id=patient_id).all()

    if not admissions:
        return jsonify({"success": False, "message": "No hospitalization records found"}), 404

    # Convert all admissions to dictionary
    admissions_list = [admission.to_dict() for admission in admissions]

    return jsonify({"success": True, "data": admissions_list}), 200

@patient_bp.route('/hospitalization_bills', methods=['GET'])
@jwt_required()
def get_patient_hospitalization_bills():
    """
    Fetch all hospitalization bills for the logged-in patient.
    """
    patient_id = get_jwt_identity()

    # ✅ Verify that the logged-in user exists as a Patient
    patient = Patient.query.filter_by(id=patient_id).first()
    if not patient:
        return jsonify({'success': False, 'message': 'Patient not found'}), 404

    # ✅ Fetch all bills belonging to this patient
    bills = HospitalizationBill.query.filter_by(patient_id=patient_id).order_by(HospitalizationBill.created_at.desc()).all()

    if not bills:
        return jsonify({'success': True, 'message': 'No hospitalization bills found', 'data': []}), 200

    return jsonify({
        'success': True,
        'message': 'Hospitalization bills fetched successfully',
        'data': [bill.to_dict() for bill in bills]
    }), 200

@patient_bp.route('/pay_hospitalization_bill/<int:bill_id>', methods=['POST'])
@jwt_required()
def pay_hospitalization_bill(bill_id):
    try:
        patient_id = int(get_jwt_identity())
        bill = HospitalizationBill.query.filter_by(id=bill_id, patient_id=patient_id).first()

        if not bill:
            return jsonify({"success": False, "message": "Bill not found"}), 404

        if bill.status.lower() == "paid":
            return jsonify({"success": False, "message": "Bill is already paid"}), 400

        # ✅ Safely get JSON data
        data = request.get_json(silent=True) or {}
        payment_mode = data.get('payment_mode', '').lower().strip()

        if payment_mode not in ['cash', 'upi']:
            return jsonify({"success": False, "message": "Invalid payment mode"}), 400

        # ✅ Store selected payment mode
        bill.payment_mode = payment_mode.capitalize()

        # 💰 Cash Payment Logic
        if payment_mode == "cash":
            bill.status = "Pending"
            db.session.commit()

            return jsonify({
                "success": True,
                "message": "Please visit the hospital to pay your bill in cash."
            }), 200

        # 💳 UPI Payment Logic
        elif payment_mode == "upi":
            hospital = bill.hospital  # from relationship in model

            # ✅ Ensure hospital and UPI ID exist
            if not hospital or not hospital.upi_id:
                return jsonify({
                    "success": False,
                    "message": "Hospital UPI ID not found. Please contact the hospital."
                }), 400

            # ✅ Prepare UPI payment info
            upi_info = {
                "upi_id": hospital.upi_id,
                "amount": bill.net_payable,
                "note": f"Payment for {hospital.hospital_name or 'Hospital'}"
            }

            # Mark bill as paid
            bill.status = "Paid"
            db.session.commit()

            return jsonify({
                "success": True,
                "message": "UPI payment initialized successfully.",
                "upi_info": upi_info
            }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({
            "success": False,
            "message": f"An error occurred: {str(e)}"
        }), 500

@patient_bp.route('/hospitalization_bills/<int:patient_id>', methods=['GET'])
@jwt_required()
def get_patient_bills(patient_id):
    patient_identity = get_jwt_identity()

    if patient_identity != patient_id:
        return jsonify({'success': False, 'message': 'Unauthorized access'}), 403

    bills = HospitalizationBill.query.filter_by(patient_id=patient_id).all()

    if not bills:
        return jsonify({'success': False, 'message': 'No bills found'}), 404

    # Mark bills as seen
    for bill in bills:
        bill.is_seen_by_patient = True
    db.session.commit()

    return jsonify({
        'success': True,
        'data': [bill.to_dict() for bill in bills]
    }), 200
@patient_bp.route('/hospitalization_bills/mark_seen/<int:bill_id>', methods=['PATCH'])
@jwt_required()
def mark_bill_as_seen(bill_id):
    patient_id = get_jwt_identity()

    bill = HospitalizationBill.query.filter_by(id=bill_id, patient_id=patient_id).first()
    if not bill:
        return jsonify({'success': False, 'message': 'Bill not found'}), 404

    bill.is_seen_by_patient = True
    db.session.commit()

    return jsonify({'success': True, 'message': 'Bill marked as seen'}), 200
