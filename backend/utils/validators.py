from functools import wraps
from flask import request, jsonify

def validate_request(model):
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            try:
                data = request.get_json() or {}
                validated = model(**data)
                return fn(validated, *args, **kwargs)
            except Exception as e:
                return jsonify({'error': str(e)}), 400
        return wrapper
    return decorator
