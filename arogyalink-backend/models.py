from datetime import datetime
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
import base64

db = SQLAlchemy()  # Define db here (do NOT import from app.py)

class Patient(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)

    # Personal Information
    date_of_birth = db.Column(db.String(20))
    age = db.Column(db.Integer) # <--- ADDED AGE FIELD HERE
    gender = db.Column(db.String(10))
    mobile_number = db.Column(db.String(15))
    residential_address = db.Column(db.String(255))
    emergency_contact_name = db.Column(db.String(100))
    emergency_contact_number = db.Column(db.String(15))

    # Medical Information
    blood_group = db.Column(db.String(5))
    known_allergies = db.Column(db.Text)
    chronic_illnesses = db.Column(db.Text)
    current_medications = db.Column(db.Text)
    past_surgeries = db.Column(db.Text)
    vaccination_details = db.Column(db.Text)

    country = db.Column(db.String(100))
    state = db.Column(db.String(100))

    # Column to store the profile image as binary data
    profile_image = db.Column(db.LargeBinary, nullable=True)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        encoded_image = None
        if self.profile_image:
            encoded_image = base64.b64encode(self.profile_image).decode('utf-8')

        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'date_of_birth': self.date_of_birth,
            'age': self.age, # <--- ADDED AGE TO DICT
            'gender': self.gender,
            'mobile_number': self.mobile_number,
            'residential_address': self.residential_address,
            'emergency_contact_name': self.emergency_contact_name,
            'emergency_contact_number': self.emergency_contact_number,
            'blood_group': self.blood_group,
            'known_allergies': self.known_allergies,
            'chronic_illnesses': self.chronic_illnesses,
            'current_medications': self.current_medications,
            'past_surgeries': self.past_surgeries,
            'vaccination_details': self.vaccination_details,
            'profile_image_base64': encoded_image,
            'country': self.country,
            'state': self.state
        }

# In your models.py
class Admin(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)

    # ✅ Add this crucial column
    status = db.Column(db.String(20), default='pending', nullable=False)
    approval_token = db.Column(db.String(64), unique=True, nullable=True)
    rejection_token = db.Column(db.String(64), unique=True, nullable=True)

    # Hospital Info
    hospital_name = db.Column(db.String(255), nullable=True)
    hospital_type = db.Column(db.String(50), nullable=True)
    owner_name = db.Column(db.String(255), nullable=True)
    contact = db.Column(db.String(20), nullable=True)
    alt_contact = db.Column(db.String(20), nullable=True)

    # Address
    address = db.Column(db.String(255), nullable=True)
    landmark = db.Column(db.String(255), nullable=True)
    state = db.Column(db.String(50), nullable=True)
    country = db.Column(db.String(50), nullable=True)

    # Latitude and Longitude
    latitude = db.Column(db.Float, nullable=True)
    longitude = db.Column(db.Float, nullable=True)

    # Facility Details
    emergency = db.Column(db.Boolean, default=False, nullable=True)
    departments = db.Column(db.Text, nullable=True)
    opd_available = db.Column(db.Boolean, default=False, nullable=True)
    opd_start_time = db.Column(db.String(20), nullable=True)
    opd_end_time = db.Column(db.String(20), nullable=True)
    license_number = db.Column(db.String(50), nullable=True)

    # ✅ New UPI ID field
    upi_id = db.Column(db.String(100), nullable=True)

    # ✅ NEW FIELD: Admission Fees
    admission_fees = db.Column(db.Float, nullable=True)

    # Change these columns from path strings to BLOBs
    registration_certificate = db.Column(db.LargeBinary, nullable=True)
    admin_id_proof = db.Column(db.LargeBinary, nullable=True)
    hospital_logo = db.Column(db.LargeBinary, nullable=True)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        # Convert all BLOBs to Base64 strings for JSON serialization
        registration_certificate_base64 = None
        if self.registration_certificate:
            registration_certificate_base64 = base64.b64encode(self.registration_certificate).decode('utf-8')

        admin_id_proof_base64 = None
        if self.admin_id_proof:
            admin_id_proof_base64 = base64.b64encode(self.admin_id_proof).decode('utf-8')

        hospital_logo_base64 = None
        if self.hospital_logo:
            hospital_logo_base64 = base64.b64encode(self.hospital_logo).decode('utf-8')

        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'status': self.status,
            'hospital_name': self.hospital_name,
            'hospital_type': self.hospital_type,
            'owner_name': self.owner_name,
            'contact': self.contact,
            'alt_contact': self.alt_contact,
            'address': self.address,
            'landmark': self.landmark,
            'state': self.state,
            'country': self.country,
            'latitude': self.latitude,
            'longitude': self.longitude,
            'emergency': self.emergency,
            'departments': self.departments,
            'opd_available': self.opd_available,
            'opd_start_time': self.opd_start_time,
            'opd_end_time': self.opd_end_time,
            'license_number': self.license_number,
            'upi_id': self.upi_id,
            'admission_fees': self.admission_fees, # ✅ include in dict
            'registration_certificate': registration_certificate_base64,
            'admin_id_proof': admin_id_proof_base64,
            'hospital_logo': hospital_logo_base64
        }

class OTP(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), nullable=False)
    otp = db.Column(db.String(6), nullable=False)
    expiry = db.Column(db.DateTime, nullable=False)

    def is_valid(self, otp_code):
        return self.otp == otp_code and self.expiry > datetime.utcnow()
    
class BedPartition(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    hospital_id = db.Column(db.Integer, db.ForeignKey('admin.id'), nullable=False)
    partition_name = db.Column(db.String(100), nullable=False)
    
    # ✅ CHANGES: Bed tracking fields added
    total_beds = db.Column(db.Integer, nullable=False)
    available_beds = db.Column(db.Integer, nullable=False, default=0) # Logic will set this to total_beds on creation
    occupied_beds = db.Column(db.Integer, nullable=False, default=0)
    # -------------------------------------

    def __repr__(self):
        return f"<BedPartition id={self.id} name='{self.partition_name}' hospital_id={self.hospital_id}>"

    def to_dict(self):
        return {
            'id': self.id,
            'hospital_id': self.hospital_id,
            'partition_name': self.partition_name,
            'total_beds': self.total_beds,
            # ✅ CHANGES: Added new fields to dict
            'available_beds': self.available_beds,
            'occupied_beds': self.occupied_beds,
            # -------------------------------------
        }

class Appointment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patient.id'), nullable=False)
    hospital_id = db.Column(db.Integer, db.ForeignKey('admin.id'), nullable=False)

    appointment_date = db.Column(db.String(20), nullable=False)
    appointment_time = db.Column(db.String(20), nullable=False)
    reason_for_visit = db.Column(db.Text, nullable=True)
    symptoms = db.Column(db.Text, nullable=True)

    status = db.Column(db.String(20), default="Pending")
    rejection_reason = db.Column(db.Text, nullable=True) 

    patient = db.relationship('Patient', backref=db.backref('appointments', lazy=True))
    hospital = db.relationship('Admin', backref=db.backref('appointments', lazy=True))

    def to_dict(self):
        return {
            'id': self.id,
            'patient_id': self.patient_id,
            'hospital_id': self.hospital_id,
            'appointment_date': self.appointment_date,
            'appointment_time': self.appointment_time,
            'reason_for_visit': self.reason_for_visit,
            'symptoms': self.symptoms,
            'status': self.status,
            'rejection_reason': self.rejection_reason,
            'patient_details': self.patient.to_dict() if self.patient else None,
        }
    
class HospitalizationAdmission(db.Model):
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)

    # Relationships
    patient_id = db.Column(db.Integer, db.ForeignKey('patient.id'), nullable=False)
    hospital_id = db.Column(db.Integer, db.ForeignKey('admin.id'), nullable=False)
    
    # 1. ASSIGNED Doctor ID (Hospital Admin sets this)
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctor.id'), nullable=True) 
    
    # 2. ✅ NEW: REFERRING Doctor ID (Comes from OPD Appointment)
    referring_doctor_id = db.Column(db.Integer, db.ForeignKey('doctor.id'), nullable=True) 
    
    opd_appointment_id = db.Column(db.Integer, db.ForeignKey('opd_appointment.id'), nullable=True)

    # Bed Partition
    bed_partition_id = db.Column(db.Integer, db.ForeignKey('bed_partition.id'), nullable=True)
    bed_partition = db.relationship('BedPartition', backref=db.backref('admissions', lazy=True))

    # Patient Details
    patient_name = db.Column(db.String(100), nullable=False)
    patient_age = db.Column(db.Integer, nullable=False)
    gender = db.Column(db.String(10), nullable=False)
    contact_number = db.Column(db.String(15), nullable=False)
    email = db.Column(db.String(120), nullable=True)

    # Admission Details
    admission_date = db.Column(db.String(20), nullable=False)
    reason_symptoms = db.Column(db.Text, nullable=False)

    # Insurance / Payment
    insurance_provider = db.Column(db.String(100), nullable=True)
    insurance_policy_number = db.Column(db.String(100), nullable=True)
    payment_mode = db.Column(db.String(20), nullable=True)

    # Emergency Contact
    guardian_name = db.Column(db.String(100), nullable=True)
    guardian_relationship = db.Column(db.String(50), nullable=True)
    guardian_contact_number = db.Column(db.String(15), nullable=True)

    # Medical Notes
    special_instructions = db.Column(db.Text, nullable=True)
    allergies = db.Column(db.Text, nullable=True)
    past_surgeries = db.Column(db.Text, nullable=True)
    current_medications = db.Column(db.Text, nullable=True)
    discharge_date = db.Column(db.DateTime, nullable=True)
    
    # Status & Rejection
    status = db.Column(db.String(30), default="Pending", nullable=False)
    rejection_reason = db.Column(db.Text, nullable=True) 
    is_seen_by_doctor = db.Column(db.Boolean, default=False)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    patient = db.relationship('Patient', backref=db.backref('hospitalizations', lazy=True))
    hospital = db.relationship('Admin', backref=db.backref('hospitalizations', lazy=True))
    doctor = db.relationship('Doctor', foreign_keys=[doctor_id], backref=db.backref('hospitalizations_assigned', lazy=True))
    opd_appointment = db.relationship('OPDAppointment', backref=db.backref('hospitalizations', lazy=True))
    # Relationship for referring doctor
    referring_doctor = db.relationship('Doctor', foreign_keys=[referring_doctor_id], backref=db.backref('hospitalizations_referred', lazy=True))


    def to_dict(self):
        data = {
            "id": self.id,
            "patient_id": self.patient_id,
            "hospital_id": self.hospital_id,
            "doctor_id": self.doctor_id,
            "opd_appointment_id": self.opd_appointment_id,
            "bed_partition_id": self.bed_partition_id,
            
            "referring_doctor_id": self.referring_doctor_id, # <<< NEW 
            
            "patient_name": self.patient_name,
            "patient_age": self.patient_age,
            "gender": self.gender,
            "contact_number": self.contact_number,
            "email": self.email,

            "admission_date": self.admission_date,
            "reason_symptoms": self.reason_symptoms,

            "insurance_provider": self.insurance_provider,
            "insurance_policy_number": self.insurance_policy_number,
            "payment_mode": self.payment_mode,

            "guardian_name": self.guardian_name,
            "guardian_relationship": self.guardian_relationship,
            "guardian_contact_number": self.guardian_contact_number,

            "special_instructions": self.special_instructions,
            "allergies": self.allergies,
            "past_surgeries": self.past_surgeries,
            "current_medications": self.current_medications,

            "status": self.status,
            "rejection_reason": self.rejection_reason,
            "is_seen_by_doctor": self.is_seen_by_doctor,
            "discharge_date": self.discharge_date.strftime("%Y-%m-%d %H:%M:%S") if self.discharge_date else None,
            "created_at": self.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            "updated_at": self.updated_at.strftime("%Y-%m-%d %H:%M:%S")
        }
        
        # ✅ Referrals Details (for the Appointment Details Screen)
        if self.opd_appointment and self.opd_appointment.doctor:
            referring_doc = self.opd_appointment.doctor
            
            # --- Doctor Details ---
            data['referring_doctor_name'] = referring_doc.name if referring_doc.name else 'N/A'
            data['referring_doctor_specialization'] = referring_doc.specialization if hasattr(referring_doc, 'specialization') and referring_doc.specialization else 'N/A' # <<< ADDED
            
            # --- Hospital Details (Joining through Doctor -> Admin) ---
            if hasattr(referring_doc, 'hospital') and referring_doc.hospital:
                data['referring_doctor_hospital_name'] = referring_doc.hospital.hospital_name if referring_doc.hospital.hospital_name else 'Hospital N/A' # <<< ADDED
            else:
                data['referring_doctor_hospital_name'] = 'Hospital N/A'
            
            # --- Referral Notes ---
            data['referral_reason'] = self.opd_appointment.referral_reason if self.opd_appointment.referral_reason else 'N/A' 
            data['referral_symptoms'] = self.opd_appointment.symptoms if self.opd_appointment.symptoms else 'N/A'
            data['referral_prescription_details'] = self.opd_appointment.prescription_details if self.opd_appointment.prescription_details else 'N/A'

        else:
             # Default N/A if not referred via OPD (Self-Admission or data missing)
            data['referring_doctor_name'] = 'N/A (Self-Admission)'
            data['referring_doctor_specialization'] = 'N/A' 
            data['referring_doctor_hospital_name'] = 'N/A' 
            data['referral_reason'] = 'N/A'
            data['referral_symptoms'] = 'N/A'
            data['referral_prescription_details'] = 'N/A'
            
        return data
# ✅ NEW: Feedback Model (KEPT AS IT IS)
class Feedback(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    feedback_type = db.Column(db.String(50), nullable=False)
    feedback_text = db.Column(db.Text, nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    patient_id = db.Column(db.Integer, db.ForeignKey('patient.id'), nullable=True)
    hospital_id = db.Column(db.Integer, db.ForeignKey('admin.id'), nullable=True)

class Doctor(db.Model):
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(100), nullable=False)
    specialization = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(15), unique=True, nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)

    # 🔹 NEW FIELDS
    password_hash = db.Column(db.String(200), nullable=True) 
    status = db.Column(db.String(20), default="pending") 
    invite_token = db.Column(db.String(200), nullable=True) 
    invited_at = db.Column(db.DateTime, default=datetime.utcnow)
    activated_at = db.Column(db.DateTime, nullable=True)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Hospital relation (Foreign Key)
    hospital_id = db.Column(db.Integer, db.ForeignKey('admin.id'), nullable=False)
    
    # ✅ NEW: Add the SQLAlchemy relationship to Admin model
    hospital = db.relationship('Admin', backref=db.backref('doctors', lazy=True)) # <<< ADDED RELATIONSHIP
    
    def to_dict(self):
        # 💡 NOTE: You can also include the hospital name here if needed for other endpoints
        hospital_name = self.hospital.hospital_name if self.hospital else 'N/A'
        
        return {
            "id": self.id,
            "name": self.name,
            "specialization": self.specialization,
            "phone": self.phone,
            "email": self.email,
            "status": self.status,
            "hospital_id": self.hospital_id,
            # Including hospital name directly in doctor dict for convenience
            "hospital_name": hospital_name,
            "created_at": self.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            "invited_at": self.invited_at.strftime("%Y-%m-%d %H:%M:%S") if self.invited_at else None,
            "activated_at": self.activated_at.strftime("%Y-%m-%d %H:%M:%S") if self.activated_at else None,
        }
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class OPDAppointment(db.Model):
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)

    hospital_id = db.Column(db.Integer, db.ForeignKey('admin.id'), nullable=False)
    doctor_id = db.Column(
        db.Integer,
        db.ForeignKey('doctor.id', ondelete="SET NULL"),
        nullable=True
    )
    patient_id = db.Column(
        db.Integer,
        db.ForeignKey('patient.id', ondelete="CASCADE"),
        nullable=False
    )

    # Patient info
    patient_name = db.Column(db.String(100), nullable=False)
    patient_age = db.Column(db.Integer, nullable=False)
    patient_contact = db.Column(db.String(15), nullable=False)
    patient_email = db.Column(db.String(120), nullable=False)
    gender = db.Column(db.String(10), nullable=False)

    # Appointment info
    appointment_date = db.Column(db.String(20), nullable=False)
    start_time = db.Column(db.String(20), nullable=False)
    end_time = db.Column(db.String(20), nullable=False)
    symptoms = db.Column(db.Text, nullable=False)
    is_emergency = db.Column(db.Boolean, default=False, nullable=False)
    is_booked = db.Column(db.Boolean, default=True, nullable=False)
    status = db.Column(db.String(30), default='Pending', nullable=False)
    referral_reason = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    token_number = db.Column(db.Integer, nullable=False)

    # Prescription info
    prescription_details = db.Column(db.Text, nullable=True)
    prescription_created_by = db.Column(db.Integer, db.ForeignKey('doctor.id'), nullable=True)
    prescription_created_at = db.Column(db.DateTime, nullable=True)
    # Billing info
    bill_generated = db.Column(db.Boolean, default=False, nullable=False)  # Has the bill been generated
    bill_paid = db.Column(db.Boolean, default=False, nullable=False)       # Has the bill been paid
    payment_mode = db.Column(db.String(10), nullable=True)   
    visiting_fee = db.Column(db.Float, nullable=True)  # Doctor's visiting fee
    checkup_fee = db.Column(db.Float, nullable=True)  # Checkup fee
    tax_percent = db.Column(db.Float, nullable=True)  # Tax percentage if applicable
    total_amount = db.Column(db.Float, nullable=True)  # Total amount after tax
    bill_generated_at = db.Column(db.DateTime, nullable=True)  # When the bill was generated
    bill_pdf_path = db.Column(db.String(200), nullable=True)  # Optional: path of generated PDF

    # Relationships
    hospital = db.relationship('Admin', backref=db.backref('opd_appointments', lazy=True))
    doctor = db.relationship(
        'Doctor',
        foreign_keys=[doctor_id],
        backref=db.backref('opd_appointments', lazy=True),
        passive_deletes=True
    )
    prescription_creator = db.relationship(
        'Doctor',
        foreign_keys=[prescription_created_by],
        backref=db.backref('prescriptions_created', lazy=True)
    )
    patient = db.relationship(
        'Patient',
        backref=db.backref('opd_appointments', lazy=True)
    )

    def to_dict(self):
        return {
            'id': self.id,
            'hospital_id': self.hospital_id,
            'doctor_id': self.doctor_id,
            'doctor_name': self.doctor.name if self.doctor else None,
            'patient_id': self.patient_id,
            'patient_name': self.patient_name,
            'patient_age': self.patient_age,
            'patient_contact': self.patient_contact,
            'patient_email': self.patient_email,
            'gender': self.gender,
            'appointment_date': self.appointment_date,
            'start_time': self.start_time,
            'end_time': self.end_time,
            'symptoms': self.symptoms,
            'is_emergency': self.is_emergency,
            'is_booked': self.is_booked,
            'status': self.status,
            'referral_reason': self.referral_reason,
            'created_at': self.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            'token_number': self.token_number,
            'prescription_details': self.prescription_details,
            'prescription_created_by': self.prescription_created_by,
            'prescription_created_at': self.prescription_created_at.strftime("%Y-%m-%d %H:%M:%S") 
                                             if self.prescription_created_at else None,
            'bill_generated': self.bill_generated,
            'bill_paid': self.bill_paid,
            'payment_mode': self.payment_mode,
            'visiting_fee': self.visiting_fee,
            'checkup_fee': self.checkup_fee,
            'tax_percent': self.tax_percent,
            'total_amount': self.total_amount,
            'bill_generated_at': self.bill_generated_at.strftime("%Y-%m-%d %H:%M:%S") if self.bill_generated_at else None,
            'bill_pdf_path': self.bill_pdf_path
        }
    
class OPDSlot(db.Model):
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    hospital_id = db.Column(db.Integer, db.ForeignKey('admin.id'), nullable=False)
    doctor_id = db.Column(
        db.Integer,
        db.ForeignKey('doctor.id', ondelete="CASCADE"),
        nullable=False
    )
    appointment_date = db.Column(db.String(20), nullable=False)  # e.g. "2025-09-13"
    start_time = db.Column(db.String(20), nullable=False)        # e.g. "09:00 AM"
    end_time = db.Column(db.String(20), nullable=False)          # e.g. "09:20 AM"
    is_booked = db.Column(db.Boolean, default=False, nullable=False)
    is_available = db.Column(db.Boolean, default=True, nullable=False)   # ✅ New
    remarks = db.Column(db.String(255), nullable=True)                    # ✅ Optional

    hospital = db.relationship('Admin', backref=db.backref('opd_slots', lazy=True))
    doctor = db.relationship(
        'Doctor',
        backref=db.backref('opd_slots', cascade="all, delete-orphan")
    )

    def to_dict(self):
        return {
            "id": self.id,
            "hospital_id": self.hospital_id,
            "doctor_id": self.doctor_id,
            "appointment_date": self.appointment_date,
            "start_time": self.start_time,
            "end_time": self.end_time,
            "is_booked": self.is_booked,
            "is_available": self.is_available,
            "remarks": self.remarks
        }
    
class DoctorTreatmentHistory(db.Model):
    __tablename__ = "doctor_treatment_history"

    id = db.Column(db.Integer, primary_key=True)
    admission_id = db.Column(db.Integer, db.ForeignKey('hospitalization_admission.id'), nullable=False)
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctor.id'), nullable=False)
    treatment_notes = db.Column(db.Text, nullable=True)
    status_update = db.Column(db.String(50), nullable=False)
    referral_reason = db.Column(db.Text, nullable=True)

    # NEW FIELD: whether admin has seen this treatment entry
    is_seen_by_admin = db.Column(db.Boolean, default=False, nullable=False)

    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    # relationships
    admission = db.relationship("HospitalizationAdmission", backref="treatment_history")
    doctor = db.relationship("Doctor", backref="treatment_history")

    def to_dict(self):
        return {
            "id": self.id,
            "admission_id": self.admission_id,
            "doctor_id": self.doctor_id,
            "treatment_notes": self.treatment_notes,
            "status_update": self.status_update,
            "referral_reason": self.referral_reason,
            "is_seen_by_admin": bool(self.is_seen_by_admin),
            "timestamp": self.timestamp.isoformat() if self.timestamp else None,
        }

class HospitalizationBill(db.Model):
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)

    # Relations
    hospitalization_id = db.Column(db.Integer, db.ForeignKey('hospitalization_admission.id'), nullable=False)
    hospital_id = db.Column(db.Integer, db.ForeignKey('admin.id'), nullable=False)
    patient_id = db.Column(db.Integer, db.ForeignKey('patient.id'), nullable=False)

    # Bill Details
    bill_number = db.Column(db.String(50), unique=True, nullable=False)
    admission_date = db.Column(db.String(20), nullable=False)
    discharge_date = db.Column(db.String(20), nullable=False)
    total_days = db.Column(db.Integer, nullable=False)

    # Charges
    room_charges = db.Column(db.Float, default=0.0)
    treatment_charges = db.Column(db.Float, default=0.0)
    doctor_fees = db.Column(db.Float, default=0.0)
    medicine_charges = db.Column(db.Float, default=0.0)
    diagnostic_charges = db.Column(db.Float, default=0.0)
    misc_charges = db.Column(db.Float, default=0.0)

    # Final Amount
    gross_total = db.Column(db.Float, default=0.0)
    insurance_covered = db.Column(db.Float, default=0.0)
    net_payable = db.Column(db.Float, default=0.0)

    # Payment Info
    payment_mode = db.Column(db.String(20), nullable=True)  # UPI, Cash, Card
    transaction_id = db.Column(db.String(100), nullable=True)
    status = db.Column(db.String(20), default="Unpaid")  # Paid / Pending

    # 👇 New field added here
    seen_by_patient = db.Column(db.Boolean, default=False)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    hospitalization = db.relationship('HospitalizationAdmission', backref=db.backref('bills', lazy=True))
    patient = db.relationship('Patient', backref=db.backref('bills', lazy=True))
    hospital = db.relationship('Admin', backref=db.backref('bills', lazy=True))

    def to_dict(self):
        return {
            "id": self.id,
            "hospitalization_id": self.hospitalization_id,
            "hospital_id": self.hospital_id,
            "patient_id": self.patient_id,

            "bill_number": self.bill_number,
            "admission_date": self.admission_date,
            "discharge_date": self.discharge_date,
            "total_days": self.total_days,

            "room_charges": self.room_charges,
            "treatment_charges": self.treatment_charges,
            "doctor_fees": self.doctor_fees,
            "medicine_charges": self.medicine_charges,
            "diagnostic_charges": self.diagnostic_charges,
            "misc_charges": self.misc_charges,

            "gross_total": self.gross_total,
            "insurance_covered": self.insurance_covered,
            "net_payable": self.net_payable,

            "payment_mode": self.payment_mode,
            "transaction_id": self.transaction_id,
            "status": self.status,
            "seen_by_patient": self.seen_by_patient,  # 👈 include in dict

            "created_at": self.created_at.strftime("%Y-%m-%d %H:%M:%S") if self.created_at else None,
            "updated_at": self.updated_at.strftime("%Y-%m-%d %H:%M:%S") if self.updated_at else None
        }
