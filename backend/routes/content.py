from flask import Blueprint, jsonify, request
from typing import List, Dict, Any

content_bp = Blueprint('content', __name__)

# Mock data for content management - in production, this would come from a database
QUICK_QUESTIONS = [
    {
        "id": "1",
        "text": "What's my love forecast? 💖",
        "category": "love",
        "order": 1,
        "is_active": True
    },
    {
        "id": "2", 
        "text": "Career guidance? ⭐",
        "category": "career",
        "order": 2,
        "is_active": True
    },
    {
        "id": "3",
        "text": "Today's energy? ☀️",
        "category": "daily",
        "order": 3,
        "is_active": True
    },
    {
        "id": "4",
        "text": "What should I focus on? 🎯",
        "category": "guidance", 
        "order": 4,
        "is_active": True
    },
    {
        "id": "5",
        "text": "Lucky numbers today? 🍀",
        "category": "daily",
        "order": 5,
        "is_active": True
    },
    {
        "id": "6",
        "text": "Mercury retrograde effects? ☿",
        "category": "planetary",
        "order": 6,
        "is_active": True
    },
    {
        "id": "7",
        "text": "Best time for decisions? 🌙",
        "category": "timing",
        "order": 7,
        "is_active": True
    }
]

INSIGHTS = [
    {
        "id": "1",
        "title": "Daily Energy",
        "content": "Your cosmic energy forecast for today",
        "category": "daily",
        "priority": 1,
        "is_active": True
    },
    {
        "id": "2",
        "title": "Love & Relationships", 
        "content": "Insights into your romantic journey",
        "category": "love",
        "priority": 2,
        "is_active": True
    },
    {
        "id": "3",
        "title": "Career Path",
        "content": "Professional guidance from the stars",
        "category": "career", 
        "priority": 3,
        "is_active": True
    },
    {
        "id": "4",
        "title": "Spiritual Growth",
        "content": "Your path to higher consciousness",
        "category": "spiritual",
        "priority": 4,
        "is_active": True
    }
]

@content_bp.route('/management', methods=['GET'])
def get_content_management():
    """
    Get all content management data including quick questions and insights
    """
    try:
        # Filter active items and sort appropriately
        active_questions = [q for q in QUICK_QUESTIONS if q['is_active']]
        active_questions.sort(key=lambda x: x['order'])
        
        active_insights = [i for i in INSIGHTS if i['is_active']]
        active_insights.sort(key=lambda x: x['priority'])
        
        return jsonify({
            "quick_questions": active_questions,
            "insights": active_insights
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

