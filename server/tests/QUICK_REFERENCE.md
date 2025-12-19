# Test Fixtures Quick Reference

Quick reference for common test patterns in the AstroNova test suite.

## Common Fixtures Cheat Sheet

```python
# Basic HTTP testing
def test_api(client):
    response = client.get('/api/v1/endpoint')

# With authentication
def test_auth(authenticated_client):
    response = authenticated_client.get('/protected')

# With database
def test_db(clean_db):
    cursor = clean_db.cursor()
    cursor.execute("SELECT * FROM users")

# With test user
def test_user(sample_user):
    assert sample_user['email'] == 'test@astronova.com'

# With user + birth data
def test_astrology(sample_user_with_birth_data):
    user = sample_user_with_birth_data
    birth = db_module.get_user_birth_data(user['id'])

# Create multiple users
def test_many(user_factory):
    users = [user_factory.create() for _ in range(5)]

# Create custom birth data
def test_births(birth_data_factory):
    bd = birth_data_factory.create(timezone='America/New_York')

# Create reports
def test_reports(report_factory, sample_user):
    report = report_factory.create(user_id=sample_user['id'])

# Freeze time
def test_time(freeze_time):
    with freeze_time('2025-01-01'):
        result = time_sensitive_function()

# Mock ephemeris
def test_chart(mock_ephemeris):
    chart = calculate_chart()  # Uses mocked positions

# Standard birth data
def test_calc(sample_birth_data):
    assert sample_birth_data['date'] == '1990-01-15'

# Planet data
def test_strength(sample_planet_data):
    impact = calculate_impact('Sun', sample_planet_data)

# Exalted planets
def test_strong(exalted_planets):
    # All planets at peak strength
    strength = calculate_strength('Jupiter', exalted_planets)
```

## Common Test Patterns

### Test API Endpoint
```python
@pytest.mark.api
def test_endpoint(client):
    response = client.get('/api/v1/horoscope?sign=aries')
    assert response.status_code == 200
    data = response.get_json()
    assert 'content' in data
```

### Test with Authentication
```python
@pytest.mark.integration
def test_protected(authenticated_client, sample_user):
    response = authenticated_client.get(f'/api/v1/user/{sample_user["id"]}/profile')
    assert response.status_code == 200
```

### Test Database Operations
```python
@pytest.mark.unit
def test_db_insert(clean_db):
    db_module.upsert_user('user1', 'test@test.com', 'Test', 'User', 'Test User')

    cursor = clean_db.cursor()
    cursor.execute("SELECT COUNT(*) FROM users")
    assert cursor.fetchone()[0] == 1
```

### Test with Multiple Users
```python
def test_bulk(user_factory, report_factory):
    # Create 10 users
    users = [user_factory.create() for _ in range(10)]

    # Create report for each
    for user in users:
        report_factory.create(user_id=user['id'])

    # Verify
    for user in users:
        reports = db_module.get_user_reports(user['id'])
        assert len(reports) == 1
```

### Test Time-Dependent Logic
```python
def test_daily_change(freeze_time):
    with freeze_time('2025-01-01'):
        day1 = get_daily_horoscope('aries')

    with freeze_time('2025-01-02'):
        day2 = get_daily_horoscope('aries')

    assert day1 != day2
```

### Test All Zodiac Signs
```python
@pytest.mark.parametrize("sign", [
    'aries', 'taurus', 'gemini', 'cancer',
    'leo', 'virgo', 'libra', 'scorpio',
    'sagittarius', 'capricorn', 'aquarius', 'pisces'
])
def test_all_signs(sign):
    horoscope = generate_horoscope(sign)
    assert len(horoscope) > 0
```

### Test with Mocked Services
```python
@pytest.mark.unit
def test_chart_calc(mock_ephemeris, sample_birth_data):
    # Ephemeris returns predictable data
    chart = calculate_natal_chart(
        sample_birth_data['date'],
        sample_birth_data['time'],
        sample_birth_data['latitude'],
        sample_birth_data['longitude']
    )

    assert 'planets' in chart
    assert chart['planets']['sun']['sign'] == 'Capricorn'
```

### Test Integration Flow
```python
@pytest.mark.integration
def test_user_journey(client, user_factory, birth_data_factory):
    # Create user
    user = user_factory.create()

    # Store birth data
    bd = birth_data_factory.create()
    db_module.upsert_user_birth_data(
        user['id'], bd['date'], bd['time'], bd['timezone'],
        bd['latitude'], bd['longitude'], bd['location_name']
    )

    # Retrieve and verify
    stored = db_module.get_user_birth_data(user['id'])
    assert stored['birth_date'] == bd['date']
```

## Running Tests

### Basic Commands
```bash
# All tests
pytest

# Specific file
pytest tests/test_api_integration.py

# Specific test
pytest tests/test_api_integration.py::TestHoroscopeEndpoints::test_horoscope_all_signs

# Verbose
pytest -v

# Stop on first failure
pytest -x

# Show print statements
pytest -s
```

### Using Markers
```bash
# Only unit tests
pytest -m unit

# Skip slow tests
pytest -m "not slow"

# Only integration tests
pytest -m integration

# Skip external services
pytest -m "not external"

# API tests only
pytest -m api

# Fast tests only
pytest -m "unit or integration and not slow"
```

### Performance
```bash
# Show slowest tests
pytest --durations=10

# Parallel execution (requires pytest-xdist)
pytest -n auto

# Coverage report (requires pytest-cov)
pytest --cov=. --cov-report=html
```

## Test Markers Quick Reference

| Marker | Description | Example |
|--------|-------------|---------|
| `@pytest.mark.unit` | Fast, isolated unit test | `pytest -m unit` |
| `@pytest.mark.integration` | Integration test | `pytest -m integration` |
| `@pytest.mark.slow` | Test takes >1 second | `pytest -m "not slow"` |
| `@pytest.mark.external` | Requires external services | `pytest -m "not external"` |
| `@pytest.mark.api` | API endpoint test | `pytest -m api` |
| `@pytest.mark.service` | Service layer test | `pytest -m service` |
| `@pytest.mark.horoscope` | Horoscope generation test | `pytest -m horoscope` |

## Factory Usage Quick Reference

### UserFactory
```python
def test(user_factory):
    # Default user
    u1 = user_factory.create()

    # Custom email
    u2 = user_factory.create(email='custom@test.com')

    # Custom name
    u3 = user_factory.create(first_name='Alice', last_name='Smith')

    # All have unique IDs automatically
```

### BirthDataFactory
```python
def test(birth_data_factory):
    # Default birth data (varied locations)
    bd1 = birth_data_factory.create()

    # Custom timezone
    bd2 = birth_data_factory.create(timezone='America/New_York')

    # Custom date and time
    bd3 = birth_data_factory.create(
        date='2000-01-01',
        time='12:00'
    )
```

### ReportFactory
```python
def test(report_factory, sample_user):
    # Default report
    r1 = report_factory.create(user_id=sample_user['id'])

    # Custom type
    r2 = report_factory.create(
        user_id=sample_user['id'],
        type='transit'
    )

    # Custom title and content
    r3 = report_factory.create(
        user_id=sample_user['id'],
        title='Custom Title',
        content='Custom content'
    )
```

## Debugging Tests

```bash
# Show full traceback
pytest --tb=long

# Drop into debugger on failure
pytest --pdb

# Show local variables on failure
pytest -l

# Show captured output for failed tests
pytest -rA

# Verbose with captured output
pytest -vv -s
```

## Common Assertions

```python
# HTTP response
assert response.status_code == 200
assert 'key' in response.get_json()

# Database
cursor.execute("SELECT COUNT(*) FROM users")
assert cursor.fetchone()[0] > 0

# Content validation
assert len(content) > 50
assert 'expected' in content.lower()

# Structure validation
assert 'planets' in result
assert result['sun']['sign'] in ['Aries', 'Taurus', ...]

# Numeric ranges
assert 0 <= score <= 10
assert -90 <= latitude <= 90
```

## Tips & Tricks

1. **Use factories for multiple objects** - Don't create users manually
2. **Use clean_db for fresh state** - Ensures test isolation
3. **Mock external services** - Use `mock_ephemeris`, `mock_geocoding`
4. **Freeze time for reproducibility** - Use `freeze_time` fixture
5. **Use markers to skip slow tests** - `pytest -m "not slow"`
6. **Parametrize for multiple cases** - Test all zodiac signs at once
7. **Use -x to stop on first failure** - Faster debugging
8. **Use --lf to run last failed** - Iterative debugging
9. **Add markers to new tests** - Helps with test organization
10. **Check coverage regularly** - `pytest --cov=. --cov-report=html`

## Full Example Test

```python
@pytest.mark.integration
@pytest.mark.api
def test_complete_user_flow(
    client,
    user_factory,
    birth_data_factory,
    report_factory,
    freeze_time
):
    """Complete user journey test."""
    # Create user
    user = user_factory.create()

    # Store birth data
    bd = birth_data_factory.create()
    db_module.upsert_user_birth_data(
        user['id'], bd['date'], bd['time'],
        bd['timezone'], bd['latitude'],
        bd['longitude'], bd['location_name']
    )

    # Freeze time for reproducibility
    with freeze_time('2025-01-01 12:00:00'):
        # Generate report
        report = report_factory.create(
            user_id=user['id'],
            type='natal_chart'
        )

        # Verify report exists
        reports = db_module.get_user_reports(user['id'])
        assert len(reports) == 1
        assert reports[0]['report_id'] == report['report_id']

        # Test API endpoint
        response = client.get(f'/api/v1/reports/{report["report_id"]}')
        assert response.status_code == 200

        data = response.get_json()
        assert data['type'] == 'natal_chart'
        assert data['user_id'] == user['id']
```

## More Examples

See `tests/test_fixtures_example.py` for comprehensive examples of all fixtures and patterns.