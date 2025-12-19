# CI/CD Quick Reference

Quick reference for common CI/CD commands and workflows.

## Setup

```bash
# Initial setup
./scripts/setup-ci.sh

# Activate virtual environment
source .venv/bin/activate

# Install pre-commit hooks
pre-commit install
```

## Testing

### Python

```bash
# Run all tests
cd server && pytest tests/ -v

# Run with coverage
pytest tests/ -v --cov=. --cov-report=html

# Run specific test file
pytest tests/test_api_integration.py -v

# Run specific test class
pytest tests/test_api_integration.py::TestHoroscopeEndpoints -v

# Run specific test function
pytest tests/test_api_integration.py::TestHoroscopeEndpoints::test_horoscope_all_signs -v

# Run tests matching pattern
pytest tests/ -v -k "horoscope"

# Run with coverage threshold check
pytest tests/ -v --cov=. --cov-fail-under=80

# Run benchmarks only
pytest tests/ --benchmark-only

# Run with verbose output
pytest tests/ -vv --tb=long

# Stop on first failure
pytest tests/ -x

# Run in parallel (if pytest-xdist installed)
pytest tests/ -n auto
```

### iOS

```bash
# Build
cd client
xcodebuild build \
  -project astronova.xcodeproj \
  -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Test
xcodebuild test \
  -project astronova.xcodeproj \
  -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean build
xcodebuild clean build \
  -project astronova.xcodeproj \
  -scheme AstronovaApp
```

## Code Quality

### Formatting

```bash
# Format Python code
cd server
black .

# Check formatting without changing
black --check .

# Sort imports
isort .

# Check import sorting
isort --check .
```

### Linting

```bash
# Python linting
cd server
flake8 .

# With specific rules
flake8 . --select=E9,F63,F7,F82

# Swift linting
cd client
swiftlint lint

# Auto-fix Swift issues
swiftlint --fix
```

### Type Checking

```bash
# Python type checking
cd server
mypy . --ignore-missing-imports
```

## Security

```bash
# Security scan with Bandit
cd server
bandit -r . -x ./tests

# Dependency security check
safety check

# Check for secrets
detect-secrets scan

# Update secrets baseline
detect-secrets scan > .secrets.baseline
```

## Coverage

```bash
# Generate HTML coverage report
cd server
pytest tests/ -v --cov=. --cov-report=html
open htmlcov/index.html

# Generate terminal coverage report
pytest tests/ -v --cov=. --cov-report=term-missing

# Generate XML coverage report (for Codecov)
pytest tests/ -v --cov=. --cov-report=xml

# Check coverage percentage
coverage report

# Fail if below threshold
coverage report --fail-under=80
```

## Pre-commit

```bash
# Run all pre-commit hooks
pre-commit run --all-files

# Run specific hook
pre-commit run black --all-files
pre-commit run flake8 --all-files

# Update hooks to latest versions
pre-commit autoupdate

# Skip hooks (not recommended)
git commit --no-verify

# Uninstall hooks
pre-commit uninstall
```

## Git Workflow

```bash
# Create feature branch
git checkout -b feature/your-feature

# Make changes and commit (hooks run automatically)
git add .
git commit -m "feat: add new feature"

# Push to remote
git push origin feature/your-feature

# Create PR on GitHub
# CI will run automatically
```

## Deployment

```bash
# Deploy to staging (push to main)
git checkout main
git merge feature/your-feature
git push origin main

# Deploy to production (create tag)
git tag v1.0.0
git push origin v1.0.0

# View tags
git tag -l

# Delete tag locally
git tag -d v1.0.0

# Delete tag remotely
git push origin :refs/tags/v1.0.0
```

## CI Debugging

```bash
# Run tests with verbose output
pytest tests/ -vv --tb=long

# Run single test with maximum detail
pytest tests/test_api_integration.py::test_function -vv -s --tb=long

# Show print statements
pytest tests/ -s

# Show local variables on failure
pytest tests/ -l

# Use debugger on failure
pytest tests/ --pdb
```

## Performance

```bash
# Run benchmarks
cd server
pytest tests/ --benchmark-only

# Compare benchmarks
pytest tests/ --benchmark-compare

# Save benchmark results
pytest tests/ --benchmark-save=baseline

# Profile memory usage
pytest tests/ --memprof
```

## Environment

```bash
# Create virtual environment
python3 -m venv .venv

# Activate virtual environment
source .venv/bin/activate  # macOS/Linux
.venv\Scripts\activate     # Windows

# Deactivate virtual environment
deactivate

# Install dependencies
pip install -r server/requirements.txt
pip install -r server/tests/requirements-test.txt

# Update dependencies
pip list --outdated
pip install --upgrade <package>

# Freeze dependencies
pip freeze > requirements.txt
```

## GitHub Actions

```bash
# View workflows
gh workflow list

# View runs
gh run list

# View specific run
gh run view <run-id>

# Watch run in real-time
gh run watch

# Re-run failed jobs
gh run rerun <run-id>

# Manually trigger workflow
gh workflow run test.yml
gh workflow run deploy.yml -f environment=staging
```

## Health Checks

```bash
# Check local server
curl http://localhost:8080/api/v1/health

# Check staging
curl https://astronova-staging.onrender.com/api/v1/health

# Check production
curl https://astronova.onrender.com/api/v1/health

# Check specific endpoint
curl "http://localhost:8080/api/v1/horoscope?sign=aries&type=daily"
```

## Troubleshooting

```bash
# Clear Python cache
find . -type d -name __pycache__ -exec rm -rf {} +
find . -type f -name "*.pyc" -delete

# Clear pytest cache
rm -rf .pytest_cache

# Clear coverage data
rm -f .coverage
rm -rf htmlcov

# Reset virtual environment
deactivate
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
pip install -r server/requirements.txt

# Clear Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## Quick CI Status Check

```bash
# Check if code is ready for CI
cd server

# 1. Tests pass
pytest tests/ -v --cov=. --cov-fail-under=80 || echo "❌ Tests failed"

# 2. Linting passes
flake8 . --select=E9,F63,F7,F82 || echo "❌ Linting failed"

# 3. Formatting correct
black --check . || echo "❌ Format failed"

# 4. Security checks pass
bandit -r . -x ./tests || echo "⚠️  Security issues found"

# All good? Push!
echo "✅ All checks passed! Safe to push."
```

## Useful Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Astronova aliases
alias astro-test='cd ~/Projects/astronova/server && pytest tests/ -v'
alias astro-cov='cd ~/Projects/astronova/server && pytest tests/ -v --cov=. --cov-report=html && open htmlcov/index.html'
alias astro-lint='cd ~/Projects/astronova/server && flake8 . && black --check . && isort --check .'
alias astro-format='cd ~/Projects/astronova/server && black . && isort .'
alias astro-secure='cd ~/Projects/astronova/server && bandit -r . -x ./tests && safety check'
alias astro-ci='cd ~/Projects/astronova && pre-commit run --all-files'
alias astro-setup='cd ~/Projects/astronova && ./scripts/setup-ci.sh'
```

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [pytest Documentation](https://docs.pytest.org/)
- [Black Documentation](https://black.readthedocs.io/)
- [flake8 Documentation](https://flake8.pycqa.org/)
- [pre-commit Documentation](https://pre-commit.com/)
- [Codecov Documentation](https://docs.codecov.com/)