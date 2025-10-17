import io
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from PyPDF2 import PdfReader, PdfWriter


def mask_phone(phone: str) -> str:
    """Mask phone number except last 3 digits."""
    return "*" * (len(phone) - 3) + phone[-3:]


def create_credentials_pdf(doctor_name, email, password, phone):
    """
    Create a password-protected PDF with doctor credentials.
    Passkey = full phone number (doctor's registered phone).
    Returns: (pdf_bytes, masked_phone)
    """

    # Step 1: Create PDF in memory
    pdf_buffer = io.BytesIO()
    c = canvas.Canvas(pdf_buffer, pagesize=letter)

    c.setFont("Helvetica-Bold", 16)
    c.drawString(100, 700, "Doctor Login Credentials")

    c.setFont("Helvetica", 12)
    c.drawString(100, 670, f"Doctor: {doctor_name}")
    c.drawString(100, 650, f"Email: {email}")
    c.drawString(100, 630, f"Password: {password}")

    c.save()

    # Step 2: Protect PDF with phone number
    pdf_buffer.seek(0)

    reader = PdfReader(pdf_buffer)
    writer = PdfWriter()

    for page in reader.pages:
        writer.add_page(page)

    # Encrypt with full phone number
    writer.encrypt(phone)

    output_buffer = io.BytesIO()
    writer.write(output_buffer)
    output_buffer.seek(0)

    # Return pdf bytes + masked phone number (for email)
    return output_buffer.read(), mask_phone(phone)
