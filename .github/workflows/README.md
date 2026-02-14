# GitHub Actions Workflows

This directory contains GitHub Actions workflow configurations for the Astronova project.

## Workflows

### 1. Test Suite (`test.yml`)

Comprehensive testing workflow that runs on every push and pull request.

**Features:**
- Matrix testing across Python 3.9, 3.10, 3.11, 3.12
- Code coverage with 80% minimum threshold
- Security scanning (Bandit, Safety, Trivy)
- Performance benchmarks
- Integration tests with live Flask server
- Coverage reports uploaded to Codecov
- Artifact uploads for test results and coverage reports

**Triggers:**
- Push to `main` or `dev` branches
- Pull requests to `main` or `dev` branches
- Manual workflow dispatch

**Jobs:**
- `test-python`: Runs Python tests across all supported versions
- `test-performance`: Runs performance benchmarks
- `integration-tests`: Runs integration tests with live server
- `security-scan`: Runs Trivy vulnerability scanner
- `test-summary`: Aggregates test results

### 2. iOS Build (`ios.yml`)

iOS build and test workflow for the SwiftUI client.

**Features:**
- Xcode build with warning detection
- Swift test execution with coverage
- Swift linting (SwiftLint)
- Build log artifact uploads
- Swift Package Manager caching

**Triggers:**
- Push to `main` or `dev` branches (only on client/** changes)
- Pull requests to `main` or `dev` branches (only on client/** changes)
- Manual workflow dispatch

**Jobs:**
- `swift-ios-build`: Builds iOS app and runs tests
- `swift-lint`: Runs SwiftLint checks
- `ios-summary`: Aggregates build results

### 3. Deployment (`deploy.yml`)

Automated deployment workflow for staging and production environments.

**Features:**
- Pre-deployment validation (tests, code quality)
- Staging deployment on main branch
- Production deployment on version tags
- 5-minute delayed post-deploy verification via `scripts/deploy-post-push-check.sh`
- Health check + endpoint smoke coverage for public and auth-protected routes
- Automatic rollback on failure
- GitHub release creation for production

**Triggers:**
- Push to `main` branch (deploys to staging)
- Tags matching `v*.*.*` (deploys to production)
- Manual workflow dispatch with environment selection

**Jobs:**
- `pre-deploy-checks`: Validates code before deployment
- `deploy-staging`: Deploys to staging environment
- `deploy-production`: Deploys to production environment
- `post-deploy-monitor`: Monitors deployment health

### Post-Deployment Verification

The `deploy-post-push-check.sh` script performs comprehensive endpoint validation after deployment:

**Validation Steps:**
1. **Health endpoint** - Retries with backoff to confirm service is live
2. **Authentication** - Validates `auth/apple` endpoint
3. **Core astrology endpoints** - Tests `horoscope`, `ephemeris`, `positions`
4. **Chart generation** - Verifies Western + Vedic chart rendering
5. **Report generation** - Tests report creation + PDF download
6. **Temple poojas** - Validates temple services endpoint
7. **Chat endpoint** - Tests chat API (503 acceptable without AI key)

**Timing:** 300-second wait for Render cold start, then sequential endpoint validation.

**Exit codes:** 0 = all pass, non-zero = failures found.

**Usage:**
```bash
bash scripts/deploy-post-push-check.sh \
  --base-url https://astronova.onrender.com \
  --wait-seconds 300 \
  --health-retries 30 \
  --health-delay 10
```

Use the staging URL for staging runs.

### 4. CI (`ci.yml`)

Legacy CI workflow (kept for compatibility).

**Status:** Deprecated - Use `test.yml` and `ios.yml` instead.

### 5. Claude Code (`claude.yml`)

GitHub integration for Claude Code AI assistance.

**Features:**
- Responds to `@claude` mentions in issues and PRs
- Provides AI-powered code assistance
- Requires `ANTHROPIC_API_KEY` secret

## Setup Instructions

### Required Secrets

Add these secrets to your GitHub repository (Settings > Secrets and variables > Actions):

1. **CODECOV_TOKEN** (Optional)
   - For code coverage reporting
   - Sign up at https://codecov.io
   - Get token from repository settings

2. **RENDER_API_KEY** (Optional)
   - For automatic deployments
   - Get from Render dashboard > Account Settings > API Keys

3. **ANTHROPIC_API_KEY** (Optional)
   - For Claude Code integration
   - Get from Anthropic dashboard

### Optional Configuration

1. **Update Repository Owner**
   - Edit badge URLs in `README.md`
   - Replace `yourusername` with your GitHub username

2. **Update Deployment URLs**
   - Edit `deploy.yml`
   - Replace URLs with your actual deployment endpoints

3. **Adjust Python Versions**
   - Edit `test.yml` matrix section
   - Add/remove Python versions as needed

4. **Adjust Xcode Version**
   - Edit `ios.yml` Xcode selection
   - Update to match your requirements

## Monitoring Workflow Runs

View workflow runs:
1. Go to repository on GitHub
2. Click "Actions" tab
3. Select a workflow from the left sidebar
4. View run history and logs

## Troubleshooting

### Tests Failing in CI but Passing Locally

1. Check Python/Xcode version differences
2. Verify all dependencies are in requirements.txt
3. Check for environment-specific code
4. Review workflow logs for specific errors

### Coverage Below Threshold

1. Run locally: `pytest tests/ -v --cov=. --cov-report=term-missing`
2. Identify uncovered code
3. Add tests to improve coverage
4. Coverage threshold is set to 80%

### Deployment Failures

1. Check pre-deployment tests pass
2. Verify deployment secrets are configured
3. Check health check endpoints are accessible
4. Review deployment logs in workflow

### Swift Build Failures

1. Check Xcode version compatibility
2. Verify Swift Package dependencies
3. Check for compiler warnings
4. Review build logs for specific errors

## Best Practices

1. **Always run tests locally before pushing**
   ```bash
   cd server && pytest tests/ -v --cov=.
   cd client && xcodebuild test -project astronova.xcodeproj -scheme AstronovaApp
   ```

2. **Use pre-commit hooks**
   ```bash
   pip install pre-commit
   pre-commit install
   ```

3. **Keep dependencies updated**
   ```bash
   pip list --outdated
   ```

4. **Monitor workflow runs**
   - Subscribe to notifications for failed workflows
   - Review logs for warnings and errors

5. **Test deployment changes in staging first**
   - Push to main branch to deploy to staging
   - Verify staging deployment before tagging for production

## Workflow Status

| Workflow | Status | Description |
|----------|--------|-------------|
| Test Suite | ![Test Suite](https://github.com/yourusername/astronova/actions/workflows/test.yml/badge.svg) | Python testing and coverage |
| iOS Build | ![iOS Build](https://github.com/yourusername/astronova/actions/workflows/ios.yml/badge.svg) | iOS build and test |
| Deploy | ![Deploy](https://github.com/yourusername/astronova/actions/workflows/deploy.yml/badge.svg) | Deployment to staging/production |
| Claude Code | ![Claude Code](https://github.com/yourusername/astronova/actions/workflows/claude.yml/badge.svg) | AI code assistance |

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines on contributing to this project, including CI/CD requirements.
