# Comprehensive Test Suite Documentation

## Overview

This test suite provides complete coverage of the Astronova astrology server, including:
- Unit tests for service-layer business logic
- Integration tests for API endpoints
- Timezone accuracy tests
- Dasha transition calculation tests
- Horoscope generation and lucky elements tests
- Error handling and edge case tests

## Test Structure

```
tests/
├── conftest.py                        # Shared fixtures and configuration
├── test_service_layer.py             # Service unit tests (fast)
├── test_dasha_transitions.py         # P1 bug fix validation
├── test_horoscope_service.py         # Horoscope generation tests
├── test_dasha_timezone_accuracy.py   # Timezone handling tests
├── test_api_integration.py           # API endpoint integration tests
├── test_dashas_complete.py           # Legacy endpoint tests
└── requirements-test.txt             # Test dependencies
```

## Installation

```bash
# Install test dependencies
pip3 install -r tests/requirements-test.txt
```

## Running Tests

### Quick Run (All Tests)
```bash
./scripts/run_comprehensive_tests.sh
```

### Specific Test Files
```bash
# Unit tests only
pytest tests/test_service_layer.py -v

# Dasha transition tests (P1 bug validation)
pytest tests/test_dasha_transitions.py -v

# Horoscope tests
pytest tests/test_horoscope_service.py -v

# Timezone tests
pytest tests/test_dasha_timezone_accuracy.py -v

# API integration
pytest tests/test_api_integration.py -v
```

### With Coverage
```bash
pytest tests/ --cov=. --cov-report=html --cov-report=term-missing
open htmlcov/index.html  # View coverage report
```

### Parallel Execution (Faster)
```bash
pytest tests/ -n auto  # Uses all available CPUs
```

### Specific Test Markers
```bash
# Run only unit tests
pytest -m unit

# Run only integration tests
pytest -m integration

# Skip slow tests
pytest -m "not slow"

# Run only horoscope tests
pytest -m horoscope
```

## Test Coverage

### 1. Service Layer Tests (`test_service_layer.py`)
- **DashaService**: Complete dasha calculations, timeline generation, period sequences
- **EphemerisService**: Planetary positions, sign changes, location variations
- **PlanetaryStrengthService**: Impact calculations, exaltation/debilitation, strength analysis
- **DashaInterpretationService**: Narrative generation, transition insights, educational content
- **Integration**: Full pipeline from calculation to interpretation

### 2. Dasha Transition Tests (`test_dasha_transitions.py`)
**Purpose**: Validate P1 bug fix for days_remaining calculation

- Day calculation accuracy at midnight, noon, and end of day
- Consistency throughout the day (no off-by-one errors)
- Edge cases: last day, one day before, timezone-aware datetime
- All three levels: Mahadasha, Antardasha, Pratyantardasha
- Frozen time scenarios (using freezegun)

### 3. Horoscope Service Tests (`test_horoscope_service.py`)
**Purpose**: Ensure bespoke user experiences, no hardcoding

- All 12 zodiac signs generate unique content
- Content changes with date (planetary transits)
- Sign traits incorporated (keywords, elements, rulers)
- Period types (daily/weekly/monthly) differ
- Lucky elements: rotation, uniqueness, sign accuracy
- No hardcoded "Purple/Seven" values
- Year-long rotation coverage
- Ephemeris integration (Sun transits, planetary influences)

### 4. Timezone Accuracy Tests (`test_dasha_timezone_accuracy.py`)
**Purpose**: Prevent 4-year dasha discrepancy bug

- Same UTC moment gives identical dasha
- Timezone shifts affect Moon position correctly
- Multiple timezone conversions (UTC, EST, JST, AEDT, etc.)
- DST boundary handling
- Leap day calculations
- GET and POST endpoint consistency
- Invalid timezone error handling
- Original bug scenario validation

### 5. API Integration Tests (`test_api_integration.py`)
**Purpose**: Validate all endpoints end-to-end

**Horoscope Endpoints:**
- All 12 signs
- All period types (daily/weekly/monthly)
- Date-specific queries
- Invalid input handling
- No hardcoded values verification
- Response schema validation

**Dasha Endpoints:**
- GET /dashas with all parameters
- POST /dashas/complete with full payload
- Missing parameters error handling
- Transitions and education flags
- Boundaries and debug modes
- Response schema validation

**Positions Endpoint:**
- Current planetary positions
- All major planets present

**Error Handling:**
- 404 for nonexistent routes
- 405 for wrong HTTP methods
- Invalid JSON payloads
- Invalid date formats

### 6. Legacy Tests (`test_dashas_complete.py`)
**Purpose**: Maintain compatibility with existing tests

## Key Test Scenarios

### Critical Bug Validations

#### P1: Dasha Transition Days Calculation
```python
# Bug: datetime with time component vs midnight datetime
# Fixed: Use date-only comparison

# Test at various times throughout day
@pytest.mark.parametrize("hour", [0, 6, 12, 18, 23])
def test_days_remaining_consistent_throughout_day(hour):
    target_date = datetime(2025, 1, 1, hour, 30, 0)
    # Should give identical days_remaining regardless of hour
```

#### P1: Dasha Endpoint Inconsistency
```python
# Bug: GET and POST endpoints returned different dates (4-year diff)
# Fixed: Both delegate to canonical DashaService

def test_get_post_endpoints_match():
    # Same birth data should give same dasha
    get_data = client.get('/api/v1/astrology/dashas?...')
    post_data = client.post('/api/v1/astrology/dashas/complete', json={...})
    assert get_data['mahadasha'] == post_data['dasha']['mahadasha']
```

#### P1: Horoscope Hardcoding
```python
# Bug: Only 5 generic phrases, empty lucky elements
# Fixed: Real astrology with sign-specific traits

def test_no_hardcoded_values():
    results = [horoscope(sign, date) for sign in signs for date in dates]
    colors = [r['luckyElements']['color'] for r in results]
    # Should vary, not all "Purple"
    assert len(set(colors)) > 1
```

### Bespoke User Experience Validation

```python
def test_different_users_different_content():
    # Different signs on same day
    aries = get_horoscope('aries', '2025-01-15')
    cancer = get_horoscope('cancer', '2025-01-15')
    assert aries['content'] != cancer['content']
    assert aries['luckyElements'] != cancer['luckyElements']

def test_same_user_different_days():
    # Same sign on different days
    day1 = get_horoscope('leo', '2025-01-15')
    day2 = get_horoscope('leo', '2025-01-16')
    # Lucky elements should rotate
    assert day1['luckyElements'] != day2['luckyElements']
```

## Fixtures

### Shared Fixtures (conftest.py)
- `client`: Flask test client
- `sample_birth_data`: Standard birth data dictionary
- `sample_birth_datetime`: UTC datetime for service tests
- `sample_moon_longitude`: Moon position for dasha tests
- `sample_target_date`: Standard target date
- `all_zodiac_signs`: List of 12 signs
- `common_timezones`: List of common timezones

## Test Markers

- `@pytest.mark.unit`: Fast, isolated unit tests
- `@pytest.mark.integration`: Slower API integration tests
- `@pytest.mark.slow`: Tests >1s execution time
- `@pytest.mark.timezone`: Timezone-specific tests
- `@pytest.mark.ephemeris`: Swiss Ephemeris-dependent tests
- `@pytest.mark.transition`: Dasha transition tests
- `@pytest.mark.horoscope`: Horoscope generation tests
- `@pytest.mark.parametrize`: Data-driven tests

## Coverage Goals

- **Target**: >90% code coverage
- **Critical paths**: 100% (dasha calculations, horoscope generation)
- **Service layer**: >95%
- **API layer**: >90%
- **Error handling**: >85%

## Continuous Testing

### Pre-commit
```bash
pytest tests/ -m "unit and not slow" --maxfail=1
```

### CI/CD
```bash
./scripts/run_comprehensive_tests.sh
```

## Troubleshooting

### Tests Fail Due to Missing Swiss Ephemeris
```bash
# Install pyswisseph
pip3 install pyswisseph
```

### Timezone Tests Fail
```bash
# Ensure tzdata is up to date
pip3 install --upgrade tzdata
```

### Coverage Report Not Generated
```bash
pip3 install pytest-cov coverage
```

### Parallel Tests Fail
```bash
pip3 install pytest-xdist
```

## Adding New Tests

### Template for New Test File
```python
"""
Brief description of what this test file covers.
"""
from __future__ import annotations

import pytest
from datetime import datetime


class TestFeatureName:
    """Test description."""

    @pytest.fixture
    def setup(self):
        """Setup fixture."""
        return {}

    def test_basic_functionality(self, setup):
        """Test basic functionality."""
        assert True

    @pytest.mark.parametrize("input,expected", [
        (1, 2),
        (2, 4),
    ])
    def test_parametrized(self, input, expected):
        """Test with multiple inputs."""
        assert input * 2 == expected
```

## Best Practices

1. **Test Isolation**: Each test should be independent
2. **Clear Names**: Use descriptive test names that explain what's being tested
3. **AAA Pattern**: Arrange, Act, Assert
4. **Fixtures**: Use fixtures for common setup
5. **Parametrize**: Use parametrize for data-driven tests
6. **Markers**: Tag tests appropriately for selective running
7. **Coverage**: Aim for high coverage but focus on critical paths
8. **Documentation**: Add docstrings explaining what each test validates

## Future Enhancements

- [ ] Property-based testing with Hypothesis
- [ ] Performance benchmarking
- [ ] Load testing for API endpoints
- [ ] Contract testing for iOS client expectations
- [ ] Snapshot testing for complex responses
- [ ] Mutation testing for test quality
- [ ] Visual regression testing for charts/SVGs