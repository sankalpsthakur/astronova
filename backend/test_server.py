#!/usr/bin/env python3
"""
Minimal test server to verify Gemini chat functionality
"""
import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from services.claude_ai import ClaudeService

# Set environment variables
os.environ['GEMINI_API_KEY'] = 'AIzaSyDK1UcAyU0e-8WpdooG-6-p10p1UuYmZD8'
os.environ['SECRET_KEY'] = 'test-secret-key'

app = Flask(__name__)
CORS(app)

# Initialize Gemini service
claude_service = ClaudeService()

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'gemini_configured': bool(claude_service.api_key)})

@app.route('/api/v1/chat', methods=['GET'])
def chat_info():
    return jsonify({
        'service': 'chat',
        'status': 'available',
        'gemini_configured': bool(claude_service.api_key),
        'endpoints': {
            'POST /send': 'Send a chat message'
        }
    })

@app.route('/api/v1/chat/send', methods=['POST'])
def send_message():
    try:
        data = request.get_json()
        if not data or 'message' not in data:
            return jsonify({'error': 'Message is required'}), 400
        
        message = data['message']
        conversation_id = data.get('conversationId', 'test')
        
        # Send message to Gemini
        response = claude_service.send_message(message)
        
        return jsonify({
            'reply': response.get('reply'),
            'messageId': response.get('message_id'),
            'conversationId': conversation_id,
            'suggestedFollowUps': [
                "What's my love forecast? 💖",
                "Career guidance? ⭐",
                "Today's energy? ☀️"
            ]
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("Starting test server with Gemini integration...")
    print(f"Gemini API configured: {bool(claude_service.api_key)}")
    app.run(host='127.0.0.1', port=5000, debug=True)