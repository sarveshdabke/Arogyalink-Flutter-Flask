import secrets
from flask import Blueprint, request, jsonify
from flask_cors import CORS
from flask_jwt_extended import jwt_required, get_jwt_identity
from flask_mail import Message
from sqlalchemy import func
from werkzeug.security import generate_password_hash
import base64
from flask import current_app
from utils.credentials_pdf import create_credentials_pdf
from datetime import datetime, timedelta
from models import DoctorTreatmentHistory, HospitalizationBill, OPDAppointment, OPDSlot, db, Admin, BedPartition, Appointment, Doctor, HospitalizationAdmission


admin_routes = Blueprint('admin_routes', __name__)
CORS(admin_routes)

# --- Admin Profile GET Route ---
@admin_routes.route('/profile', methods=['GET'])
@jwt_required()
def admin_profile():
    admin_id = get_jwt_identity()
    admin = Admin.query.get(admin_id)

    if admin:
        admin_dict = {
            'id': admin.id,
            'hospital_name': admin.hospital_name,
            'email': admin.email,
            'owner_name': admin.owner_name,
            'contact': admin.contact,
            'alt_contact': admin.alt_contact,
            'address': admin.address,
            'landmark': admin.landmark,
            'hospital_type': admin.hospital_type,
            'emergency': admin.emergency,
            'opd_available': admin.opd_available,
            'opd_start_time': admin.opd_start_time,
            'opd_end_time': admin.opd_end_time,
            'license_number': admin.license_number,
            'latitude': admin.latitude,
            'longitude': admin.longitude,
            'state': admin.state,
            'country': admin.country,
        }

        if admin.hospital_logo:
            admin_dict['hospital_logo'] = base64.b64encode(admin.hospital_logo).decode('utf-8')
        else:
            admin_dict['hospital_logo'] = None
            
        partitions = BedPartition.query.filter_by(hospital_id=admin.id).all()
        admin_dict['bed_partitions'] = [partition.to_dict() for partition in partitions]

        return jsonify({'success': True, 'data': admin_dict}), 200

    return jsonify({'success': False, 'message': 'Admin not found'}), 404 

# --- Admin Profile UPDATE Route ---
@admin_routes.route('/profile/update', methods=['PUT'])
@jwt_required()
def update_admin_profile():
    admin_id = get_jwt_identity()
    admin = Admin.query.get(admin_id)

    if not admin:
        return jsonify({'success': False, 'message': 'Admin not found'}), 404

    data = request.form
    files = request.files

    admin.hospital_name = data.get('hospital_name', admin.hospital_name)
    admin.owner_name = data.get('owner_name', admin.owner_name)
    admin.contact = data.get('contact', admin.contact)
    admin.alt_contact = data.get('alt_contact', admin.alt_contact)
    admin.address = data.get('address', admin.address)
    admin.landmark = data.get('landmark', admin.landmark)
    admin.hospital_type = data.get('hospital_type', admin.hospital_type)
    admin.departments = data.get('departments', admin.departments)
    admin.emergency = data.get('emergency', admin.emergency)
    admin.opd_available = data.get('opd_available', admin.opd_available)
    admin.opd_start_time = data.get('opd_start_time', admin.opd_start_time)
    admin.opd_end_time = data.get('opd_end_time', admin.opd_end_time)
    admin.license_number = data.get('license_number', admin.license_number)
    admin.state = data.get('state', admin.state)
    admin.country = data.get('country', admin.country)
    
    if 'latitude' in data:
        admin.latitude = float(data.get('latitude', admin.latitude))
    if 'longitude' in data:
        admin.longitude = float(data.get('longitude', admin.longitude))

    if 'password' in data and data['password']:
        admin.password = generate_password_hash(data['password'])

    if 'hospital_logo' in files:
        logo_file = files['hospital_logo']
        try:
            file_data = logo_file.read()
            admin.hospital_logo = file_data
        except Exception as e:
            return jsonify({'success': False, 'message': f'Error processing image: {e}'}), 500

    try:
        db.session.commit()
        return jsonify({'success': True, 'message': 'Profile updated successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Error updating profile: {e}'}), 500

# --- Add a new bed partition ---
@admin_routes.route('/bed_partitions', methods=['POST'])
@jwt_required()
def add_bed_partition():
    admin_id = get_jwt_identity()
    data = request.get_json()

    if not data:
        return jsonify({'success': False, 'message': 'No data provided'}), 400

    partition_name = data.get('partition_name')
    total_beds = data.get('total_beds')
    
    # New logic: When a partition is created, available_beds defaults to total_beds, occupied_beds to 0
    # NOTE: available_beds is not taken directly from user input anymore.
    if total_beds is None:
        return jsonify({'success': False, 'message': 'Missing required field: total_beds'}), 400

    try:
        total_beds = int(total_beds)
        if total_beds < 0:
             return jsonify({'success': False, 'message': 'Invalid total bed count'}), 400
    except ValueError:
        return jsonify({'success': False, 'message': 'Invalid total bed count format'}), 400


    try:
        new_partition = BedPartition(
            partition_name=partition_name,
            total_beds=total_beds,
            available_beds=total_beds, # Initialize available_beds to total_beds
            occupied_beds=0,           # Initialize occupied_beds to 0
            hospital_id=admin_id
        )
        db.session.add(new_partition)
        db.session.commit()
        return jsonify({'success': True, 'message': 'Bed partition added successfully'}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Error adding partition: {e}'}), 500

# --- Update an existing bed partition ---
@admin_routes.route('/bed_partitions/<int:partition_id>', methods=['PUT'])
@jwt_required()
def update_bed_partition(partition_id):
    admin_id = get_jwt_identity()
    partition = BedPartition.query.filter_by(id=partition_id, hospital_id=admin_id).first()

    if not partition:
        return jsonify({'success': False, 'message': 'Partition not found or unauthorized'}), 404
    
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'message': 'No data provided'}), 400
    
    # Only allow updating name and total_beds. available/occupied beds are managed by logic.
    new_total_beds = data.get('total_beds')
    if new_total_beds is not None:
        try:
            new_total_beds = int(new_total_beds)
        except ValueError:
            return jsonify({'success': False, 'message': 'Invalid total bed count format'}), 400

        if new_total_beds < partition.occupied_beds:
            return jsonify({'success': False, 'message': f"Total beds cannot be less than occupied beds ({partition.occupied_beds})!"}), 400

        # Logic to update available_beds based on new total_beds
        partition.total_beds = new_total_beds
        partition.available_beds = new_total_beds - partition.occupied_beds

    partition.partition_name = data.get('partition_name', partition.partition_name)


    try:
        db.session.commit()
        return jsonify({'success': True, 'message': 'Bed partition updated successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Error updating partition: {e}'}), 500


# --- Delete a bed partition ---
@admin_routes.route('/bed_partitions/<int:partition_id>', methods=['DELETE'])
@jwt_required()
def delete_bed_partition(partition_id):
    admin_id = get_jwt_identity()
    partition = BedPartition.query.filter_by(id=partition_id, hospital_id=admin_id).first()

    if not partition:
        return jsonify({'success': False, 'message': 'Partition not found or unauthorized'}), 404
    
    # Check if any patients are currently assigned to this partition
    if partition.occupied_beds > 0:
         return jsonify({'success': False, 'message': 'Cannot delete partition: It currently has occupied beds.'}), 400

    try:
        db.session.delete(partition)
        db.session.commit()
        return jsonify({'success': True, 'message': 'Bed partition deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Error deleting partition: {e}'}), 500

# --- Get all bed partitions ---
@admin_routes.route('/bed_partitions', methods=['GET'])
@jwt_required()
def get_bed_partitions():
    admin_id = get_jwt_identity()

    partitions = BedPartition.query.filter_by(hospital_id=admin_id).all()

    return jsonify({
        'success': True,
        'data': [partition.to_dict() for partition in partitions]
    }), 200

    

        
# --- Endpoint to update an appointment's status (Accept/Reject) ---
@admin_routes.route('/appointments/<int:appointment_id>/status', methods=['POST'])
@jwt_required()
def update_appointment_status(appointment_id):
    try:
        admin_id = int(get_jwt_identity())
        data = request.get_json()
        new_status = data.get('status')
        rejection_reason = data.get('rejection_reason')

        # Validate the new status
        if new_status not in ['Approved', 'Rejected']:
            return jsonify({'success': False, 'message': 'Invalid status provided.'}), 400

        appointment = Appointment.query.filter_by(id=appointment_id, hospital_id=admin_id).first()
        
        if not appointment:
            return jsonify({'success': False, 'message': 'Appointment not found or you do not have permission to modify it.'}), 404
        
        # Check if the appointment is in a pending state before updating
        if appointment.status != 'Pending':
            return jsonify({'success': False, 'message': 'Cannot modify a non-pending appointment.'}), 409

        # Update the appointment status
        appointment.status = new_status
        if new_status == 'Rejected':
            appointment.rejection_reason = rejection_reason
        else:
            appointment.rejection_reason = None # Clear rejection reason if accepted

        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'Appointment {appointment_id} has been {new_status.lower()}.'
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Error updating appointment status: {e}'}), 500

@admin_routes.route('/doctors', methods=['POST'])
@jwt_required()
def add_doctor():
    admin_id = get_jwt_identity()
    data = request.get_json()

    if not data:
        return jsonify({'success': False, 'message': 'No data provided'}), 400

    name = data.get('name')
    specialization = data.get('specialization')
    phone = data.get('phone')
    email = data.get('email')
    password = data.get('password')    # 👈 Plain password (doctor ke liye)

    if not all([name, specialization, phone, email, password]):
        return jsonify({'success': False, 'message': 'Missing required fields'}), 400

    if len(phone) != 10 or not phone.isdigit():
        return jsonify({'success': False, 'message': 'Phone number must be 10 digits'}), 400

    try:
        # --- Create Doctor ---
        new_doctor = Doctor(
            name=name,
            specialization=specialization,
            phone=phone,
            email=email,
            hospital_id=admin_id,
            status="pending"
        )
        new_doctor.set_password(password)   # 👈 Hash DB me

        db.session.add(new_doctor)
        db.session.commit()

        # --- Hospital info ---
        hospital = Admin.query.get(admin_id)

        # --- PDF credentials banake secure karna (phone as passkey) ---
        pdf_bytes, masked_phone = create_credentials_pdf(
            doctor_name=new_doctor.name,
            email=new_doctor.email,
            password=password,
            phone=new_doctor.phone
        )

        # --- Mail banana ---
        subject = f"Your account for {hospital.hospital_name} on Arogyalink"
        sender = current_app.config['MAIL_USERNAME']
        recipients = [new_doctor.email]

        body = f"""
Hello {new_doctor.name},

You have been registered by {hospital.hospital_name} on Arogyalink.

👉 Your login credentials are attached as a secure PDF.
🔑 To open the PDF, please use your registered phone number. 
    (Example: {masked_phone})

You can now log in using the mobile app.

Thanks!
"""

        msg = Message(subject=subject, sender=sender, recipients=recipients, body=body)

        # --- PDF attach karna (direct bytes se) ---
        msg.attach("Credentials.pdf", "application/pdf", pdf_bytes)

        current_app.extensions.get('mail').send(msg)

        return jsonify({'success': True, 'message': 'Doctor account created and credentials sent!'}), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Error adding doctor: {e}'}), 500

# --- Get all doctors ---
@admin_routes.route('/doctors', methods=['GET'])
@jwt_required()
def get_doctors():
    admin_id = get_jwt_identity()
    doctors = Doctor.query.filter_by(hospital_id=admin_id).all()
    return jsonify({
        'success': True,
        'data': [doctor.to_dict() for doctor in doctors]
    }), 200


# --- Delete doctor ---
@admin_routes.route('/doctors/<int:doctor_id>', methods=['DELETE'])
@jwt_required()
def delete_doctor(doctor_id):
    admin_id = get_jwt_identity()
    doctor = Doctor.query.filter_by(id=doctor_id, hospital_id=admin_id).first()

    if not doctor:
        return jsonify({'success': False, 'message': 'Doctor not found'}), 404

    try:
        db.session.delete(doctor)
        db.session.commit()
        return jsonify({'success': True, 'message': 'Doctor deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Error deleting doctor: {e}'}), 500


# =========================================================================
# === NEW HOSPITALIZATION MANAGEMENT ENDPOINTS (FOR BED PARTITIONING) =====
# =========================================================================
# --- Get all Hospitalization Admissions for the Hospital ---
@admin_routes.route('/hospitalization_admissions', methods=['GET'])
@jwt_required()
def get_hospitalization_admissions():
    admin_id = get_jwt_identity()

    try:
        admissions = HospitalizationAdmission.query.filter_by(hospital_id=admin_id).all()
        admissions_list = [admission.to_dict() for admission in admissions]

        return jsonify({
            'success': True,
            'data': admissions_list
        }), 200

    except Exception as e:
        return jsonify({'success': False, 'message': f'Error fetching admissions: {e}'}), 500
    
@admin_routes.route('/hospitalization_admissions/<int:admission_id>', methods=['GET'])
@jwt_required()
def get_single_hospitalization_admission(admission_id):
    admin_id = get_jwt_identity()
    try:
        admission = HospitalizationAdmission.query.filter_by(
            id=admission_id, hospital_id=admin_id
        ).first()
        if not admission:
            return jsonify({'success': False, 'message': 'Admission not found'}), 404

        return jsonify({'success': True, 'data': admission.to_dict()}), 200
    except Exception as e:
        return jsonify({'success': False, 'message': f'Error: {e}'}), 500

@admin_routes.route('/hospitalization_admissions/<int:admission_id>/action', methods=['PUT'])
@jwt_required()
def action_hospitalization_admission(admission_id):
    """
    Endpoint to approve, reject, or discharge a hospitalization admission.
    Expected JSON body:
    {
        "action": "approve" | "reject" | "discharge", 
        "doctor_id": Optional, required if action is approve,
        "rejection_reason": Optional, required if action is reject
    }
    """
    admin_id = get_jwt_identity()
    data = request.get_json()

    if not data or 'action' not in data:
        return jsonify({'success': False, 'message': 'Action is required'}), 400

    action = data['action'].lower()
    doctor_id = data.get('doctor_id')
    rejection_reason = data.get('rejection_reason')
    
    # Fetch the admission
    admission = HospitalizationAdmission.query.filter_by(
        id=admission_id, hospital_id=admin_id
    ).first()

    if not admission:
        return jsonify({'success': False, 'message': 'Admission not found'}), 404

    # --- DISCHARGE LOGIC ---
    if action == 'discharge':
        if admission.status != 'Approved':
            return jsonify({
                'success': False, 
                'message': f"Cannot discharge patient. Current status is '{admission.status}'."
            }), 400

    # Free all allocated beds for this admission
        if admission.bed_partition_id:
            partition = BedPartition.query.get(admission.bed_partition_id)
            if partition:
                if partition.occupied_beds > 0:
                    partition.occupied_beds -= 1
                    partition.available_beds += 1

        admission.bed_partition_id = None  # reset allocation
        admission.status = 'Discharged'
        admission.discharge_date = datetime.utcnow()


    # --- APPROVE LOGIC ---
    elif action == 'approve':
        if admission.status == 'Approved':
            return jsonify({'success': False, 'message': 'Admission is already approved.'}), 400
        
        if not doctor_id:
            return jsonify({'success': False, 'message': 'Doctor ID is required to approve admission.'}), 400

        # Assign doctor
        admission.doctor_id = doctor_id

        # Update status
        admission.status = 'Approved'
        admission.rejection_reason = None

        # 💡 MODIFICATION: Assign bed to the first available partition
        available_partition = BedPartition.query.filter(
            BedPartition.hospital_id == admin_id,
            BedPartition.available_beds > 0  # Only look for partitions with available beds
        ).order_by(BedPartition.id.asc()).first() # Get the oldest/first created one

        if not available_partition:
            # 💡 New Error Message
            return jsonify({
                'success': False, 
                'message': 'No available beds in any partition to approve this admission.'
            }), 400

        # Update bed counts for the found partition
        available_partition.available_beds -= 1
        available_partition.occupied_beds += 1

        admission.bed_partition_id = available_partition.id
        # 💡 End of Modification
    # --- REJECT LOGIC ---
    elif action == 'reject':
        if admission.status == 'Approved':
            return jsonify({'success': False, 'message': 'Cannot reject an already approved admission.'}), 400
        
        if not rejection_reason or rejection_reason.strip() == '':
            return jsonify({'success': False, 'message': 'Rejection reason is required'}), 400
        
        admission.status = 'Rejected'
        admission.rejection_reason = rejection_reason.strip()
        admission.doctor_id = None  # Clear any previously assigned doctor

    # --- INVALID ACTION ---
    else:
        return jsonify({'success': False, 'message': 'Invalid action. Use "approve", "reject", or "discharge".'}), 400

    # Commit changes
    try:
        db.session.commit()
        return jsonify({
            'success': True,
            'message': f'Admission {action}d successfully',
            'data': admission.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Error: {e}'}), 500


# --- Fetch all OPD Appointments for Logged-in Admin's Hospital ---
@admin_routes.route('/opd_appointments', methods=['GET'])
@jwt_required()
def get_loggedin_hospital_opd_appointments():
    try:
        # 1. Get logged-in admin ID from JWT
        admin_id = get_jwt_identity()

        # 2. Fetch OPD appointments for this hospital only
        appointments = db.session.query(OPDAppointment, Doctor.name.label('doctor_name')).\
            outerjoin(Doctor, OPDAppointment.doctor_id == Doctor.id).\
            filter(OPDAppointment.hospital_id == admin_id).\
            order_by(OPDAppointment.created_at.desc()).\
            all()

        appointment_list = []
        for appointment, doctor_name in appointments:
            appointment_dict = appointment.to_dict()

            appointment_dict['doctor_name'] = doctor_name if doctor_name else "Unassigned/Doctor Removed"
            appointment_list.append(appointment_dict)

        return jsonify({
            'success': True,
            'message': f"Found {len(appointment_list)} OPD appointments for your hospital.",
            'data': appointment_list
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500

@admin_routes.route('/admissions/<int:admission_id>/shift_ward', methods=['PUT'])
@jwt_required()
def shift_ward_for_admission(admission_id):
    admin_id = get_jwt_identity()
    data = request.get_json()
    new_partition_id = data.get('new_bed_partition_id')

    if not new_partition_id:
        return jsonify({'success': False, 'message': 'New bed partition ID is required'}), 400

    # ✅ CORRECTION: HospitalizationAdmission क्लास का उपयोग करें
    admission_record = HospitalizationAdmission.query.filter_by(
        id=admission_id, 
        hospital_id=admin_id, 
        status='Approved'
    ).first()
    
    if not admission_record:
        return jsonify({'success': False, 'message': 'Approved admission not found or unauthorized'}), 404
    
    # पुरानी वार्ड ID प्राप्त करें
    old_partition_id = admission_record.bed_partition_id
    
    # लॉजिक सुधार: अगर पुरानी ID NULL है, तो इसका मतलब है कि यह पहली बार वार्ड असाइन हो रहा है
    if old_partition_id is not None and old_partition_id == new_partition_id:
        return jsonify({'success': False, 'message': 'Patient is already assigned to this partition'}), 400
    
    # 1. Fetch current and new partition
    # old_partition को तभी fetch करें जब patient पहले से किसी वार्ड में हो (shift के लिए)
    old_partition = None
    if old_partition_id is not None:
        old_partition = BedPartition.query.filter_by(id=old_partition_id, hospital_id=admin_id).first()
        # यदि old_partition नहीं मिलता है, तो यह डेटाबेस त्रुटि है लेकिन हम आगे बढ़ सकते हैं

    new_partition = BedPartition.query.filter_by(id=new_partition_id, hospital_id=admin_id).first()

    if not new_partition:
        return jsonify({'success': False, 'message': 'New partition not found'}), 404
        
    # 2. Check availability in the new partition
    if new_partition.available_beds <= 0:
        return jsonify({'success': False, 'message': f"New ward '{new_partition.partition_name}' has no available beds"}), 400

    try:
        # --- Transaction Start ---

        # 3. Update Old Partition (Remove patient/free up bed)
        # यह केवल तभी चलेगा जब old_partition_id मौजूद हो (अर्थात, यह एक actual shift है)
        if old_partition:
            old_partition.occupied_beds -= 1
            old_partition.available_beds += 1
        
        # 4. Update New Partition (Add patient/book bed)
        new_partition.occupied_beds += 1
        new_partition.available_beds -= 1
        
        # 5. Update Admission Record
        admission_record.bed_partition_id = new_partition_id
        
        db.session.commit()
        # --- Transaction End ---
        
        return jsonify({'success': True, 'message': f'Patient successfully shifted to {new_partition.partition_name}'}), 200

    except Exception as e:
        db.session.rollback()
        # लॉगिंग के लिए प्रिंट स्टेटमेंट (debugging के लिए उपयोगी)
        print(f"Database error during ward shift: {e}") 
        return jsonify({'success': False, 'message': 'Shift failed due to a server error.'}), 500
    
# routes/admin.py (Flask Backend)

@admin_routes.route('/hospitalization_admissions/discharged', methods=['GET'])
@jwt_required()
def get_discharged_hospitalization_admissions():
    admin_id = get_jwt_identity()

    # सिर्फ 'Discharged' स्टेटस वाले एडमिशन रिकॉर्ड्स को fetch करें
    admissions = HospitalizationAdmission.query.filter_by(
        hospital_id=admin_id,
        status='Discharged'
    ).order_by(HospitalizationAdmission.admission_date.desc()).all()

    admission_data = [admission.to_dict() for admission in admissions]

    return jsonify({
        'success': True,
        'message': 'Discharged admissions fetched successfully',
        'data': admission_data
    }), 200


@admin_routes.route('/doctor_treatment_history', methods=['GET'])
@jwt_required()
def get_doctor_treatment_history():
    admin_id = get_jwt_identity()  # Logged-in admin
    try:
        histories = (
            db.session.query(DoctorTreatmentHistory)
            .join(HospitalizationAdmission, DoctorTreatmentHistory.admission_id == HospitalizationAdmission.id)
            .filter(HospitalizationAdmission.hospital_id == admin_id)
            .order_by(DoctorTreatmentHistory.timestamp.desc())
            .all()
        )

        result = []
        for history in histories:
            record = history.to_dict()
            record['patient_name'] = history.admission.patient_name if history.admission else None
            record['doctor_name'] = history.doctor.name if history.doctor else None
            record['referral_reason'] = history.referral_reason if hasattr(history, 'referral_reason') else None
            result.append(record)

        return jsonify({'success': True, 'data': result}), 200

    except Exception as e:
        return jsonify({'success': False, 'message': f'Error: {e}'}), 500

@admin_routes.route("/treatment/unseen_count", methods=["GET"])
@jwt_required()
def get_unseen_count():
    admin_id = get_jwt_identity()   # yahi tumhara hospital_id hai
    
    count = (
        db.session.query(DoctorTreatmentHistory)
        .join(HospitalizationAdmission, DoctorTreatmentHistory.admission_id == HospitalizationAdmission.id)
        .filter(
            HospitalizationAdmission.hospital_id == admin_id,   # ✅ yaha hospital_id = admin.id use kiya hai
            DoctorTreatmentHistory.is_seen_by_admin == False
        )
        .count()
    )
    
    return jsonify({"success": True, "unseen_count": count})
@admin_routes.route("/treatment/mark_seen", methods=["PUT"])
@jwt_required()
def mark_treatment_seen():
    admin_id = get_jwt_identity()   # ✅ yaha bhi hospital_id ke equal hai

    # Step 1: Fetch all unseen treatment histories for this hospital
    treatments = DoctorTreatmentHistory.query.join(HospitalizationAdmission)\
        .filter(
            HospitalizationAdmission.hospital_id == admin_id,
            DoctorTreatmentHistory.is_seen_by_admin == False
        ).all()

    # Step 2: Mark each one as seen
    for t in treatments:
        t.is_seen_by_admin = True

    # Step 3: Commit changes
    db.session.commit()

    return jsonify({"success": True, "message": "All unseen treatment histories marked as seen"})

# Fetch all treatments for a given hospitalization
@admin_routes.route('/hospitalization/<int:admission_id>/treatments', methods=['GET'])
@jwt_required()
def get_treatment_history(admission_id):
    admin_id = get_jwt_identity()

    admission = HospitalizationAdmission.query.filter_by(id=admission_id, hospital_id=admin_id).first()
    if not admission:
        return jsonify({'success': False, 'message': 'Admission not found'}), 404

    treatments = DoctorTreatmentHistory.query.filter_by(admission_id=admission.id).all()
    return jsonify({
        'success': True,
        'data': [t.to_dict() for t in treatments]
    }), 200

@admin_routes.route('/hospitalization_bills/generate/<int:admission_id>', methods=['POST'])
@jwt_required()
def generate_hospitalization_bill(admission_id):
    admin_id = get_jwt_identity()
    
    # Fetch the admission
    admission = HospitalizationAdmission.query.filter_by(id=admission_id, hospital_id=admin_id).first()
    if not admission:
        return jsonify({'success': False, 'message': 'Admission not found'}), 404

    if not admission.discharge_date:
        return jsonify({'success': False, 'message': 'Patient not discharged yet'}), 400

    data = request.get_json() or {}

    # Extract charges from request body (default to 0)
    room_charges = float(data.get('room_charges', 0))
    treatment_charges = float(data.get('treatment_charges', 0))
    doctor_fees = float(data.get('doctor_fees', 0))
    medicine_charges = float(data.get('medicine_charges', 0))
    diagnostic_charges = float(data.get('diagnostic_charges', 0))
    misc_charges = float(data.get('misc_charges', 0))
    insurance_covered = float(data.get('insurance_covered', 0))

    # Correctly parse dates from ISO format
    admission_date = datetime.fromisoformat(admission.admission_date).date()
    discharge_date = admission.discharge_date.date()
    total_days = (discharge_date - admission_date).days + 1

    # Calculate totals
    gross_total = room_charges + treatment_charges + doctor_fees + medicine_charges + diagnostic_charges + misc_charges
    net_payable = gross_total - insurance_covered

    # Generate unique bill number
    bill_number = f"BILL-{admission.id}-{int(datetime.utcnow().timestamp())}"

    # Create and save bill
    bill = HospitalizationBill(
        hospitalization_id=admission.id,
        hospital_id=admin_id,
        patient_id=admission.patient_id,
        bill_number=bill_number,
        admission_date=admission.admission_date,
        discharge_date=discharge_date.strftime("%Y-%m-%d"),
        total_days=total_days,
        room_charges=room_charges,
        treatment_charges=treatment_charges,
        doctor_fees=doctor_fees,
        medicine_charges=medicine_charges,
        diagnostic_charges=diagnostic_charges,
        misc_charges=misc_charges,
        gross_total=gross_total,
        insurance_covered=insurance_covered,
        net_payable=net_payable,
        status="Unpaid"
    )

    db.session.add(bill)
    db.session.commit()

    return jsonify({
        'success': True,
        'message': 'Bill generated successfully',
        'data': bill.to_dict()
    }), 200

# --- Doctor Count GET Route (NEW) ---
@admin_routes.route('/doctor_count', methods=['GET'])
@jwt_required()
def get_doctor_count():
    admin_id = get_jwt_identity()
    
   
    doctor_count = Doctor.query.filter_by(hospital_id=admin_id).count() 

    return jsonify({'success': True, 'data': {'count': doctor_count}}), 200

@admin_routes.route('/check_setup_status', methods=['GET'])
@jwt_required()
def check_setup_status():
    try:
        # ✅ JWT se admin id lena
        admin_id = int(get_jwt_identity())

        # ✅ Doctor aur Partition existence check karna
        doctor_exists = Doctor.query.filter_by(hospital_id=admin_id).count() > 0
        partition_exists = BedPartition.query.filter_by(hospital_id=admin_id).count() > 0

        # ✅ Condition check
        if doctor_exists and partition_exists:
            return jsonify({
                "success": True,
                "setup_complete": True,
                "message": "Hospital setup is complete. You have doctors and partitions configured."
            }), 200
        else:
            missing_items = []
            if not doctor_exists:
                missing_items.append("doctor")
            if not partition_exists:
                missing_items.append("bed partition")

            return jsonify({
                "success": True,
                "setup_complete": False,
                "message": f"Hospital setup incomplete. Please add at least one {', '.join(missing_items)}."
            }), 200

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500
