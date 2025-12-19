# Authentication & Security Test Suite

Comprehensive security testing for Astronova server authentication system.

## Quick Start

```bash
# Run all security tests
cd server
python3 -m pytest tests/test_auth_security.py -v

# Run specific test class
python3 -m pytest tests/test_auth_security.py::TestCrossUserAccess -v

# Run with coverage
python3 -m pytest tests/test_auth_security.py --cov=routes.auth --cov-report=html
```

## Test Coverage

**Total Tests:** 55 ✅
**Test Categories:** 14
**Status:** All passing

### Test Categories

1. **Apple Sign-In Flow** (8 tests)
   - Valid/invalid data handling
   - Database record creation
   - User upsert logic

2. **Token Refresh** (9 tests)
   - Bearer token validation
   - Authorization header requirements
   - Edge cases (null, undefined, malformed)

3. **Token Validation** (3 tests)
   - Valid/invalid token checking
   - Missing token handling

4. **Logout** (3 tests)
   - Endpoint functionality
   - With/without authentication

5. **Delete Account** (3 tests)
   - Account deletion endpoint
   - Data cleanup verification

6. **Protected Endpoints** (4 tests)
   - Authentication requirements
   - Authorization validation

7. **Cross-User Access** (3 tests)
   - User isolation testing
   - Privilege escalation attempts

8. **SQL Injection** (4 tests)
   - Parameterized query verification
   - Attack vector testing

9. **Invalid Token Formats** (5 tests)
   - Malformed JWT handling
   - Special characters, Unicode
   - Extremely long tokens

10. **JWT Expiration** (2 tests)
    - Expiration field presence
    - Expiration calculation

11. **Rate Limiting** (2 tests)
    - Brute force protection
    - Request throttling

12. **Security Headers** (2 tests)
    - Request ID tracking
    - CORS configuration

13. **Input Validation** (4 tests)
    - Required field checking
    - Null/extreme value handling

14. **Database Security** (3 tests)
    - Parameterized queries
    - Foreign keys & WAL mode

## Key Findings

### ✅ Secure

- **SQL Injection Protection:** All database operations use parameterized queries
- **Input Validation:** Proper validation and error handling
- **Database Security:** Foreign keys enabled, WAL mode active
- **Error Handling:** Graceful handling of edge cases

### ⚠️ Security Vulnerabilities Identified

#### CRITICAL

1. **No Authentication Middleware**
   - Protected endpoints don't validate tokens
   - User identity can be spoofed

2. **Cross-User Data Access**
   - Users can access other users' reports
   - Birth data exposed without authorization

3. **No Rate Limiting**
   - Susceptible to brute force attacks
   - No request throttling

4. **Logout Doesn't Invalidate Tokens**
   - Tokens remain valid after logout
   - No token blacklist

5. **Delete Account Doesn't Delete Data**
   - User data persists after deletion request
   - GDPR compliance risk

#### MEDIUM

6. **No JWT Signature Validation** (demo mode)
7. **No Token Expiration Enforcement**
8. **Missing Security Headers** (HSTS, CSP, etc.)
9. **No Apple Token Validation** (demo mode)

See [SECURITY_AUDIT_REPORT.md](./SECURITY_AUDIT_REPORT.md) for detailed findings.

## Test Structure

```
test_auth_security.py
├── TestAppleSignIn              # Apple authentication flow
├── TestTokenRefresh             # Token refresh endpoint
├── TestTokenValidation          # Token validation endpoint
├── TestLogout                   # Logout functionality
├── TestDeleteAccount            # Account deletion
├── TestProtectedEndpoints       # Auth requirements
├── TestCrossUserAccess          # User isolation
├── TestSQLInjection             # SQL injection protection
├── TestInvalidTokenFormats      # Malformed token handling
├── TestJWTExpiration            # Expiration handling
├── TestRateLimiting             # Rate limiting status
├── TestSecurityHeaders          # Security headers
├── TestDataValidation           # Input validation
└── TestDatabaseSecurity         # Database configuration
```

## Running Specific Tests

```bash
# Test SQL injection protection
pytest tests/test_auth_security.py::TestSQLInjection -v

# Test cross-user access
pytest tests/test_auth_security.py::TestCrossUserAccess -v

# Test rate limiting
pytest tests/test_auth_security.py::TestRateLimiting -v

# Test a specific test case
pytest tests/test_auth_security.py::TestAppleSignIn::test_apple_auth_valid_complete_data -v
```

## Test Fixtures

- `client`: Flask test client with isolated database
- `auth_token`: Valid demo authentication token
- `test_user_id`: Test user ID for scenarios
- `another_user_id`: Second user for cross-access tests
- `test_db_path`: Temporary isolated database

## Continuous Integration

Add to CI/CD pipeline:

```yaml
# .github/workflows/test.yml
- name: Run Security Tests
  run: |
    cd server
    pytest tests/test_auth_security.py -v --cov=routes.auth --cov-report=xml

- name: Upload Coverage
  uses: codecov/codecov-action@v3
  with:
    file: ./coverage.xml
```

## Development Guidelines

### Adding New Tests

1. Add test to appropriate test class
2. Use descriptive test names
3. Include docstrings explaining what's tested
4. Document expected behavior
5. Mark vulnerabilities with comments

Example:
```python
def test_new_security_feature(self, client):
    """Test that new security feature prevents attack X."""
    # Attempt attack
    response = client.post('/api/v1/endpoint', json={'malicious': 'data'})

    # Verify protection
    assert response.status_code == 403
    data = response.get_json()
    assert 'error' in data
```

### Test Naming Convention

- `test_<feature>_<scenario>` for positive tests
- `test_<feature>_<attack>_blocked` for security tests
- `test_<feature>_<edge_case>_handled` for edge cases

## Production Checklist

Before deploying to production, ensure:

- [ ] Authentication middleware implemented
- [ ] Authorization checks added to all endpoints
- [ ] Rate limiting configured
- [ ] Token blacklist implemented (Redis)
- [ ] Account deletion functional
- [ ] JWT signature validation enabled
- [ ] Token expiration enforced
- [ ] Security headers added
- [ ] Apple token validation implemented
- [ ] Audit logging enabled

## References

- **Full Audit Report:** [SECURITY_AUDIT_REPORT.md](./SECURITY_AUDIT_REPORT.md)
- **Test File:** [test_auth_security.py](./test_auth_security.py)
- **Auth Implementation:** [../routes/auth.py](../routes/auth.py)

## Support

For questions or issues with the security tests:
1. Review the full audit report
2. Check test implementation in test_auth_security.py
3. Review auth.py implementation

---

**Last Updated:** 2025-09-30
**Test Suite Version:** 1.0
**Status:** ✅ 55/55 tests passing