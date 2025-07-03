#!/usr/bin/env python3
"""
AstroNova Backend API Comprehensive Test Suite
Generates detailed testing report with all endpoints
"""

import os
import sys
import json
import requests
import time
from datetime import datetime
from typing import Dict, List, Any
import subprocess
import signal

# Configuration
BASE_URL = "http://127.0.0.1:5001"
REPORT_DIR = "test_reports"
os.makedirs(REPORT_DIR, exist_ok=True)

# Test results storage
test_results = {
    "test_run_info": {
        "timestamp": datetime.now().isoformat(),
        "base_url": BASE_URL,
        "total_tests": 0,
        "passed": 0,
        "failed": 0,
        "warnings": 0
    },
    "services": {},
    "summary": {}
}

class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_header(text):
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'=' * 60}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text.center(60)}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'=' * 60}{Colors.END}\n")

def print_test(name, status, details=""):
    test_results["test_run_info"]["total_tests"] += 1
    if status == "PASS":
        test_results["test_run_info"]["passed"] += 1
        print(f"{Colors.GREEN}✓ {name}{Colors.END}")
    elif status == "FAIL":
        test_results["test_run_info"]["failed"] += 1
        print(f"{Colors.RED}✗ {name}{Colors.END}")
    elif status == "WARN":
        test_results["test_run_info"]["warnings"] += 1
        print(f"{Colors.YELLOW}⚠ {name}{Colors.END}")
    
    if details:
        print(f"  {details}")

def test_endpoint(method, endpoint, data=None, headers=None, service_name=""):
    """Test a single endpoint and return results"""
    url = f"{BASE_URL}{endpoint}"
    try:
        if method == "GET":
            response = requests.get(url, headers=headers, timeout=10)
        elif method == "POST":
            response = requests.post(url, json=data, headers=headers, timeout=10)
        elif method == "PUT":
            response = requests.put(url, json=data, headers=headers, timeout=10)
        else:
            response = requests.delete(url, headers=headers, timeout=10)
        
        result = {
            "endpoint": endpoint,
            "method": method,
            "status_code": response.status_code,
            "response_time": response.elapsed.total_seconds(),
            "success": 200 <= response.status_code < 300,
            "response": response.json() if response.content else {}
        }
        
        # Store in service results
        if service_name:
            if service_name not in test_results["services"]:
                test_results["services"][service_name] = {"endpoints": []}
            test_results["services"][service_name]["endpoints"].append(result)
        
        return result
        
    except requests.exceptions.ConnectionError:
        result = {
            "endpoint": endpoint,
            "method": method,
            "status_code": 0,
            "response_time": 0,
            "success": False,
            "error": "Connection refused - server not running"
        }
        if service_name:
            if service_name not in test_results["services"]:
                test_results["services"][service_name] = {"endpoints": []}
            test_results["services"][service_name]["endpoints"].append(result)
        return result
    except Exception as e:
        result = {
            "endpoint": endpoint,
            "method": method,
            "status_code": 0,
            "response_time": 0,
            "success": False,
            "error": str(e)
        }
        if service_name:
            if service_name not in test_results["services"]:
                test_results["services"][service_name] = {"endpoints": []}
            test_results["services"][service_name]["endpoints"].append(result)
        return result

def test_health_check():
    print_header("Health Check")
    result = test_endpoint("GET", "/health", service_name="health")
    
    if result["success"]:
        print_test("Health endpoint", "PASS", f"Response time: {result['response_time']:.3f}s")
        if result["response"].get("gemini_configured"):
            print_test("Gemini API configured", "PASS")
        else:
            print_test("Gemini API configured", "WARN", "Gemini API key not set")
    else:
        print_test("Health endpoint", "FAIL", result.get("error", ""))

def test_auth_service():
    print_header("Authentication Service")
    
    # Test info endpoint
    result = test_endpoint("GET", "/api/v1/auth", service_name="auth")
    if result["success"]:
        print_test("Auth info endpoint", "PASS")
    else:
        print_test("Auth info endpoint", "FAIL")
    
    # Test mock login
    login_data = {"userId": "test-user-" + str(int(time.time()))}
    result = test_endpoint("POST", "/api/v1/auth/mock-login", data=login_data, service_name="auth")
    
    if result["success"]:
        print_test("Mock login", "PASS")
        token = result["response"].get("jwtToken")
        if token:
            print_test("JWT token generated", "PASS", f"Token length: {len(token)}")
            return token
        else:
            print_test("JWT token generated", "FAIL", "No token in response")
    else:
        print_test("Mock login", "FAIL")
    
    return None

def test_chat_service():
    print_header("Chat Service (Gemini AI)")
    
    # Test info endpoint
    result = test_endpoint("GET", "/api/v1/chat", service_name="chat")
    if result["success"]:
        print_test("Chat info endpoint", "PASS")
        if result["response"].get("gemini_configured"):
            print_test("Gemini integration", "PASS")
        else:
            print_test("Gemini integration", "WARN", "Using mock responses")
    else:
        print_test("Chat info endpoint", "FAIL")
    
    # Test chat message
    chat_data = {
        "message": "What are the lucky colors for Pisces today?",
        "conversationId": f"test-{int(time.time())}"
    }
    
    result = test_endpoint("POST", "/api/v1/chat/send", data=chat_data, service_name="chat")
    
    if result["success"]:
        print_test("Chat message send", "PASS", f"Response time: {result['response_time']:.3f}s")
        reply = result["response"].get("reply", "")
        if len(reply) > 50:
            print_test("AI response quality", "PASS", f"Response length: {len(reply)} chars")
        else:
            print_test("AI response quality", "WARN", "Response seems short")
    else:
        print_test("Chat message send", "FAIL")

def test_horoscope_service():
    print_header("Horoscope Service")
    
    result = test_endpoint("GET", "/api/v1/horoscope", service_name="horoscope")
    if result["success"]:
        print_test("Horoscope endpoint", "PASS")
        if "sample_data" in result["response"]:
            print_test("Sample data available", "PASS")
        else:
            print_test("Sample data available", "WARN")
    else:
        print_test("Horoscope endpoint", "FAIL")

def test_match_service():
    print_header("Match/Compatibility Service")
    
    # Test info endpoint
    result = test_endpoint("GET", "/api/v1/match", service_name="match")
    if result["success"]:
        print_test("Match info endpoint", "PASS")
    else:
        print_test("Match info endpoint", "FAIL")
    
    # Test compatibility calculation
    match_data = {
        "user": {
            "name": "Alice",
            "birth_date": "1990-05-15",
            "birth_time": "14:30",
            "timezone": "America/New_York",
            "latitude": 40.7128,
            "longitude": -74.0060
        },
        "partner": {
            "name": "Bob",
            "birth_date": "1988-08-22",
            "birth_time": "09:15",
            "timezone": "America/Los_Angeles",
            "latitude": 34.0522,
            "longitude": -118.2437
        }
    }
    
    result = test_endpoint("POST", "/api/v1/match", data=match_data, service_name="match")
    
    if result["success"]:
        print_test("Compatibility calculation", "PASS")
        resp = result["response"]
        if all(key in resp for key in ["overallScore", "vedicScore", "chineseScore"]):
            print_test("Compatibility scores", "PASS", 
                      f"Overall: {resp['overallScore']}, Vedic: {resp['vedicScore']}, Chinese: {resp['chineseScore']}")
        else:
            print_test("Compatibility scores", "WARN", "Missing some scores")
    else:
        print_test("Compatibility calculation", "FAIL")

def test_chart_service():
    print_header("Chart Generation Service")
    
    # Test info endpoint
    result = test_endpoint("GET", "/api/v1/chart", service_name="chart")
    if result["success"]:
        print_test("Chart info endpoint", "PASS")
    else:
        print_test("Chart info endpoint", "FAIL")
    
    # Test chart generation
    chart_data = {
        "chartType": "natal",
        "systems": ["western", "vedic"],
        "birthData": {
            "date": "1990-05-15",
            "time": "14:30",
            "timezone": "America/New_York",
            "latitude": 40.7128,
            "longitude": -74.0060
        }
    }
    
    result = test_endpoint("POST", "/api/v1/chart/generate", data=chart_data, service_name="chart")
    
    if result["success"]:
        print_test("Chart generation", "PASS")
        resp = result["response"]
        if "chartId" in resp and "charts" in resp:
            print_test("Chart data structure", "PASS", f"Chart ID: {resp['chartId']}")
        else:
            print_test("Chart data structure", "WARN", "Missing expected fields")
    else:
        print_test("Chart generation", "FAIL")

def test_reports_service():
    print_header("Reports Service")
    
    # Test info endpoint
    result = test_endpoint("GET", "/api/v1/reports", service_name="reports")
    if result["success"]:
        print_test("Reports info endpoint", "PASS")
    else:
        print_test("Reports info endpoint", "FAIL")
    
    # Test report generation
    report_data = {
        "reportType": "natal",
        "userId": "test-user-123",
        "birthData": {
            "date": "1990-05-15",
            "time": "14:30",
            "timezone": "America/New_York",
            "latitude": 40.7128,
            "longitude": -74.0060
        }
    }
    
    result = test_endpoint("POST", "/api/v1/reports/full", data=report_data, service_name="reports")
    
    if result["success"]:
        print_test("Report generation", "PASS")
        resp = result["response"]
        if all(key in resp for key in ["reportId", "title", "summary", "keyInsights"]):
            print_test("Report structure", "PASS", f"Report ID: {resp['reportId']}")
        else:
            print_test("Report structure", "WARN", "Missing expected fields")
    else:
        print_test("Report generation", "FAIL")

def test_ephemeris_service():
    print_header("Ephemeris Service")
    
    # Test info endpoint
    result = test_endpoint("GET", "/api/v1/ephemeris", service_name="ephemeris")
    if result["success"]:
        print_test("Ephemeris info endpoint", "PASS")
    else:
        print_test("Ephemeris info endpoint", "FAIL")
    
    # Test current positions
    result = test_endpoint("GET", "/api/v1/ephemeris/current?lat=40.7128&lon=-74.0060", service_name="ephemeris")
    
    if result["success"]:
        print_test("Current planetary positions", "PASS")
        resp = result["response"]
        if "planets" in resp and len(resp["planets"]) > 0:
            print_test("Planetary data", "PASS", f"Found {len(resp['planets'])} planets")
        else:
            print_test("Planetary data", "WARN", "No planetary data")
    else:
        print_test("Current planetary positions", "FAIL")

def test_content_service():
    print_header("Content Management Service")
    
    # Test info endpoint
    result = test_endpoint("GET", "/api/v1/content", service_name="content")
    if result["success"]:
        print_test("Content info endpoint", "PASS")
    else:
        print_test("Content info endpoint", "FAIL")
    
    # Test content management
    result = test_endpoint("GET", "/api/v1/content/management", service_name="content")
    
    if result["success"]:
        print_test("Content management data", "PASS")
        resp = result["response"]
        if "quick_questions" in resp and "insights" in resp:
            print_test("Content structure", "PASS", 
                      f"Questions: {len(resp['quick_questions'])}, Insights: {len(resp['insights'])}")
        else:
            print_test("Content structure", "WARN", "Missing expected content")
    else:
        print_test("Content management data", "FAIL")

def generate_report():
    """Generate comprehensive test report"""
    print_header("Generating Test Report")
    
    # Calculate statistics
    total = test_results["test_run_info"]["total_tests"]
    passed = test_results["test_run_info"]["passed"]
    failed = test_results["test_run_info"]["failed"]
    warnings = test_results["test_run_info"]["warnings"]
    
    test_results["summary"] = {
        "success_rate": (passed / total * 100) if total > 0 else 0,
        "services_tested": len(test_results["services"]),
        "total_endpoints": sum(len(s["endpoints"]) for s in test_results["services"].values()),
        "average_response_time": 0,
        "recommendations": []
    }
    
    # Calculate average response time
    total_time = 0
    count = 0
    for service in test_results["services"].values():
        for endpoint in service["endpoints"]:
            if "response_time" in endpoint:
                total_time += endpoint["response_time"]
                count += 1
    
    if count > 0:
        test_results["summary"]["average_response_time"] = total_time / count
    
    # Add recommendations
    if test_results["summary"]["success_rate"] < 100:
        test_results["summary"]["recommendations"].append("Fix failing endpoints before deployment")
    
    if warnings > 0:
        test_results["summary"]["recommendations"].append("Review warnings for potential issues")
    
    # Generate JSON report
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    json_report_path = os.path.join(REPORT_DIR, f"test_report_{timestamp}.json")
    with open(json_report_path, 'w') as f:
        json.dump(test_results, f, indent=2)
    
    print_test("JSON report generated", "PASS", json_report_path)
    
    # Generate Markdown report
    md_report_path = os.path.join(REPORT_DIR, f"test_report_{timestamp}.md")
    generate_markdown_report(md_report_path)
    print_test("Markdown report generated", "PASS", md_report_path)
    
    # Generate HTML report
    html_report_path = os.path.join(REPORT_DIR, f"test_report_{timestamp}.html")
    generate_html_report(html_report_path)
    print_test("HTML report generated", "PASS", html_report_path)
    
    # Print summary
    print(f"\n{Colors.BOLD}Test Summary:{Colors.END}")
    print(f"  Total Tests: {total}")
    print(f"  {Colors.GREEN}Passed: {passed}{Colors.END}")
    print(f"  {Colors.RED}Failed: {failed}{Colors.END}")
    print(f"  {Colors.YELLOW}Warnings: {warnings}{Colors.END}")
    print(f"  Success Rate: {test_results['summary']['success_rate']:.1f}%")
    print(f"  Average Response Time: {test_results['summary']['average_response_time']:.3f}s")

def generate_markdown_report(filepath):
    """Generate Markdown formatted report"""
    with open(filepath, 'w') as f:
        f.write("# AstroNova Backend API Test Report\n\n")
        f.write(f"**Generated:** {test_results['test_run_info']['timestamp']}\n\n")
        f.write(f"**Base URL:** {test_results['test_run_info']['base_url']}\n\n")
        
        # Summary
        f.write("## Summary\n\n")
        f.write(f"- **Total Tests:** {test_results['test_run_info']['total_tests']}\n")
        f.write(f"- **Passed:** {test_results['test_run_info']['passed']}\n")
        f.write(f"- **Failed:** {test_results['test_run_info']['failed']}\n")
        f.write(f"- **Warnings:** {test_results['test_run_info']['warnings']}\n")
        f.write(f"- **Success Rate:** {test_results['summary']['success_rate']:.1f}%\n")
        f.write(f"- **Average Response Time:** {test_results['summary']['average_response_time']:.3f}s\n\n")
        
        # Services
        f.write("## Services Tested\n\n")
        for service_name, service_data in test_results["services"].items():
            f.write(f"### {service_name.title()} Service\n\n")
            
            # Create table for endpoints
            f.write("| Endpoint | Method | Status | Response Time | Result |\n")
            f.write("|----------|--------|--------|---------------|--------|\n")
            
            for endpoint in service_data["endpoints"]:
                status = endpoint.get("status_code", "N/A")
                time_str = f"{endpoint.get('response_time', 0):.3f}s" if endpoint.get('response_time') else "N/A"
                result = "✅ Pass" if endpoint.get("success") else "❌ Fail"
                
                f.write(f"| {endpoint['endpoint']} | {endpoint['method']} | {status} | {time_str} | {result} |\n")
            
            f.write("\n")
        
        # Recommendations
        if test_results["summary"]["recommendations"]:
            f.write("## Recommendations\n\n")
            for rec in test_results["summary"]["recommendations"]:
                f.write(f"- {rec}\n")
            f.write("\n")
        
        # Sample Responses
        f.write("## Sample Responses\n\n")
        for service_name, service_data in test_results["services"].items():
            for endpoint in service_data["endpoints"]:
                if endpoint.get("success") and endpoint.get("response"):
                    f.write(f"### {endpoint['method']} {endpoint['endpoint']}\n\n")
                    f.write("```json\n")
                    f.write(json.dumps(endpoint["response"], indent=2))
                    f.write("\n```\n\n")

def generate_html_report(filepath):
    """Generate HTML formatted report"""
    html_content = f"""<!DOCTYPE html>
<html>
<head>
    <title>AstroNova Backend API Test Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }}
        .container {{ max-width: 1200px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
        h1 {{ color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }}
        h2 {{ color: #555; margin-top: 30px; }}
        .summary {{ background-color: #f0f0f0; padding: 15px; border-radius: 5px; margin: 20px 0; }}
        .pass {{ color: #4CAF50; font-weight: bold; }}
        .fail {{ color: #f44336; font-weight: bold; }}
        .warn {{ color: #ff9800; font-weight: bold; }}
        table {{ border-collapse: collapse; width: 100%; margin: 20px 0; }}
        th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
        th {{ background-color: #4CAF50; color: white; }}
        tr:nth-child(even) {{ background-color: #f2f2f2; }}
        .code {{ background-color: #f5f5f5; padding: 10px; border-radius: 4px; overflow-x: auto; }}
        pre {{ margin: 0; }}
        .metric {{ display: inline-block; margin: 10px 20px 10px 0; }}
        .metric-value {{ font-size: 24px; font-weight: bold; }}
        .metric-label {{ color: #666; font-size: 14px; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>AstroNova Backend API Test Report</h1>
        <p><strong>Generated:</strong> {test_results['test_run_info']['timestamp']}</p>
        <p><strong>Base URL:</strong> {test_results['test_run_info']['base_url']}</p>
        
        <div class="summary">
            <h2>Summary</h2>
            <div class="metric">
                <div class="metric-value">{test_results['test_run_info']['total_tests']}</div>
                <div class="metric-label">Total Tests</div>
            </div>
            <div class="metric">
                <div class="metric-value pass">{test_results['test_run_info']['passed']}</div>
                <div class="metric-label">Passed</div>
            </div>
            <div class="metric">
                <div class="metric-value fail">{test_results['test_run_info']['failed']}</div>
                <div class="metric-label">Failed</div>
            </div>
            <div class="metric">
                <div class="metric-value warn">{test_results['test_run_info']['warnings']}</div>
                <div class="metric-label">Warnings</div>
            </div>
            <div class="metric">
                <div class="metric-value">{test_results['summary']['success_rate']:.1f}%</div>
                <div class="metric-label">Success Rate</div>
            </div>
            <div class="metric">
                <div class="metric-value">{test_results['summary']['average_response_time']:.3f}s</div>
                <div class="metric-label">Avg Response Time</div>
            </div>
        </div>
"""
    
    # Add service details
    for service_name, service_data in test_results["services"].items():
        html_content += f"""
        <h2>{service_name.title()} Service</h2>
        <table>
            <tr>
                <th>Endpoint</th>
                <th>Method</th>
                <th>Status</th>
                <th>Response Time</th>
                <th>Result</th>
            </tr>
"""
        for endpoint in service_data["endpoints"]:
            status = endpoint.get("status_code", "N/A")
            time_str = f"{endpoint.get('response_time', 0):.3f}s" if endpoint.get('response_time') else "N/A"
            result = '<span class="pass">✅ Pass</span>' if endpoint.get("success") else '<span class="fail">❌ Fail</span>'
            
            html_content += f"""
            <tr>
                <td>{endpoint['endpoint']}</td>
                <td>{endpoint['method']}</td>
                <td>{status}</td>
                <td>{time_str}</td>
                <td>{result}</td>
            </tr>
"""
        html_content += "</table>"
    
    # Add recommendations
    if test_results["summary"]["recommendations"]:
        html_content += "<h2>Recommendations</h2><ul>"
        for rec in test_results["summary"]["recommendations"]:
            html_content += f"<li>{rec}</li>"
        html_content += "</ul>"
    
    html_content += """
    </div>
</body>
</html>
"""
    
    with open(filepath, 'w') as f:
        f.write(html_content)

def main():
    print_header("AstroNova Backend API Test Suite")
    print(f"Testing against: {BASE_URL}")
    print(f"Starting at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    # Start test server (optional - comment out if server is already running)
    server_process = None
    try:
        # Check if server is already running
        try:
            response = requests.get(f"{BASE_URL}/health", timeout=2)
            print("Server is already running")
        except:
            print("Starting test server...")
            server_process = subprocess.Popen(
                [sys.executable, "test_all_endpoints.py"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            time.sleep(3)  # Wait for server to start
    
        # Run all tests
        test_health_check()
        token = test_auth_service()
        test_chat_service()
        test_horoscope_service()
        test_match_service()
        test_chart_service()
        test_reports_service()
        test_ephemeris_service()
        test_content_service()
        
        # Generate reports
        generate_report()
        
    finally:
        # Clean up server process if we started it
        if server_process:
            print("\nStopping test server...")
            server_process.terminate()
            server_process.wait()

if __name__ == "__main__":
    main()