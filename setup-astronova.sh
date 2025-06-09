#!/bin/bash

# 🌟 Astronova Development Environment Setup Script
# This script sets up the complete development environment for the Astronova astrology app

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emoji helpers
ROCKET="🚀"
STAR="⭐"
CHECK="✅"
CROSS="❌"
WARNING="⚠️"
INFO="ℹ️"

echo -e "${PURPLE}${ROCKET} Astronova Development Environment Setup${NC}"
echo -e "${CYAN}Setting up your cosmic development environment...${NC}"
echo ""

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}${STAR} $1${NC}"
    echo "----------------------------------------"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local result
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " result
        echo "${result:-$default}"
    else
        read -p "$prompt: " result
        echo "$result"
    fi
}

# Check prerequisites
print_section "Checking Prerequisites"

# Check Python
if command_exists python3; then
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo -e "${CHECK} Python 3 found: $PYTHON_VERSION"
    if [[ $(echo $PYTHON_VERSION | cut -d'.' -f2) -lt 11 ]]; then
        echo -e "${WARNING} Warning: Python 3.11+ recommended for best compatibility"
    fi
else
    echo -e "${CROSS} Python 3 not found. Please install Python 3.11+."
    exit 1
fi

# Check pip
if command_exists pip3; then
    echo -e "${CHECK} pip3 found"
else
    echo -e "${CROSS} pip3 not found. Please install pip."
    exit 1
fi

# Check Redis (optional)
if command_exists redis-server; then
    echo -e "${CHECK} Redis server found"
    REDIS_AVAILABLE=true
else
    echo -e "${WARNING} Redis server not found. Installing via package manager..."
    REDIS_AVAILABLE=false
fi

# Check Docker (optional)
if command_exists docker; then
    echo -e "${CHECK} Docker found"
    DOCKER_AVAILABLE=true
else
    echo -e "${INFO} Docker not found (optional for deployment)"
    DOCKER_AVAILABLE=false
fi

# Install Redis if not available
if [ "$REDIS_AVAILABLE" = false ]; then
    echo -e "\n${YELLOW}Installing Redis...${NC}"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            brew install redis
            echo -e "${CHECK} Redis installed via Homebrew"
        else
            echo -e "${CROSS} Homebrew not found. Please install Redis manually."
            echo "Visit: https://redis.io/download"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y redis-server
            echo -e "${CHECK} Redis installed via apt"
        elif command_exists yum; then
            sudo yum install -y redis
            echo -e "${CHECK} Redis installed via yum"
        else
            echo -e "${WARNING} Could not auto-install Redis. Please install manually."
        fi
    else
        echo -e "${WARNING} Unsupported OS for auto-installation. Please install Redis manually."
    fi
fi

# Setup backend environment
print_section "Setting Up Backend Environment"

cd backend/

# Create virtual environment
echo "Creating Python virtual environment..."
if [ -d "astronova-env" ]; then
    echo -e "${INFO} Virtual environment already exists"
else
    python3 -m venv astronova-env
    echo -e "${CHECK} Virtual environment created"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source astronova-env/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "Installing Python dependencies..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    echo -e "${CHECK} Dependencies installed"
else
    echo -e "${CROSS} requirements.txt not found"
    exit 1
fi

# Install development dependencies
echo "Installing development dependencies..."
pip install pytest pytest-cov pytest-asyncio python-dotenv

# Setup environment variables
print_section "Configuring Environment Variables"

if [ -f ".env" ]; then
    echo -e "${INFO} .env file already exists"
    read -p "Do you want to update it? (y/N): " UPDATE_ENV
    if [[ $UPDATE_ENV =~ ^[Yy]$ ]]; then
        SETUP_ENV=true
    else
        SETUP_ENV=false
    fi
else
    SETUP_ENV=true
fi

if [ "$SETUP_ENV" = true ]; then
    echo "Setting up environment variables..."
    
    # Generate secure keys
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    JWT_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    
    echo -e "${INFO} Generated secure keys automatically"
    
    # Prompt for API keys
    echo -e "\n${YELLOW}Please provide your API keys:${NC}"
    ANTHROPIC_API_KEY=$(prompt_with_default "Anthropic API Key" "")
    GOOGLE_PLACES_API_KEY=$(prompt_with_default "Google Places API Key" "")
    
    # Other configurations
    REDIS_URL=$(prompt_with_default "Redis URL" "redis://localhost:6379/0")
    EPHEMERIS_PATH=$(prompt_with_default "Ephemeris Path" "./ephemeris")
    FLASK_ENV=$(prompt_with_default "Flask Environment" "development")
    
    # Create .env file
    cat > .env << EOF
# Security
SECRET_KEY=$SECRET_KEY
JWT_SECRET_KEY=$JWT_SECRET_KEY

# APIs
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY
GOOGLE_PLACES_API_KEY=$GOOGLE_PLACES_API_KEY

# Infrastructure
REDIS_URL=$REDIS_URL
EPHEMERIS_PATH=$EPHEMERIS_PATH

# Environment
FLASK_ENV=$FLASK_ENV
FLASK_DEBUG=true
EOF
    
    echo -e "${CHECK} Environment variables configured"
    
    # Set permissions for .env file
    chmod 600 .env
    echo -e "${CHECK} .env file permissions secured"
fi

# Setup ephemeris directory
print_section "Setting Up Ephemeris Data"

if [ ! -d "./ephemeris" ]; then
    mkdir -p ./ephemeris
    echo -e "${CHECK} Ephemeris directory created"
    echo -e "${INFO} Swiss Ephemeris data files will be downloaded when needed"
else
    echo -e "${INFO} Ephemeris directory already exists"
fi

# Start Redis server
print_section "Starting Services"

echo "Starting Redis server..."
if command_exists redis-server; then
    # Check if Redis is already running
    if pgrep redis-server > /dev/null; then
        echo -e "${INFO} Redis server already running"
    else
        redis-server --daemonize yes
        echo -e "${CHECK} Redis server started"
    fi
else
    echo -e "${WARNING} Redis server not available. Some features may not work."
fi

# Test backend setup
print_section "Validating Setup"

echo "Running setup validation..."
if [ -f "validate_setup.py" ]; then
    python validate_setup.py
else
    echo -e "${WARNING} validate_setup.py not found. Skipping validation."
fi

# Return to project root
cd ..

# Setup iOS development (optional)
print_section "iOS Development Setup"

if command_exists xcodebuild; then
    echo -e "${CHECK} Xcode found"
    echo -e "${INFO} iOS development environment ready"
    echo -e "${INFO} Open astronova.xcodeproj in Xcode to start iOS development"
else
    echo -e "${INFO} Xcode not found. Install Xcode for iOS development."
fi

# Create helpful scripts
print_section "Creating Helper Scripts"

# Create start script
cat > start-dev.sh << 'EOF'
#!/bin/bash
# Start Astronova development environment

echo "🌟 Starting Astronova development environment..."

# Start Redis
if command -v redis-server >/dev/null 2>&1; then
    if ! pgrep redis-server > /dev/null; then
        redis-server --daemonize yes
        echo "✅ Redis server started"
    else
        echo "ℹ️ Redis server already running"
    fi
fi

# Start backend
cd backend/
source astronova-env/bin/activate
echo "🚀 Starting Flask backend on http://localhost:8080"
python app.py
EOF

chmod +x start-dev.sh

# Create stop script
cat > stop-dev.sh << 'EOF'
#!/bin/bash
# Stop Astronova development environment

echo "🛑 Stopping Astronova development environment..."

# Stop backend (if running in background)
pkill -f "python app.py" 2>/dev/null || true

# Stop Redis (optional)
# pkill redis-server 2>/dev/null || true

echo "✅ Development environment stopped"
EOF

chmod +x stop-dev.sh

echo -e "${CHECK} Helper scripts created (start-dev.sh, stop-dev.sh)"

# Final summary
print_section "Setup Complete!"

echo -e "${GREEN}${ROCKET} Astronova development environment setup complete!${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo -e "1. ${STAR} Update API keys in backend/.env if needed"
echo -e "2. ${STAR} Run './start-dev.sh' to start the development environment"
echo -e "3. ${STAR} Open astronova.xcodeproj in Xcode for iOS development"
echo -e "4. ${STAR} Visit http://localhost:8080/api/v1/misc/health to test backend"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  ./start-dev.sh     - Start development environment"
echo -e "  ./stop-dev.sh      - Stop development environment"
echo -e "  cd backend && python validate_setup.py - Validate setup"
echo ""
echo -e "${PURPLE}Happy coding! May the cosmos guide your development! ✨${NC}"