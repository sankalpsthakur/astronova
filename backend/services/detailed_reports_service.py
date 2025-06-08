from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
import json
from services.astro_calculator import AstroCalculator
from services.claude_ai import ClaudeService
from fpdf import FPDF
import redis
import os

class DetailedReportsService:
    def __init__(self):
        self.astro_calculator = AstroCalculator()
        self.claude_ai = ClaudeService()
        # In production, use Redis for report storage
        self.redis_client = None
        try:
            if os.environ.get('REDIS_URL'):
                self.redis_client = redis.from_url(os.environ.get('REDIS_URL'))
        except:
            pass
        
        # Fallback to in-memory storage for development
        self.memory_store = {}
    
    def generate_detailed_report(self, birth_data: Dict[str, Any], report_type: str, 
                               options: Dict[str, Any] = None, user_id: str = None) -> Dict[str, Any]:
        """Generate comprehensive astrological report based on type"""
        
        # Calculate birth chart using proper method
        from services.astro_calculator import BirthData
        
        birth_data_obj = BirthData(
            date=birth_data['date'],
            time=birth_data['time'],
            timezone=birth_data['timezone'],
            latitude=birth_data['latitude'],
            longitude=birth_data['longitude']
        )
        
        chart_data = self.astro_calculator.calculate_birth_chart(birth_data_obj)
        
        # Generate report based on type
        if report_type == "love_forecast":
            return self._generate_love_forecast(chart_data, birth_data, options)
        elif report_type == "birth_chart":
            return self._generate_birth_chart_reading(chart_data, birth_data, options)
        elif report_type == "career_forecast":
            return self._generate_career_forecast(chart_data, birth_data, options)
        elif report_type == "year_ahead":
            return self._generate_year_ahead(chart_data, birth_data, options)
        else:
            raise ValueError(f"Unknown report type: {report_type}")
    
    def _generate_love_forecast(self, chart_data: Dict, birth_data: Dict, options: Dict) -> Dict[str, Any]:
        """Generate detailed love and relationship forecast"""
        
        # Extract relevant astrological data for love analysis
        venus_position = chart_data.get('planets', {}).get('Venus', {})
        mars_position = chart_data.get('planets', {}).get('Mars', {})
        moon_position = chart_data.get('planets', {}).get('Moon', {})
        seventh_house = chart_data.get('houses', {}).get('7', {})
        fifth_house = chart_data.get('houses', {}).get('5', {})
        
        prompt = f"""
        Generate a comprehensive love and relationship forecast based on this birth chart data:
        
        Venus (love, beauty, relationships): {venus_position}
        Mars (passion, desire, action): {mars_position}
        Moon (emotions, feelings): {moon_position}
        7th House (partnerships, marriage): {seventh_house}
        5th House (romance, dating, creativity): {fifth_house}
        
        Provide a detailed analysis covering:
        1. Current romantic energy and timing
        2. Ideal partner qualities and compatibility
        3. Relationship patterns and karmic lessons
        4. Best periods for love in the coming year
        5. Areas for personal growth in relationships
        6. Specific guidance for single vs. partnered individuals
        
        Make it personal, insightful, and actionable. Use astrological terminology appropriately but keep it accessible.
        """
        
        ai_content = self.claude_ai.generate_content(prompt, max_tokens=2000)
        
        key_insights = [
            "Venus placement reveals your love language and attraction patterns",
            "Mars position shows how you pursue and express romantic desires",
            "7th house indicates partnership karma and relationship destiny",
            "Upcoming planetary transits will create new romantic opportunities"
        ]
        
        return {
            'title': 'Love & Relationship Forecast',
            'content': ai_content,
            'summary': 'A comprehensive analysis of your romantic potential, relationship patterns, and love forecast for the year ahead.',
            'keyInsights': key_insights
        }
    
    def _generate_birth_chart_reading(self, chart_data: Dict, birth_data: Dict, options: Dict) -> Dict[str, Any]:
        """Generate complete birth chart interpretation"""
        
        sun_position = chart_data.get('planets', {}).get('Sun', {})
        moon_position = chart_data.get('planets', {}).get('Moon', {})
        rising_sign = chart_data.get('ascendant', {})
        aspects = chart_data.get('aspects', [])
        
        prompt = f"""
        Generate a comprehensive natal chart reading based on this birth chart data:
        
        Sun (core identity, purpose): {sun_position}
        Moon (emotions, subconscious): {moon_position}
        Rising/Ascendant (persona, first impressions): {rising_sign}
        Major Aspects: {aspects[:5]}  # Top 5 aspects
        
        Provide a detailed interpretation covering:
        1. Core personality and life purpose (Sun sign analysis)
        2. Emotional nature and inner needs (Moon sign analysis)
        3. How others see you and your approach to life (Rising sign)
        4. Key planetary aspects and their influences
        5. Life themes and karmic patterns
        6. Strengths, challenges, and growth opportunities
        7. Career inclinations and natural talents
        8. Relationship patterns and compatibility factors
        
        Make it a complete personality profile that feels accurate and insightful.
        """
        
        ai_content = self.claude_ai.generate_content(prompt, max_tokens=2500)
        
        key_insights = [
            "Your Sun sign reveals your core life purpose and identity",
            "Moon sign shows your emotional needs and subconscious patterns",
            "Rising sign influences how you appear to others and approach life",
            "Planetary aspects create the unique blueprint of your personality"
        ]
        
        return {
            'title': 'Complete Birth Chart Reading',
            'content': ai_content,
            'summary': 'Your comprehensive astrological blueprint revealing personality, life purpose, and cosmic influences.',
            'keyInsights': key_insights
        }
    
    def _generate_career_forecast(self, chart_data: Dict, birth_data: Dict, options: Dict) -> Dict[str, Any]:
        """Generate career and professional guidance"""
        
        midheaven = chart_data.get('midheaven', {})
        tenth_house = chart_data.get('houses', {}).get('10', {})
        sixth_house = chart_data.get('houses', {}).get('6', {})
        saturn_position = chart_data.get('planets', {}).get('Saturn', {})
        jupiter_position = chart_data.get('planets', {}).get('Jupiter', {})
        
        prompt = f"""
        Generate a comprehensive career and professional forecast based on this birth chart data:
        
        Midheaven (career calling, public image): {midheaven}
        10th House (career, reputation, achievements): {tenth_house}
        6th House (daily work, service, health): {sixth_house}
        Saturn (discipline, structure, mastery): {saturn_position}
        Jupiter (expansion, opportunities, growth): {jupiter_position}
        
        Provide detailed guidance covering:
        1. Natural career inclinations and professional calling
        2. Best industries and work environments for success
        3. Leadership style and professional strengths
        4. Career timing and upcoming opportunities
        5. Challenges to overcome for professional growth
        6. Ideal work-life balance and values alignment
        7. Financial potential and wealth-building strategies
        8. Professional relationships and networking
        
        Make it practical and actionable for career development.
        """
        
        ai_content = self.claude_ai.generate_content(prompt, max_tokens=2000)
        
        key_insights = [
            "Midheaven reveals your true professional calling and public image",
            "Saturn placement shows where discipline leads to mastery",
            "Jupiter indicates areas of natural expansion and opportunity",
            "Timing analysis reveals best periods for career moves"
        ]
        
        return {
            'title': 'Career & Professional Forecast',
            'content': ai_content,
            'summary': 'Strategic career guidance based on your astrological blueprint for professional success.',
            'keyInsights': key_insights
        }
    
    def _generate_year_ahead(self, chart_data: Dict, birth_data: Dict, options: Dict) -> Dict[str, Any]:
        """Generate comprehensive year ahead forecast"""
        
        # Calculate upcoming transits and progressions
        current_transits = self.astro_calculator.calculate_current_transits()
        solar_return = self.astro_calculator.calculate_solar_return(birth_data)
        
        prompt = f"""
        Generate a comprehensive year ahead forecast based on:
        
        Birth Chart Data: {chart_data}
        Current Transits: {current_transits}
        Solar Return Analysis: {solar_return}
        
        Provide a month-by-month breakdown covering:
        1. Major themes and energy shifts throughout the year
        2. Best times for new beginnings, relationships, career moves
        3. Challenging periods and how to navigate them
        4. Personal growth opportunities and life lessons
        5. Financial and material manifestation potential
        6. Health and wellness guidance
        7. Spiritual development and consciousness expansion
        8. Key dates and astrological events to watch
        
        Make it a practical roadmap for the year with specific timing.
        """
        
        ai_content = self.claude_ai.generate_content(prompt, max_tokens=3000)
        
        key_insights = [
            "Solar return chart reveals the main themes for your new year",
            "Major transits will bring significant life changes and opportunities",
            "Eclipses will activate karmic release and new beginnings",
            "Retrograde periods offer time for reflection and course correction"
        ]
        
        return {
            'title': 'Year Ahead Cosmic Forecast',
            'content': ai_content,
            'summary': 'Your complete cosmic roadmap for the year ahead with timing, themes, and opportunities.',
            'keyInsights': key_insights
        }
    
    def store_report(self, report_id: str, report_data: Dict[str, Any]):
        """Store generated report for retrieval"""
        if self.redis_client:
            # Store in Redis with 1 year expiration
            self.redis_client.setex(
                f"report:{report_id}", 
                timedelta(days=365), 
                json.dumps(report_data)
            )
        else:
            # Fallback to memory storage
            self.memory_store[report_id] = report_data
    
    def get_report(self, report_id: str) -> Optional[Dict[str, Any]]:
        """Retrieve stored report"""
        if self.redis_client:
            data = self.redis_client.get(f"report:{report_id}")
            if data:
                return json.loads(data)
        else:
            return self.memory_store.get(report_id)
        return None
    
    def get_user_reports(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all reports for a specific user"""
        user_reports = []
        
        if self.redis_client:
            # In production, you'd have a more efficient way to query user reports
            # This is a simplified implementation
            for key in self.redis_client.scan_iter(match="report:*"):
                data = self.redis_client.get(key)
                if data:
                    report = json.loads(data)
                    if report.get('userId') == user_id:
                        user_reports.append(report)
        else:
            # Memory storage fallback
            for report in self.memory_store.values():
                if report.get('userId') == user_id:
                    user_reports.append(report)
        
        # Sort by generation date, newest first
        user_reports.sort(key=lambda x: x.get('generatedAt', ''), reverse=True)
        return user_reports
    
    def generate_pdf_report(self, report_data: Dict[str, Any]) -> bytes:
        """Generate PDF version of the report"""
        pdf = FPDF()
        pdf.add_page()
        
        # Title
        pdf.set_font("Arial", "B", 16)
        pdf.cell(0, 10, report_data['title'], ln=True, align='C')
        pdf.ln(10)
        
        # Generated date
        pdf.set_font("Arial", "I", 10)
        pdf.cell(0, 5, f"Generated: {report_data['generatedAt']}", ln=True, align='C')
        pdf.ln(10)
        
        # Summary
        if report_data.get('summary'):
            pdf.set_font("Arial", "B", 12)
            pdf.cell(0, 8, "Summary", ln=True)
            pdf.set_font("Arial", "", 10)
            pdf.multi_cell(0, 5, report_data['summary'])
            pdf.ln(5)
        
        # Key Insights
        if report_data.get('keyInsights'):
            pdf.set_font("Arial", "B", 12)
            pdf.cell(0, 8, "Key Insights", ln=True)
            pdf.set_font("Arial", "", 10)
            for insight in report_data['keyInsights']:
                pdf.cell(0, 5, f"• {insight}", ln=True)
            pdf.ln(5)
        
        # Main content
        pdf.set_font("Arial", "B", 12)
        pdf.cell(0, 8, "Detailed Analysis", ln=True)
        pdf.set_font("Arial", "", 10)
        
        # Split content into manageable chunks for PDF
        content = report_data['content']
        lines = content.split('\n')
        for line in lines:
            if len(line) > 80:
                # Wrap long lines
                words = line.split(' ')
                current_line = ""
                for word in words:
                    if len(current_line + word) < 80:
                        current_line += word + " "
                    else:
                        if current_line:
                            pdf.cell(0, 5, current_line.strip(), ln=True)
                        current_line = word + " "
                if current_line:
                    pdf.cell(0, 5, current_line.strip(), ln=True)
            else:
                pdf.cell(0, 5, line, ln=True)
        
        return pdf.output(dest='S').encode('latin1')