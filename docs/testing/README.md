# Testing & Quality Assurance

Test reports, coverage metrics, accuracy benchmarks, and quality assurance documentation.

## Test Reports

### [Test Report](./TEST_REPORT.md)
Comprehensive test suite results including:
- Backend test coverage (499+ tests, 80%+ coverage)
- Unit test results
- Integration test results
- API endpoint testing
- Service layer testing
- Test execution time and performance

**Latest Run**: See report for timestamp

### [E2E Test Report](./E2E_TEST_REPORT.md)
End-to-end testing results covering:
- Complete user flows
- Cross-feature integration testing
- Real-world usage scenarios
- Bug discoveries and fixes

### [Fresh Build Test Report](./FRESH_BUILD_TEST_REPORT.md)
Fresh build verification testing (most recent):
- Clean build validation
- Dependency resolution testing
- First-run experience
- Installation testing

## Accuracy & Benchmarks

### [Astrology Accuracy](./astrology-accuracy.md)
Quantitative accuracy benchmarks including:
- Swiss Ephemeris comparison
- Planetary position accuracy
- Rising sign calculations
- Dasha timeline verification
- Error margins and tolerances

**Accuracy**: 99.9%+ for core calculations

### [Run Findings](./run-findings.md)
Runtime testing observations including:
- Performance profiling results
- Memory usage patterns
- Network behavior
- Edge cases and corner scenarios

## Test Coverage Summary

- **Backend**: 80%+ coverage, 499+ tests
- **iOS**: Unit tests for core models and services
- **Integration**: Complete API endpoint coverage
- **E2E**: Key user journeys validated

## Post-Deploy Server Verification

```bash
bash scripts/deploy-post-push-check.sh \
  --base-url https://astronova.onrender.com \
  --wait-seconds 300 \
  --health-retries 30 \
  --health-delay 10
```

Key options:

- `--base-url` - Deployment base URL (`https://astronova-staging.onrender.com` for staging)
- `--wait-seconds` - Delay before the first check (default `300`)
- `--health-retries` / `--health-delay` - Retry strategy while waiting for startup
- `--allow-chat-503` - Temporarily treat 503 as acceptable for `/api/v1/chat`
- `--skip-charged-reports` - Skip report generate/download checks
- `--skip-chat` - Skip chat checks

## Running Tests

### Backend
```bash
cd server
pytest tests/ -v                              # All tests
pytest tests/ -v --cov=. --cov-report=html    # With coverage
pytest -m unit                                # Unit tests only
pytest -m "not slow"                          # Skip slow tests
```

### iOS
```bash
cd client
xcodebuild test -project astronova.xcodeproj -scheme AstronovaApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

## UI Journey Tests

Comprehensive end-to-end UI testing covering key user flows and edge cases:

### Test Suites

- **ChaosJourneyTests.swift** - Seeded deterministic chaos testing with 3 adversarial journey paths. Uses deterministic seeds for reproducible test runs that simulate real-world edge cases and rapid user interactions.

- **MonetizationJourneyTests.swift** - Validates complete monetization flows including free-to-credit conversion, credit-to-pro upgrades, and pro report purchases.

- **AccessibilityTests.swift** - VoiceOver navigation verification, color contrast checks, and dynamic type support across key screens.

### Running UI Tests

```bash
xcodebuild test \
  -project client/astronova.xcodeproj \
  -scheme AstronovaApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:AstronovaAppUITests
```

Run specific test class:
```bash
xcodebuild test ... -only-testing:AstronovaAppUITests/ChaosJourneyTests
```

**Note**: Chaos tests use deterministic seeds to ensure reproducible results across test runs.

## Related Documentation

- [Development Guide](../development.md) — Test setup and execution
- `docs/claude/CLAUDE_FULL.md` — Test writing guidelines
- [CONTRIBUTING.md](../CONTRIBUTING.md) — PR test requirements
