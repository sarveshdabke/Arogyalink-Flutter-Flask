# doctor.py
from datetime import date, datetime, timedelta
from operator import or_
from flask import Blueprint, current_app, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from routes.auth_routes import generate_slots
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from io import BytesIO
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import Paragraph
from flask_mail import Message
from models import Doctor, Admin, DoctorTreatmentHistory, HospitalizationAdmission, OPDAppointment, OPDSlot, db  # adjust imports as per your project

doctor_routes = Blueprint('doctor_routes', __name__)

@doctor_routes.route('/me', methods=['GET'])
@jwt_required()
def get_logged_in_doctor():
    """
    Fetch the currently logged-in doctor's data using JWT identity.
    """
    doctor_id = int(get_jwt_identity())
    doctor = Doctor.query.get(doctor_id)

    if not doctor:
        return jsonify({'success': False, 'message': 'Doctor not found'}), 404

    # Fetch hospital name from Admin table using doctor.hospital_id
    hospital = Admin.query.get(doctor.hospital_id)
    hospital_name = hospital.hospital_name if hospital else None

    return jsonify({
        'success': True,
        'data': {
            'id': doctor.id,
            'name': doctor.name,
            'specialization': doctor.specialization,
            'phone': doctor.phone,
            'email': doctor.email,
            'hospital_name': hospital_name
        }
    })

@doctor_routes.route('/my-slots/<date>', methods=['GET'])
@jwt_required()
def get_doctor_slots(date):
    """
    Fetch all OPD slots for the logged-in doctor for a given date.
    Includes booked/unbooked and availability status.
    """
    doctor_id = int(get_jwt_identity())

    # Fetch all slots for this doctor and date
    slots = OPDSlot.query.filter_by(doctor_id=doctor_id, appointment_date=date).all()

    if not slots:
        return jsonify({'success': True, 'data': [], 'message': 'No slots found for this date'}), 200

    # Return slots as a list of dicts
    slot_list = [slot.to_dict() for slot in slots]

    return jsonify({'success': True, 'data': slot_list}), 200

@doctor_routes.route('/maintain-slots', methods=['POST'])
def maintain_doctor_slots():
    """
    Maintain rolling 7-day slots:
    1️⃣ Delete unbooked past slots
    2️⃣ Preserve booked slots
    3️⃣ Ensure slots exist for today + next 6 days
    """
    today = date.today()
    doctors = Doctor.query.filter_by(status='active').all()

    for doctor in doctors:
        # 1️⃣ Delete unbooked past slots
        OPDSlot.query.filter(
            OPDSlot.doctor_id == doctor.id,
            OPDSlot.appointment_date < today,
            OPDSlot.is_booked == False
        ).delete()
        db.session.commit()

        # 2️⃣ Ensure slots for next 7 days
        hospital = Admin.query.get(doctor.hospital_id)
        if not hospital:
            continue

        for i in range(7):  # today + 6 days
            target_date = today + timedelta(days=i)

            # check if slots already exist for this date
            existing = OPDSlot.query.filter_by(
                doctor_id=doctor.id,
                appointment_date=target_date
            ).first()

            if not existing:
                # generate for this single date
                generate_slots(
                    doctor_id=doctor.id,
                    hospital_id=doctor.hospital_id,
                    start_time_str=hospital.opd_start_time,
                    end_time_str=hospital.opd_end_time,
                    days_to_generate=1,  # only 1 day at a time
                    start_date=target_date  # pass target date explicitly
                )

    return jsonify({'success': True, 'message': 'Slots maintained successfully'}), 200


@doctor_routes.route('/appointments', methods=['GET'])
@jwt_required()
def get_doctor_appointments():
    """
    Fetch all appointments for the logged-in doctor, grouped by date.
    """
    doctor_id = int(get_jwt_identity())
    appointments = OPDAppointment.query.filter_by(doctor_id=doctor_id).order_by(OPDAppointment.appointment_date).all()

    grouped = {}
    for appt in appointments:
        date = appt.appointment_date
        if date not in grouped:
            grouped[date] = []
        grouped[date].append(appt.to_dict())

    return jsonify({'success': True, 'data': grouped}), 200

@doctor_routes.route('/slot/<int:slot_id>', methods=['PUT'])
@jwt_required()
def edit_slot(slot_id):
    data = request.get_json()
    slot = OPDSlot.query.get(slot_id)
    if not slot:
        return jsonify({'success': False, 'message': 'Slot not found'}), 404

    # Example: update start_time and end_time
    slot.start_time = data.get('start_time', slot.start_time)
    slot.end_time = data.get('end_time', slot.end_time)

    db.session.commit()
    return jsonify({'success': True, 'message': 'Slot updated', 'slot': {
        'id': slot.id,
        'start_time': slot.start_time,
        'end_time': slot.end_time
    }}), 200

@doctor_routes.route('/slot/<int:slot_id>', methods=['DELETE'])
@jwt_required()
def delete_slot(slot_id):
    slot = OPDSlot.query.get(slot_id)
    if not slot:
        return jsonify({'success': False, 'message': 'Slot not found'}), 404

    if slot.is_booked:
        return jsonify({'success': False, 'message': 'Cannot delete booked slot'}), 400

    db.session.delete(slot)
    db.session.commit()
    return jsonify({'success': True, 'message': 'Slot deleted'}), 200

@doctor_routes.route('/slot', methods=['POST'])
@jwt_required()
def create_slot():
    data = request.get_json()
    doctor_id = int(get_jwt_identity())
    
    appointment_date = data.get('appointment_date')
    start_time = data.get('start_time')
    end_time = data.get('end_time')
    
    if not all([appointment_date, start_time, end_time]):
        return jsonify({'success': False, 'message': 'Missing required fields'}), 400

    # Check if slot already exists
    existing = OPDSlot.query.filter_by(
        doctor_id=doctor_id,
        appointment_date=appointment_date,
        start_time=start_time,
        end_time=end_time
    ).first()
    if existing:
        return jsonify({'success': False, 'message': 'Slot already exists'}), 400

    # Create new slot
    new_slot = OPDSlot(
        doctor_id=doctor_id,
        hospital_id=Doctor.query.get(doctor_id).hospital_id,
        appointment_date=appointment_date,
        start_time=start_time,
        end_time=end_time,
        is_available=True,
        is_booked=False
    )
    db.session.add(new_slot)
    db.session.commit()

    return jsonify({
        'success': True,
        'message': 'Slot created successfully',
        'slot': {
            'id': new_slot.id,
            'appointment_date': new_slot.appointment_date,
            'start_time': new_slot.start_time,
            'end_time': new_slot.end_time
        }
    }), 201

@doctor_routes.route('/appointment/<int:appointment_id>/status', methods=['PUT'])
@jwt_required()
def update_appointment_status(appointment_id):
    """
    Update appointment status to 'Completed', 'Cancelled', or 'Referred' with reason
    """
    data = request.get_json()
    new_status = data.get('status')
    referral_reason = data.get('referral_reason')  # extra field for referral

    # Allowed statuses
    valid_statuses = ['Completed', 'Cancelled', 'Referred']
    if new_status not in valid_statuses:
        return jsonify({'success': False, 'message': 'Invalid status'}), 400

    appointment = OPDAppointment.query.get(appointment_id)
    if not appointment:
        return jsonify({'success': False, 'message': 'Appointment not found'}), 404

    # If referred, reason must be provided
    if new_status == 'Referred':
        if not referral_reason:
            return jsonify({'success': False, 'message': 'Referral reason is required'}), 400
        appointment.referral_reason = referral_reason

    appointment.status = new_status
    db.session.commit()

    return jsonify({'success': True, 'message': f'Appointment marked as {new_status}'}), 200

@doctor_routes.route('/appointments/referred', methods=['GET'])
@jwt_required()
def get_referred_appointments():
    doctor_id = int(get_jwt_identity())  # logged-in doctor

    referred_appts = OPDAppointment.query.filter_by(
        doctor_id=doctor_id,
        status='Referred'
    ).all()

    return jsonify({
        'success': True,
        'appointments': [appt.to_dict() for appt in referred_appts]
    }), 200

@doctor_routes.route('/appointments/completed', methods=['GET'])
@jwt_required()
def get_completed_appointments():
    doctor_id = int(get_jwt_identity())  # Logged-in doctor
    completed_appts = OPDAppointment.query.filter(
    OPDAppointment.doctor_id == doctor_id,
    or_(
        OPDAppointment.status == 'Completed',
        OPDAppointment.status == 'Referred'
    )
).order_by(OPDAppointment.appointment_date).all()

    return jsonify({
        'success': True,
        'appointments': [appt.to_dict() for appt in completed_appts]
    }), 200

@doctor_routes.route('/appointment/<int:appointment_id>/prescription', methods=['PUT'])
@jwt_required()
def add_prescription(appointment_id):
    data = request.get_json()
    prescription_details = data.get('prescription_details')

    if not prescription_details:
        return jsonify({'success': False, 'message': 'Prescription details required'}), 400

    appointment = OPDAppointment.query.get(appointment_id)
    if not appointment:
        return jsonify({'success': False, 'message': 'Appointment not found'}), 404

    appointment.prescription_details = prescription_details
    appointment.prescription_created_by = int(get_jwt_identity())
    appointment.prescription_created_at = datetime.utcnow()

    db.session.commit()

    return jsonify({'success': True, 'message': 'Prescription saved successfully'}), 200

@doctor_routes.route('/appointments/bill_pending', methods=['GET'])
@jwt_required()
def get_patients_for_bill():
    doctor_id = int(get_jwt_identity())
    
    # Fetch patients with prescription done but bill not generated
    appointments = OPDAppointment.query.filter(
        OPDAppointment.doctor_id == doctor_id,
        OPDAppointment.prescription_details != None,
        OPDAppointment.bill_generated == False
    ).all()
    
    return jsonify({
        'success': True,
        'appointments': [a.to_dict() for a in appointments]
    }), 200

@doctor_routes.route('/appointments/generate_bill', methods=['POST'])
@jwt_required()
def generate_bill():
    from app import db, mail
    doctor_id = int(get_jwt_identity())
    data = request.get_json()

    appointment_id = data.get('appointment_id')
    visiting_fee = float(data.get('visiting_fee', 0.0))
    checkup_fee = float(data.get('checkup_fee', 0.0))
    tax_percent = float(data.get('tax_percent', 0.0))

    if not appointment_id:
        return jsonify({'success': False, 'message': 'Appointment ID required'}), 400

    appointment = OPDAppointment.query.filter_by(
        id=appointment_id,
        doctor_id=doctor_id
    ).first()

    if not appointment:
        return jsonify({'success': False, 'message': 'Appointment not found'}), 404

    if appointment.bill_generated:
        return jsonify({'success': False, 'message': 'Bill already generated'}), 400

    total_amount = visiting_fee + checkup_fee + tax_percent

    # Update DB
    appointment.visiting_fee = visiting_fee
    appointment.checkup_fee = checkup_fee
    appointment.tax_percent = tax_percent
    appointment.total_amount = total_amount
    appointment.bill_generated = True
    appointment.bill_generated_at = datetime.utcnow()
    db.session.commit()

    doctor = Doctor.query.get(doctor_id)
    hospital = Admin.query.get(doctor.hospital_id)
    patient_email = appointment.patient_email

    pdf_buffer = BytesIO()
    c = canvas.Canvas(pdf_buffer, pagesize=A4)
    width, height = A4

    styles = getSampleStyleSheet()
    styleN = styles['Normal']

    # App name + logo
    c.setFont("Helvetica-Bold", 16)
    c.drawString(200, 800, "Arogyalink")
    logo_path = r"C:\Users\Main\arogyalink-backend\routes\images\logo.png"
    c.drawImage(logo_path, 450, 780, width=100, height=50)

    y = 770

    # Doctor details
    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "Doctor Details:")
    y -= 15
    c.setFont("Helvetica", 11)
    c.drawString(70, y, f"Name: {doctor.name}")
    y -= 15
    c.drawString(70, y, f"Specialization: {doctor.specialization}")
    y -= 15
    c.drawString(70, y, f"Email: {doctor.email}")
    y -= 15
    c.drawString(70, y, f"Phone: {doctor.phone}")
    y -= 25

    # Hospital details
    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "Hospital Details:")
    y -= 15
    c.setFont("Helvetica", 11)
    c.drawString(70, y, f"Name: {hospital.hospital_name}")
    y -= 15

    hospital_address = Paragraph(f"Address: {hospital.address}", styleN)
    w, h = hospital_address.wrap(400, 100)
    hospital_address.drawOn(c, 70, y - h + 11)
    y = y - h - 5

    c.drawString(70, y, f"Contact: {hospital.contact}")
    y -= 15
    c.drawString(70, y, f"License: {hospital.license_number}")
    y -= 15
    c.drawString(70, y, f"State: {hospital.state}, Country: {hospital.country}")
    y -= 25

    # Patient details
    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "Patient Details:")
    y -= 15
    c.setFont("Helvetica", 11)
    c.drawString(70, y, f"Name: {appointment.patient_name}")
    y -= 15
    c.drawString(70, y, f"Age: {appointment.patient_age}")
    y -= 15
    c.drawString(70, y, f"Gender: {appointment.gender}")
    y -= 15
    c.drawString(70, y, f"Email: {appointment.patient_email}")
    y -= 15
    c.drawString(70, y, f"Symptoms: {appointment.symptoms}")
    y -= 15

    prescription = Paragraph(f"Prescription: {appointment.prescription_details}", styleN)
    w, h = prescription.wrap(400, 150)
    prescription.drawOn(c, 70, y - h + 11)
    y = y - h - 10

    # Bill details
    c.setFont("Helvetica-Bold", 12)
    c.drawString(50, y, "Bill Summary:")
    y -= 15
    c.setFont("Helvetica", 11)
    c.drawString(70, y, f"Visiting Fee: ₹{visiting_fee}")
    y -= 15
    c.drawString(70, y, f"Checkup Fee: ₹{checkup_fee}")
    y -= 15
    c.drawString(70, y, f"Tax/Charges: ₹{tax_percent}")
    y -= 15
    c.drawString(70, y, f"Total: ₹{total_amount}")

    c.save()
    pdf_buffer.seek(0)

    msg = Message(
        subject="Your OPD Bill - Arogyalink",
        sender=current_app.config['MAIL_USERNAME'],
        recipients=[patient_email]
    )
    msg.body = "Dear Patient,\n\nPlease find attached your OPD Bill.\n\nRegards,\nArogyalink"
    msg.attach("OPD_Bill.pdf", "application/pdf", pdf_buffer.read())

    try:
        mail.send(msg)
    except Exception as e:
        return jsonify({'success': False, 'message': f'Bill saved but email failed: {str(e)}'}), 500

    return jsonify({
        'success': True,
        'message': 'Bill generated and emailed successfully',
        'bill': appointment.to_dict()
    }), 200

@doctor_routes.route('/hospitalization_admissions', methods=['GET'])
@jwt_required()
def get_hospitalization_admissions():
    """
    Returns all hospitalization admissions assigned to the logged-in doctor
    """
    doctor_id = get_jwt_identity()  # Assuming JWT identity is doctor.id
    admissions = HospitalizationAdmission.query.filter_by(doctor_id=doctor_id).all()

    admissions_list = [adm.to_dict() for adm in admissions]

    return jsonify({
        "success": True,
        "data": admissions_list
    }), 200

@doctor_routes.route('/hospitalization_admissions/<int:admission_id>/doctor_action', methods=['PUT'])
@jwt_required()
def doctor_hospitalization_action(admission_id):
    doctor_id = get_jwt_identity()  # logged in doctor
    data = request.get_json()

    if not data:
        return jsonify({'success': False, 'message': 'No data provided'}), 400

    admission = HospitalizationAdmission.query.filter_by(
        id=admission_id,
        doctor_id=doctor_id
    ).first()

    if not admission:
        return jsonify({'success': False, 'message': 'Admission not found for this doctor'}), 404

    # Get submitted fields
    treatment_notes = data.get('doctor_treatment_notes')
    status_update = data.get('doctor_status_update')
    referral_reason = data.get('doctor_referral_reason')

    if status_update not in ['In Progress', 'Referred', 'Discharged']:
        return jsonify({'success': False, 'message': 'Invalid status'}), 400

    # --- Create new DoctorTreatmentHistory row ---
    history = DoctorTreatmentHistory(
    admission_id=admission_id,
    doctor_id=doctor_id,
    treatment_notes=treatment_notes,
    status_update=status_update,
    referral_reason=referral_reason if status_update == 'Referred' else None,
)


    try:
        db.session.add(history)
        db.session.commit()

        return jsonify({
            'success': True,
            'message': 'Doctor action saved in history table',
            'data': history.to_dict()  # Return the newly created row
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Error: {e}'}), 500

@doctor_routes.route("/admissions/mark_seen", methods=["PUT"])
@jwt_required()
def mark_admissions_seen():
    doctor_id = get_jwt_identity()

    # Update all unseen admissions for this doctor
    db.session.query(HospitalizationAdmission) \
        .filter(
            HospitalizationAdmission.doctor_id == doctor_id,
            HospitalizationAdmission.is_seen_by_doctor == False
        ) \
        .update({HospitalizationAdmission.is_seen_by_doctor: True}, synchronize_session=False)

    db.session.commit()

    return jsonify({"success": True, "message": "All unseen admissions marked as seen"})
@doctor_routes.route("/admissions/unseen_count", methods=["GET"])
@jwt_required()
def get_unseen_admissions_count():
    doctor_id = get_jwt_identity()

    unseen_count = db.session.query(HospitalizationAdmission) \
        .filter(
            HospitalizationAdmission.doctor_id == doctor_id,
            HospitalizationAdmission.is_seen_by_doctor == False
        ).count()

    return jsonify({"success": True, "unseen_count": unseen_count})
