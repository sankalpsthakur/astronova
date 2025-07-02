#!/usr/bin/env python3
"""
Quick test script for Gemini API integration
"""
import os
import sys
sys.path.append('.')

from services.claude_ai import ClaudeService

def test_gemini():
    # Set the API key for testing
    os.environ['GEMINI_API_KEY'] = 'AIzaSyDK1UcAyU0e-8WpdooG-6-p10p1UuYmZD8'
    
    print("Testing Gemini API integration...")
    
    # Initialize the service
    claude_service = ClaudeService()
    
    # Test basic message
    print("\n1. Testing basic message...")
    try:
        response = claude_service.send_message("Hello, can you tell me about astrology?")
        print(f"Response: {response}")
    except Exception as e:
        print(f"Error: {e}")
    
    # Test content generation
    print("\n2. Testing content generation...")
    try:
        content = claude_service.generate_content("Generate a brief horoscope for Aries today")
        print(f"Generated content: {content}")
    except Exception as e:
        print(f"Error: {e}")
    
    print("\nTest completed!")

if __name__ == "__main__":
    test_gemini()