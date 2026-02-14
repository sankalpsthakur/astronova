# Astronova Development Guide

## Prerequisites

- **Python**: 3.9+ (3.11 recommended)
- **Xcode**: 15+ with iOS 17 SDK
- **Node.js**: 18+ (for pre-commit prettier)
- **Git**: 2.30+

## Initial Setup

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/astronova.git
cd astronova
```

### 2. Backend Setup
```bash
cd server

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Install test dependencies
pip install -r tests/requirements-test.txt

# Run server
python app.py  # Starts on http://0.0.0.0:8080
```

### 3. iOS Setup
```bash
cd client

# Open Xcode project
open astronova.xcodeproj

# Select scheme: AstronovaApp
# Select simulator: iPhone 15 (iOS 17+)
# Build and run (⌘R)
```

### 4. Pre-commit Hooks
```bash
# From project root
pip install pre-commit
pre-commit install

# Run manually
pre-commit run --all-files
```

## Development Workflow

### Running the Full Stack

**Terminal 1 (Backend):**
```bash
cd server
source .venv/bin/activate
FLASK_DEBUG=true python app.py
```

**Terminal 2 (iOS):**
```bash
# Open Xcode and run, or:
cd client
xcodebuild -project astronova.xcodeproj -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### Quick Start Script
```bash
./scripts/run-local.sh           # Boots backend + opens Xcode
OPEN_XCODE=0 ./scripts/run-local.sh  # Backend only
```

## Testing

### Backend Tests

```bash
cd server
source .venv/bin/activate

# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ -v --cov=. --cov-report=html
open htmlcov/index.html

# Run specific markers
pytest -m unit              # Unit tests only
pytest -m "not slow"        # Skip slow tests
pytest -m api               # API tests only
pytest -m ephemeris         # Ephemeris tests

# Run specific file
pytest tests/test_api_integration.py -v

# Run specific test
pytest tests/test_api_integration.py::TestHoroscopeEndpoints::test_horoscope_all_signs -v

# Show slowest tests
pytest --durations=10
```

### iOS Tests

```bash
cd client

# Run all tests
xcodebuild test -project astronova.xcodeproj -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Unit tests only
xcodebuild test -project astronova.xcodeproj -scheme AstronovaApp \
  -only-testing:AstronovaAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# UI tests only
xcodebuild test -project astronova.xcodeproj -scheme AstronovaApp \
  -only-testing:AstronovaAppUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Code Quality

### Python Linting
```bash
cd server

# Format check
black . --check
isort . --check

# Lint
ruff check .

# Security scan
bandit -r . -x ./tests

# Type checking (optional)
mypy .
```

### Pre-commit Hooks

Configured checks:
- **Black**: Python formatting (127 char line length)
- **isort**: Import sorting
- **Ruff**: Fast Python linting with auto-fix
- **Bandit**: Security vulnerability scanning
- **Prettier**: YAML/JSON/markdown formatting
- **Detect-secrets**: Secret detection

## Adding New Features

### Adding a New API Endpoint

1. **Create/Update Route** (`server/routes/`)
   ```python
   @blueprint.route("/new-endpoint", methods=["POST"])
   def new_endpoint():
       data = request.get_json()
       # Validate input
       # Call service
       # Return response
   ```

2. **Add Service Logic** (if needed, `server/services/`)
   ```python
   class NewService:
       def process(self, data):
           # Business logic
           return result
   ```

3. **Update OpenAPI Spec** (`server/openapi_spec.yaml`)
   ```yaml
   /api/v1/new-endpoint:
     post:
       summary: New endpoint
       requestBody: ...
       responses: ...
   ```

4. **Add Swift Method** (`client/AstronovaApp/APIServices.swift`)
   ```swift
   func callNewEndpoint(_ data: RequestType) async throws -> ResponseType {
       return try await networkClient.post("/api/v1/new-endpoint", body: data)
   }
   ```

5. **Add Response Model** (`client/AstronovaApp/APIModels.swift`)
   ```swift
   struct ResponseType: Codable {
       let field: String
   }
   ```

6. **Add Tests** (`server/tests/test_new_feature.py`)
   ```python
   def test_new_endpoint(client):
       response = client.post("/api/v1/new-endpoint", json={...})
       assert response.status_code == 200
   ```

### Adding a New SwiftUI View

1. **Create View** (`client/AstronovaApp/Features/{Feature}/`)
   ```swift
   struct NewFeatureView: View {
       @StateObject private var viewModel = NewFeatureViewModel()

       var body: some View {
           // Use CosmicColors, CosmicTypography
       }
   }
   ```

2. **Create ViewModel** (if needed)
   ```swift
   @MainActor
   class NewFeatureViewModel: ObservableObject {
       @Published var data: [Item] = []

       func loadData() async {
           // Call APIServices
       }
   }
   ```

3. **Wire Navigation** (`RootView.swift` or parent view)
   ```swift
   NavigationLink {
       NewFeatureView()
   } label: {
       Text("New Feature")
   }
   ```

4. **Add Accessibility Identifiers** (for UI testing)
   ```swift
   .accessibilityIdentifier("newFeatureView")
   ```

## Environment Configuration

### Backend Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `FLASK_DEBUG` | `false` | Enable debug mode |
| `DB_PATH` | `./astronova.db` | SQLite database path |
| `OPENAI_API_KEY` | — | Required for AI chat |
| `OPENAI_MODEL` | `gpt-4o-mini` | OpenAI model |

Create `.env` file:
```bash
FLASK_DEBUG=true
PORT=8080
OPENAI_API_KEY=sk-...
```

### iOS Configuration

API URL resolution in `AppConfig.swift`:
- Debug + Simulator: `http://127.0.0.1:8080`
- Device/Release: `https://astronova.onrender.com`

Override via Info.plist:
```xml
<key>API_BASE_URL</key>
<string>http://your-server.com:8080</string>
```

## Database Management

### Migrations

Database schema is managed via Python migrations in `server/migrations/`. Migrations run automatically at app startup.

**Check current version:**
```bash
sqlite3 server/astronova.db "SELECT * FROM schema_migrations"
```

**Create a new migration:**
```bash
# Create file: server/migrations/NNN_description.py
# Example: 002_add_user_preferences.py
```

Migration file structure:
```python
VERSION = 2  # Must match filename prefix
NAME = "add_user_preferences"

def up(conn):
    cur = conn.cursor()
    cur.execute("ALTER TABLE users ADD COLUMN preferences TEXT")
    conn.commit()

def down(conn):  # Optional rollback
    pass
```

### Reset Database
```bash
cd server
rm astronova.db
python app.py  # Recreates via migrations
```

### Seed Test Data
```bash
cd server
python seed_sankalp.py
```

### View Database
```bash
sqlite3 server/astronova.db
.tables
SELECT * FROM users;
SELECT * FROM schema_migrations;  # Check migration history
```

## Debugging

### Backend Logs
- Debug logs: `server/backend.log`
- Request tracing: Check `X-Request-ID` header in responses

### iOS Debugging
- NetworkClient logs raw response on decode errors
- Use Xcode console for print statements
- Enable network debugging in scheme settings

### Common Issues

**Backend won't start:**
```bash
# Check port in use
lsof -i :8080
# Kill if needed
kill -9 <PID>
```

### Post-Deploy Verification

```bash
bash scripts/deploy-post-push-check.sh --base-url https://astronova.onrender.com --wait-seconds 300
```

**iOS can't connect to backend:**
- Ensure backend running on `0.0.0.0:8080` (not `127.0.0.1`)
- Check simulator network settings
- Verify ATS allows localhost (`NSAppTransportSecurity` in Info.plist)

**Swiss Ephemeris errors:**
```bash
pip install pyswisseph
# Or continue with fallback approximations
```

## Git Workflow

### Branch Naming
- `feat/feature-name` — New features
- `fix/bug-description` — Bug fixes
- `refactor/component-name` — Refactoring
- `docs/topic` — Documentation

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
feat: add relationship pulse calculation
fix: correct dasha balance year computation
refactor: extract timeline calculator
docs: update API reference
test: add coverage for horoscope endpoint
```

### Pull Request Process
1. Create feature branch from `main`
2. Make changes and add tests
3. Run full test suite: `pytest tests/ -v`
4. Run pre-commit: `pre-commit run --all-files`
5. Push and create PR
6. Wait for CI checks to pass
7. Request review

## CI/CD

### GitHub Actions Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `test.yml` | Push/PR | Python tests, coverage, linting |
| `ios.yml` | iOS changes | Xcode build and tests |
| `deploy.yml` | Push to main/tags | Deploy to Render |

### Coverage Requirements
- Minimum: 80% (enforced in CI)
- Check locally: `pytest --cov-fail-under=80`

## Useful Commands Reference

```bash
# Backend
python app.py                          # Start server
pytest tests/ -v                       # Run tests
pytest --cov=. --cov-report=html      # Coverage report
black . && isort .                     # Format code
ruff check . --fix                     # Lint with auto-fix

# iOS
open client/astronova.xcodeproj        # Open Xcode
xcodebuild test ...                    # Run tests

# Git
git checkout -b feat/new-feature       # Create branch
git commit -m "feat: description"      # Commit
git push -u origin HEAD                # Push branch

# Pre-commit
pre-commit install                     # Setup hooks
pre-commit run --all-files            # Run all checks
```
