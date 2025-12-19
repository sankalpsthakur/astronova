# Contributing to Astronova

Thank you for your interest in contributing to Astronova! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

1. [Development Setup](#development-setup)
2. [Code Quality](#code-quality)
3. [Testing](#testing)
4. [CI/CD Pipeline](#cicd-pipeline)
5. [Pull Request Process](#pull-request-process)
6. [Coding Standards](#coding-standards)

## Development Setup

### Prerequisites

- Python 3.9+ for backend development
- Xcode 15+ for iOS development
- Git for version control

### Backend Setup

```bash
cd server
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
pip install -r tests/requirements-test.txt
```

### iOS Setup

```bash
cd client
open astronova.xcodeproj
```

### Pre-commit Hooks

Install pre-commit hooks to ensure code quality before committing:

```bash
pip install pre-commit
pre-commit install
```

This will automatically run the following checks before each commit:
- Code formatting (Black, isort)
- Linting (flake8)
- Security checks (Bandit, detect-secrets)
- File validation

To run checks manually:
```bash
pre-commit run --all-files
```

## Code Quality

### Python

We use the following tools for Python code quality:

- **Black**: Code formatting (line length: 127)
- **isort**: Import sorting
- **flake8**: Linting and style checking
- **mypy**: Type checking (optional)
- **Bandit**: Security vulnerability scanning
- **Safety**: Dependency security checking

Run all checks:
```bash
cd server
black . --check
isort . --check
flake8 .
bandit -r . -x ./tests
safety check
```

### Swift

We use the following tools for Swift code quality:

- **SwiftLint**: Linting and style checking
- **SwiftFormat**: Code formatting (optional)

Install SwiftLint:
```bash
brew install swiftlint
```

Run SwiftLint:
```bash
cd client
swiftlint lint
```

## Testing

### Python Tests

Run the full test suite:
```bash
cd server
pytest tests/ -v
```

Run with coverage:
```bash
pytest tests/ -v --cov=. --cov-report=html
```

Run specific test files:
```bash
pytest tests/test_api_integration.py -v
```

Run specific test classes or functions:
```bash
pytest tests/test_api_integration.py::TestHoroscopeEndpoints::test_horoscope_all_signs -v
```

### iOS Tests

Run tests via Xcode or command line:
```bash
cd client
xcodebuild test \
  -project astronova.xcodeproj \
  -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Coverage Requirements

- Python backend: Minimum 80% code coverage
- New code should include appropriate tests
- Integration tests should cover major API endpoints
- Unit tests should cover business logic and edge cases

## CI/CD Pipeline

### Continuous Integration

The project uses GitHub Actions for CI. The following workflows run automatically:

1. **Test Suite** (`.github/workflows/test.yml`)
   - Triggers: Push to main/dev, Pull requests
   - Runs on Python 3.9, 3.10, 3.11, 3.12
   - Executes all tests with coverage
   - Performs security scanning
   - Uploads coverage to Codecov

2. **iOS Build** (`.github/workflows/ios.yml`)
   - Triggers: Changes to client/** directory
   - Builds iOS app
   - Runs Swift tests
   - Checks for compiler warnings
   - Performs Swift linting

### Continuous Deployment

Deployment is automatic based on branch/tag:

- **Staging**: Automatic deployment on push to `main` branch
- **Production**: Automatic deployment on version tags (`v*.*.*`)

### Local CI Simulation

You can simulate CI checks locally:

```bash
# Python tests
cd server
pip install -r tests/requirements-test.txt
pytest tests/ -v --cov=. --cov-report=term-missing --cov-fail-under=80

# Python linting
flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
black --check .
isort --check .

# Security checks
bandit -r . -x ./tests
safety check

# iOS build
cd client
xcodebuild clean build -project astronova.xcodeproj -scheme AstronovaApp
```

## Pull Request Process

1. **Fork and Clone**
   ```bash
   git clone https://github.com/yourusername/astronova.git
   cd astronova
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

3. **Make Changes**
   - Write clean, well-documented code
   - Follow coding standards
   - Add tests for new functionality
   - Update documentation as needed

4. **Run Tests Locally**
   ```bash
   # Python
   cd server && pytest tests/ -v --cov=.

   # iOS
   cd client && xcodebuild test -project astronova.xcodeproj -scheme AstronovaApp
   ```

5. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   # Pre-commit hooks will run automatically
   ```

6. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then create a Pull Request on GitHub.

7. **PR Checklist**
   - [ ] Tests pass locally
   - [ ] Code coverage is maintained (≥80%)
   - [ ] Code is formatted and linted
   - [ ] Documentation is updated
   - [ ] Commit messages follow conventions
   - [ ] PR description explains changes clearly

### Commit Message Convention

We follow conventional commits:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

Example:
```
feat: add planetary strength calculation

- Implement Shadbala calculation
- Add unit tests for all planets
- Update API documentation
```

## Coding Standards

### Python

- Follow PEP 8 style guide
- Use type hints where appropriate
- Write docstrings for public functions/classes
- Keep functions focused and single-purpose
- Maximum line length: 127 characters
- Use meaningful variable names

Example:
```python
def calculate_planetary_position(
    date: str,
    time: str,
    latitude: float,
    longitude: float
) -> dict:
    """
    Calculate planetary positions for a given date and location.

    Args:
        date: Date in YYYY-MM-DD format
        time: Time in HH:MM format
        latitude: Latitude in decimal degrees
        longitude: Longitude in decimal degrees

    Returns:
        Dictionary with planetary positions
    """
    # Implementation
    pass
```

### Swift

- Follow Swift API Design Guidelines
- Use meaningful names for types and methods
- Prefer value types (struct) over reference types (class)
- Use `private` and `fileprivate` appropriately
- Document public APIs with comments

Example:
```swift
/// Calculates the planetary position for a given date
/// - Parameters:
///   - date: The date for calculation
///   - location: Geographic location
/// - Returns: Planetary position data
func calculatePosition(for date: Date, at location: Location) -> Position {
    // Implementation
}
```

## Security

- Never commit sensitive data (API keys, passwords, tokens)
- Use environment variables for secrets
- Run `detect-secrets` before committing
- Report security vulnerabilities privately

## Questions?

If you have questions or need help:

1. Check existing issues and discussions
2. Create a new issue with the "question" label
3. Join our community discussions

## License

By contributing, you agree that your contributions will be licensed under the project's MIT License.