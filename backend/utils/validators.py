from functools import wraps
from flask import request, jsonify
from pydantic import ValidationError
import logging

def validate_request(model):
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            try:
                # First, try to get JSON data
                try:
                    data = request.get_json() or {}
                except Exception as json_error:
                    # JSON parsing error should return 400, not 500
                    logging.warning(f"JSON parsing error: {str(json_error)}")
                    return jsonify({'error': 'Invalid JSON format', 'message': 'Request body must be valid JSON'}), 400
                
                # Then validate with Pydantic
                validated = model(**data)
                return fn(validated, *args, **kwargs)
            except ValidationError as e:
                return jsonify({'error': 'Validation failed', 'details': e.errors()}), 400
            except ValueError as e:
                return jsonify({'error': 'Invalid data format', 'message': str(e)}), 400
            except Exception as e:
                logging.error(f"Unexpected error in validation: {str(e)}")
                return jsonify({'error': 'Internal server error'}), 500
        return wrapper
    return decorator
