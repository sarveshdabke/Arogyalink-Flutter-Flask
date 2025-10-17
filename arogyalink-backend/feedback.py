# feedback.py

from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from flask_cors import CORS
from flask_mail import Message, Mail
from models import db, Patient, Admin, Feedback
from datetime import datetime

feedback_bp = Blueprint('feedback_bp', __name__)
CORS(feedback_bp)

# Assuming 'mail' is initialized in your main app.py file
mail = Mail() 

@feedback_bp.route('/submit', methods=['POST'])
@jwt_required()
def submit_feedback():
    """
    Submits feedback from either a patient or a hospital and sends an email notification.
    """
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        feedback_type = data.get('feedbackType')
        feedback_text = data.get('feedbackText')

        if not feedback_type or not feedback_text:
            return jsonify({'success': False, 'message': 'Feedback type and text are required.'}), 400

        patient = Patient.query.get(user_id)
        hospital = Admin.query.get(user_id)

        patient_id = None
        hospital_id = None
        sender_name = "Unknown User"
        
        # Determine sender and get their name
        if patient:
            patient_id = user_id
            sender_name = patient.username
        elif hospital:
            hospital_id = user_id
            sender_name = hospital.hospital_name
        else:
            return jsonify({'success': False, 'message': 'Invalid user. Feedback cannot be submitted.'}), 403

        # Save feedback to the database
        new_feedback = Feedback(
            feedback_type=feedback_type,
            feedback_text=feedback_text,
            patient_id=patient_id,
            hospital_id=hospital_id,
            timestamp=datetime.utcnow()
        )
        db.session.add(new_feedback)
        db.session.commit()

        # ✅ NEW: Send email notification
        try:
            msg = Message(
                subject=f"New Feedback: {feedback_type} from {sender_name}",
                sender=current_app.config['MAIL_USERNAME'],
                recipients=['dabkesarvesh7@gmail.com'] # Replace with your destination email
            )
            msg.body = f"""
            Hello,

            A new feedback has been submitted.

            Sender: {sender_name}
            Feedback Type: {feedback_type}
            
            Message:
            {feedback_text}

            ---
            This is an automated message.
            """
            mail.send(msg)
        except Exception as e:
            # Log the email sending error, but don't fail the feedback submission
            current_app.logger.error(f"Failed to send feedback email: {e}")


        return jsonify({'success': True, 'message': 'Feedback submitted successfully.'}), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500