from fpdf import FPDF

class ReportService:
    def generate_pdf(self, title: str, content: str) -> bytes:
        pdf = FPDF()
        pdf.add_page()
        pdf.set_font("Arial", size=12)
        pdf.cell(200, 10, txt=title, ln=1, align='C')
        pdf.multi_cell(0, 10, txt=content)
        return pdf.output(dest='S').encode('latin1')
