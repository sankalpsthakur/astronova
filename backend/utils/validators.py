from functools import wraps
from flask import request, jsonify
from pydantic import ValidationError
import logging

def validate_request(model):
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            try:
                data = request.get_json() or {}
                validated = model(**data)
                return fn(validated, *args, **kwargs)
            except ValidationError as e:
                return jsonify({'error': 'Validation failed', 'details': e.errors()}), 400
            except ValueError as e:
                return jsonify({'error': 'Invalid data format'}), 400
            except Exception as e:
                logging.error(f"Unexpected error in validation: {str(e)}")
                return jsonify({'error': 'Internal server error'}), 500
        return wrapper
    return decorator
