#!/usr/bin/env python3
"""
🌟 Astronova Backend Setup Validation Script

This script validates that the Astronova backend environment is properly configured
and all required dependencies and services are available.
"""

import os
import sys
import json
import importlib
import subprocess
import socket
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# Colors for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    NC = '\033[0m'  # No Color

# Emoji helpers
EMOJIS = {
    'rocket': '🚀',
    'star': '⭐',
    'check': '✅',
    'cross': '❌',
    'warning': '⚠️',
    'info': 'ℹ️',
    'gear': '⚙️',
    'key': '🔑',
    'network': '🌐',
    'database': '🗄️',
    'file': '📁',
    'python': '🐍'
}

class ValidationResult:
    def __init__(self, name: str, passed: bool, message: str, details: Optional[str] = None):
        self.name = name
        self.passed = passed
        self.message = message
        self.details = details

class SetupValidator:
    def __init__(self):
        self.results: List[ValidationResult] = []
        self.critical_failures = 0
        
    def print_header(self):
        """Print validation header"""
        print(f"{Colors.PURPLE}{EMOJIS['rocket']} Astronova Backend Setup Validation{Colors.NC}")
        print(f"{Colors.CYAN}Validating your cosmic development environment...{Colors.NC}")
        print()

    def print_section(self, title: str):
        """Print section header"""
        print(f"\n{Colors.BLUE}{EMOJIS['star']} {title}{Colors.NC}")
        print("-" * (len(title) + 4))

    def add_result(self, result: ValidationResult, critical: bool = False):
        """Add validation result"""
        self.results.append(result)
        
        # Print result immediately
        status_icon = EMOJIS['check'] if result.passed else EMOJIS['cross']
        status_color = Colors.GREEN if result.passed else Colors.RED
        
        print(f"{status_color}{status_icon} {result.message}{Colors.NC}")
        
        if result.details:
            print(f"   {Colors.CYAN}{result.details}{Colors.NC}")
            
        if not result.passed and critical:
            self.critical_failures += 1

    def validate_python_environment(self):
        """Validate Python and virtual environment setup"""
        self.print_section("Python Environment")
        
        # Check Python version
        python_version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
        is_good_version = sys.version_info >= (3, 11)
        
        self.add_result(ValidationResult(
            "python_version",
            is_good_version,
            f"Python version: {python_version}",
            "Python 3.11+ recommended" if not is_good_version else None
        ))
        
        # Check if in virtual environment
        in_venv = hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix)
        
        self.add_result(ValidationResult(
            "virtual_env",
            in_venv,
            "Virtual environment active" if in_venv else "Not in virtual environment",
            "Run 'source astronova-env/bin/activate' first" if not in_venv else None
        ), critical=True)

    def validate_dependencies(self):
        """Validate required Python packages"""
        self.print_section("Python Dependencies")
        
        required_packages = [
            ('flask', 'Flask web framework'),
            ('flask_cors', 'CORS support'),
            ('flask_limiter', 'Rate limiting'),
            ('redis', 'Redis client'),
            ('requests', 'HTTP requests'),
            ('python_dotenv', 'Environment variables'),
            ('swisseph', 'Swiss Ephemeris'),
            ('anthropic', 'Anthropic AI client'),
            ('pydantic', 'Data validation'),
            ('pytest', 'Testing framework')
        ]
        
        for package, description in required_packages:
            try:
                # Special handling for python-dotenv package name
                module_name = 'dotenv' if package == 'python_dotenv' else package
                importlib.import_module(module_name)
                self.add_result(ValidationResult(
                    f"package_{package}",
                    True,
                    f"{description} ({package})"
                ))
            except ImportError:
                self.add_result(ValidationResult(
                    f"package_{package}",
                    False,
                    f"Missing: {description} ({package})",
                    f"Install with: pip install {package}"
                ), critical=True)

    def validate_environment_variables(self):
        """Validate environment variables and configuration"""
        self.print_section("Environment Variables")
        
        # Load .env file if exists
        env_file = Path('.env')
        if env_file.exists():
            try:
                from dotenv import load_dotenv
                load_dotenv()
                self.add_result(ValidationResult(
                    "env_file",
                    True,
                    "Environment file (.env) loaded"
                ))
            except ImportError:
                self.add_result(ValidationResult(
                    "env_file",
                    False,
                    "python-dotenv not installed",
                    "Install with: pip install python-dotenv"
                ))
        else:
            self.add_result(ValidationResult(
                "env_file",
                False,
                ".env file not found",
                "Create .env file with required configuration"
            ), critical=True)
        
        # Check required environment variables
        required_vars = [
            ('SECRET_KEY', 'Flask secret key', True),
            ('JWT_SECRET_KEY', 'JWT secret key', True),
            ('ANTHROPIC_API_KEY', 'Anthropic AI API key', True),
            ('GOOGLE_PLACES_API_KEY', 'Google Places API key', False),
            ('REDIS_URL', 'Redis connection URL', False),
            ('FLASK_ENV', 'Flask environment', False)
        ]
        
        for var_name, description, required in required_vars:
            value = os.getenv(var_name)
            has_value = bool(value and value.strip())
            
            if required:
                self.add_result(ValidationResult(
                    f"env_{var_name.lower()}",
                    has_value,
                    f"{description}: {'Set' if has_value else 'Missing'}",
                    f"Set {var_name} in .env file" if not has_value else None
                ), critical=required)
            else:
                self.add_result(ValidationResult(
                    f"env_{var_name.lower()}",
                    True,  # Optional variables don't fail validation
                    f"{description}: {'Set' if has_value else 'Not set (optional)'}",
                    None
                ))

    def validate_redis_connection(self):
        """Validate Redis connection"""
        self.print_section("Redis Connection")
        
        try:
            import redis
            redis_url = os.getenv('REDIS_URL', 'redis://localhost:6379/0')
            
            # Try to connect to Redis
            r = redis.from_url(redis_url)
            r.ping()
            
            # Test basic operations
            r.set('astronova_test', 'validation')
            test_value = r.get('astronova_test')
            r.delete('astronova_test')
            
            self.add_result(ValidationResult(
                "redis_connection",
                True,
                f"Redis connection successful ({redis_url})"
            ))
            
        except ImportError:
            self.add_result(ValidationResult(
                "redis_connection",
                False,
                "Redis package not installed",
                "Install with: pip install redis"
            ), critical=True)
        except Exception as e:
            self.add_result(ValidationResult(
                "redis_connection",
                False,
                "Redis connection failed",
                f"Error: {str(e)}. Ensure Redis server is running."
            ), critical=True)

    def validate_network_ports(self):
        """Validate network port availability"""
        self.print_section("Network Configuration")
        
        ports_to_check = [
            (8080, "Flask application port"),
            (6379, "Redis default port")
        ]
        
        for port, description in ports_to_check:
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(1)
                result = sock.connect_ex(('localhost', port))
                sock.close()
                
                if result == 0:
                    # Port is in use
                    if port == 6379:  # Redis port - good if in use
                        self.add_result(ValidationResult(
                            f"port_{port}",
                            True,
                            f"{description} (:{port}) - Service running"
                        ))
                    else:  # Application port - should be free
                        self.add_result(ValidationResult(
                            f"port_{port}",
                            False,
                            f"{description} (:{port}) - Port in use",
                            "Stop other services or use different port"
                        ))
                else:
                    # Port is free
                    if port == 8080:  # Application port - good if free
                        self.add_result(ValidationResult(
                            f"port_{port}",
                            True,
                            f"{description} (:{port}) - Port available"
                        ))
                    else:  # Redis port - concerning if not in use
                        self.add_result(ValidationResult(
                            f"port_{port}",
                            False,
                            f"{description} (:{port}) - Service not running",
                            "Start Redis server: redis-server"
                        ))
                        
            except Exception as e:
                self.add_result(ValidationResult(
                    f"port_{port}",
                    False,
                    f"Could not check {description} (:{port})",
                    f"Error: {str(e)}"
                ))

    def validate_file_structure(self):
        """Validate project file structure"""
        self.print_section("File Structure")
        
        required_files = [
            ('app.py', 'Flask application entry point'),
            ('config.py', 'Application configuration'),
            ('requirements.txt', 'Python dependencies'),
            ('routes/__init__.py', 'Routes package'),
            ('services/__init__.py', 'Services package'),
            ('models/__init__.py', 'Models package')
        ]
        
        for file_path, description in required_files:
            path = Path(file_path)
            exists = path.exists()
            
            self.add_result(ValidationResult(
                f"file_{file_path.replace('/', '_').replace('.', '_')}",
                exists,
                f"{description}: {'Found' if exists else 'Missing'}",
                f"Create {file_path}" if not exists else None
            ), critical=file_path in ['app.py', 'config.py'])

    def validate_api_keys(self):
        """Validate API key formats"""
        self.print_section("API Key Validation")
        
        # Anthropic API Key
        anthropic_key = os.getenv('ANTHROPIC_API_KEY', '')
        if anthropic_key:
            valid_anthropic = anthropic_key.startswith('sk-ant-api03-')
            self.add_result(ValidationResult(
                "anthropic_key_format",
                valid_anthropic,
                f"Anthropic API key format: {'Valid' if valid_anthropic else 'Invalid'}",
                "Should start with 'sk-ant-api03-'" if not valid_anthropic else None
            ))
        
        # Google Places API Key
        google_key = os.getenv('GOOGLE_PLACES_API_KEY', '')
        if google_key:
            # Basic format check (Google API keys are typically 39 characters)
            valid_google = len(google_key) >= 30
            self.add_result(ValidationResult(
                "google_key_format",
                valid_google,
                f"Google Places API key format: {'Valid' if valid_google else 'Invalid'}",
                "Check API key length and format" if not valid_google else None
            ))

    def validate_ephemeris_setup(self):
        """Validate Swiss Ephemeris setup"""
        self.print_section("Swiss Ephemeris")
        
        ephemeris_path = Path(os.getenv('EPHEMERIS_PATH', './ephemeris'))
        
        # Check if directory exists
        if ephemeris_path.exists():
            self.add_result(ValidationResult(
                "ephemeris_directory",
                True,
                f"Ephemeris directory found: {ephemeris_path}"
            ))
            
            # Check for ephemeris files
            ephemeris_files = list(ephemeris_path.glob('*.se1'))
            if ephemeris_files:
                self.add_result(ValidationResult(
                    "ephemeris_files",
                    True,
                    f"Ephemeris data files found: {len(ephemeris_files)} files"
                ))
            else:
                self.add_result(ValidationResult(
                    "ephemeris_files",
                    True,  # Not critical - files download on demand
                    "No ephemeris files found (will download on demand)",
                    "Files will be downloaded automatically when needed"
                ))
        else:
            self.add_result(ValidationResult(
                "ephemeris_directory",
                False,
                f"Ephemeris directory missing: {ephemeris_path}",
                f"Create directory: mkdir -p {ephemeris_path}"
            ))

    def test_flask_import(self):
        """Test Flask application import"""
        self.print_section("Flask Application")
        
        try:
            # Try to import the app
            sys.path.insert(0, '.')
            from app import create_app
            app = create_app()
            
            self.add_result(ValidationResult(
                "flask_import",
                True,
                "Flask application imports successfully"
            ))
            
            # Test app configuration
            if hasattr(app, 'config'):
                self.add_result(ValidationResult(
                    "flask_config",
                    True,
                    "Flask configuration loaded"
                ))
            
        except ImportError as e:
            self.add_result(ValidationResult(
                "flask_import",
                False,
                "Flask application import failed",
                f"Error: {str(e)}"
            ), critical=True)
        except Exception as e:
            self.add_result(ValidationResult(
                "flask_import",
                False,
                "Flask application error",
                f"Error: {str(e)}"
            ), critical=True)

    def run_comprehensive_test(self):
        """Run a comprehensive test suite"""
        self.print_section("Comprehensive Test")
        
        try:
            # Test pytest is available and can find tests
            result = subprocess.run(['python', '-m', 'pytest', '--collect-only', '-q'], 
                                  capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                test_count = len([line for line in result.stdout.split('\n') if '::' in line])
                self.add_result(ValidationResult(
                    "pytest_discovery",
                    True,
                    f"Test discovery successful: {test_count} tests found"
                ))
            else:
                self.add_result(ValidationResult(
                    "pytest_discovery",
                    False,
                    "Test discovery failed",
                    result.stderr or "No error details available"
                ))
                
        except subprocess.TimeoutExpired:
            self.add_result(ValidationResult(
                "pytest_discovery",
                False,
                "Test discovery timed out",
                "Tests may have import issues"
            ))
        except Exception as e:
            self.add_result(ValidationResult(
                "pytest_discovery",
                False,
                "Could not run test discovery",
                f"Error: {str(e)}"
            ))

    def print_summary(self):
        """Print validation summary"""
        self.print_section("Validation Summary")
        
        total_tests = len(self.results)
        passed_tests = sum(1 for r in self.results if r.passed)
        failed_tests = total_tests - passed_tests
        
        print(f"Total tests: {total_tests}")
        print(f"{Colors.GREEN}Passed: {passed_tests}{Colors.NC}")
        if failed_tests > 0:
            print(f"{Colors.RED}Failed: {failed_tests}{Colors.NC}")
        if self.critical_failures > 0:
            print(f"{Colors.RED}Critical failures: {self.critical_failures}{Colors.NC}")
        
        print()
        
        if self.critical_failures == 0:
            print(f"{Colors.GREEN}{EMOJIS['check']} All critical checks passed!{Colors.NC}")
            print(f"{Colors.CYAN}Your Astronova backend environment is ready for development!{Colors.NC}")
            
            if failed_tests > 0:
                print(f"{Colors.YELLOW}{EMOJIS['warning']} Some optional checks failed - review details above{Colors.NC}")
        else:
            print(f"{Colors.RED}{EMOJIS['cross']} Critical setup issues found!{Colors.NC}")
            print(f"{Colors.YELLOW}Please resolve critical issues before running the application.{Colors.NC}")
        
        print()
        print(f"{Colors.PURPLE}Next steps:{Colors.NC}")
        if self.critical_failures == 0:
            print(f"{Colors.CYAN}• Run 'python app.py' to start the development server{Colors.NC}")
            print(f"{Colors.CYAN}• Visit http://localhost:8080/api/v1/misc/health to test{Colors.NC}")
            print(f"{Colors.CYAN}• Run 'pytest' to execute the test suite{Colors.NC}")
        else:
            print(f"{Colors.YELLOW}• Fix critical issues listed above{Colors.NC}")
            print(f"{Colors.YELLOW}• Re-run this validation script{Colors.NC}")
        
        return self.critical_failures == 0

def main():
    """Main validation function"""
    validator = SetupValidator()
    
    validator.print_header()
    
    # Run all validations
    validator.validate_python_environment()
    validator.validate_dependencies()
    validator.validate_environment_variables()
    validator.validate_redis_connection()
    validator.validate_network_ports()
    validator.validate_file_structure()
    validator.validate_api_keys()
    validator.validate_ephemeris_setup()
    validator.test_flask_import()
    validator.run_comprehensive_test()
    
    # Print summary and return exit code
    success = validator.print_summary()
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())