# Binary Response Tests - Quick Reference

## Running the Tests

```bash
# Run all binary response tests
cd /Users/sankalp/Projects/astronova/server
python3 -m pytest tests/test_binary_responses.py -v

# Run specific test class
python3 -m pytest tests/test_binary_responses.py::TestPDFEndpoints -v
python3 -m pytest tests/test_binary_responses.py::TestBinaryResponseHeaders -v

# Run specific test
python3 -m pytest tests/test_binary_responses.py::TestPDFEndpoints::test_pdf_magic_bytes -v

# Run with detailed output
python3 -m pytest tests/test_binary_responses.py -vv -s

# Run with coverage
python3 -m pytest tests/test_binary_responses.py --cov=routes.reports --cov-report=html
```

## Test Classes

### 1. TestPDFEndpoints (10 tests)
Tests PDF binary response functionality:
- Endpoint accessibility
- Content-Type headers
- PDF magic bytes validation
- Response is binary, not JSON
- Size validation
- Invalid ID handling
- Content verification
- Multiple report types

### 2. TestBinaryResponseHeaders (3 tests)
Tests HTTP headers for binary responses:
- Error responses are JSON
- JSON endpoints have correct content types
- No unnecessary chunked encoding

### 3. TestContentEncoding (2 tests)
Tests compression and encoding:
- Gzip compression support
- Large response handling

### 4. TestBinaryDataIntegrity (2 tests)
Tests binary data integrity:
- Consistent data across requests
- No text encoding corruption

### 5. TestReportAliasRedirect (3 tests)
Tests backward compatibility redirects:
- Singular to plural endpoint redirect
- PDF endpoint redirect
- Content type preservation

### 6. TestCacheHeaders (1 test)
Tests caching behavior:
- Cache header documentation

## Test Results

**Status**: ✅ **21/21 PASSING**

**Execution Time**: ~0.25s

## What These Tests Verify

### ✅ Binary Response Integrity
- PDFs have correct magic bytes (`%PDF-1.4`)
- Binary data is not corrupted by text encoding
- Responses are bytes, not strings
- Data is consistent across multiple requests

### ✅ HTTP Headers
- Content-Type is `application/pdf` for PDFs
- Content-Type is `application/json` for JSON endpoints
- Content-Length matches actual data size
- Error responses have JSON content type

### ✅ Error Handling
- 404 errors return JSON, not binary garbage
- Error responses have proper structure
- Endpoints handle invalid input gracefully

### ✅ Compression
- Server handles gzip encoding requests
- Large responses can be compressed
- Small files don't use chunked encoding

### ✅ Redirects
- `/api/v1/report` redirects to `/api/v1/reports`
- Redirects preserve HTTP method and body
- Content types are preserved after redirect

## Known Issues (Documented in Tests)

### 🔴 Invalid Report IDs Return 200 OK
Current behavior: All report IDs (even invalid) return 200 with placeholder PDF
Expected behavior: Invalid IDs should return 404 with JSON error

### ⚠️ Missing Headers
- No `Content-Disposition` header (can't control download behavior)
- No `Cache-Control` header (no caching optimization)
- No `ETag` header (no cache validation)

### ℹ️ Minimal PDF Content
Current PDFs are placeholders (~50-70 bytes)
Production should generate full formatted PDFs

## Related Files

- **Test file**: `/Users/sankalp/Projects/astronova/server/tests/test_binary_responses.py`
- **Summary**: `/Users/sankalp/Projects/astronova/server/tests/BINARY_RESPONSE_TEST_SUMMARY.md`
- **Implementation**: `/Users/sankalp/Projects/astronova/server/routes/reports.py`

## Example Test Output

```
tests/test_binary_responses.py::TestPDFEndpoints::test_pdf_endpoint_exists PASSED
tests/test_binary_responses.py::TestPDFEndpoints::test_pdf_content_type_header PASSED
tests/test_binary_responses.py::TestPDFEndpoints::test_pdf_magic_bytes PASSED
tests/test_binary_responses.py::TestPDFEndpoints::test_pdf_response_is_not_json PASSED
...
======================== 21 passed in 0.25s ========================
```

## Adding New Tests

To add a new binary response test:

```python
class TestPDFEndpoints:
    def test_new_pdf_feature(self, client):
        """Test description."""
        # Create a report
        response = client.post('/api/v1/reports', json={
            'userId': 'test-user',
            'reportType': 'birth_chart',
            'birthData': {
                'date': '1990-01-15',
                'time': '14:30',
                'timezone': 'UTC',
                'latitude': 19.0,
                'longitude': 72.0
            }
        })
        report_id = response.get_json()['reportId']

        # Test PDF endpoint
        pdf_response = client.get(f'/api/v1/reports/{report_id}/pdf')

        # Assertions
        assert pdf_response.status_code == 200
        assert pdf_response.content_type == 'application/pdf'
        # Add your custom assertions here
```

## CI/CD Integration

Add to your CI pipeline:

```yaml
- name: Run Binary Response Tests
  run: |
    cd server
    python3 -m pytest tests/test_binary_responses.py -v --tb=short
```

## Debugging Failed Tests

If a test fails:

1. Run with verbose output: `pytest tests/test_binary_responses.py -vv -s`
2. Check the middleware logs for request details
3. Inspect response headers and body
4. Verify database state if needed

```python
# Add debug output in tests
print(f"Status: {response.status_code}")
print(f"Headers: {dict(response.headers)}")
print(f"Body (first 100 bytes): {response.data[:100]}")
```