from flask import Blueprint, jsonify, request
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity, get_jwt
from utils.validators import validate_request
from models.schemas import AppleAuthRequest
from services.apple_auth_service import AppleAuthService
from services.user_service import UserService
from services.cloudkit_service import CloudKitService
import logging
from datetime import datetime, timedelta

auth_bp = Blueprint('auth', __name__)
apple_auth = AppleAuthService()
user_service = UserService()
cloudkit = CloudKitService()
logger = logging.getLogger(__name__)

@auth_bp.route('', methods=['GET'])
def auth_info():
    """Get authentication service information"""
    return jsonify({
        'service': 'auth',
        'status': 'available',
        'endpoints': {
            'POST /apple': 'Authenticate with Apple ID',
            'GET /validate': 'Validate JWT token',
            'POST /refresh': 'Refresh JWT token',
            'POST /logout': 'Logout user',
            'GET /user': 'Get current user',
            'PUT /user': 'Update current user'
        }
    })

@auth_bp.route('/apple', methods=['POST'])
@validate_request(AppleAuthRequest)
def authenticate_with_apple(data: AppleAuthRequest):
    """
    Authenticate user with Apple ID token
    """
    try:
        # 1. Verify Apple ID token with Apple's servers
        apple_user_data = apple_auth.verify_token(data.idToken)
        
        if not apple_user_data:
            return jsonify({'error': 'Invalid Apple ID token'}), 401
            
        # 2. Extract user information
        apple_user_id = apple_user_data.get('sub')  # Apple's user identifier
        email = apple_user_data.get('email') or data.email
        
        # 3. Create or update user in our system
        user = user_service.create_or_update_user(
            apple_user_id=apple_user_id,
            email=email,
            first_name=data.firstName,
            last_name=data.lastName,
            user_identifier=data.userIdentifier
        )
        
        # 4. Save user to CloudKit
        cloudkit.save_user_profile(user_id=user.id, profile_data=user.to_dict())
        
        # 5. Generate our internal JWT token
        jwt_token = create_access_token(
            identity=user.id,
            additional_claims={
                'apple_user_id': apple_user_id,
                'email': email,
                'user_type': 'authenticated'
            }
        )
        
        logger.info(f"User authenticated successfully: {user.id}")
        
        return jsonify({
            'jwtToken': jwt_token,
            'user': user.to_dict(),
            'expiresAt': user_service.get_token_expiry().isoformat()
        })
        
    except ValueError as e:
        logger.error(f"Apple authentication validation failed: {str(e)}")
        return jsonify({
            'error': 'Invalid request data',
            'message': str(e),
            'code': 'VALIDATION_ERROR'
        }), 400
    except ConnectionError as e:
        logger.error(f"Apple authentication connection failed: {str(e)}")
        return jsonify({
            'error': 'Unable to verify with Apple servers',
            'message': 'Please check your internet connection and try again',
            'code': 'CONNECTION_ERROR'
        }), 503
    except Exception as e:
        logger.error(f"Apple authentication failed: {str(e)}")
        return jsonify({
            'error': 'Authentication failed',
            'message': 'An unexpected error occurred. Please try again.',
            'code': 'INTERNAL_ERROR'
        }), 500

@auth_bp.route('/validate', methods=['GET'])
@jwt_required()
def validate_token():
    """
    Validate JWT token
    """
    try:
        current_user_id = get_jwt_identity()
        user = user_service.get_user_by_id(current_user_id)
        
        if not user:
            return jsonify({'valid': False, 'error': 'User not found'}), 404
            
        return jsonify({'valid': True, 'user': user.to_dict()})
        
    except Exception as e:
        logger.error(f"Token validation failed: {str(e)}")
        return jsonify({'valid': False, 'error': 'Token validation failed'}), 500

@auth_bp.route('/refresh', methods=['POST'])
@jwt_required()
def refresh_token():
    """
    Refresh JWT token
    """
    try:
        current_user_id = get_jwt_identity()
        user = user_service.get_user_by_id(current_user_id)
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
            
        # Generate new token
        new_token = create_access_token(
            identity=user.id,
            additional_claims={
                'apple_user_id': user.apple_user_id,
                'email': user.email,
                'user_type': 'authenticated'
            }
        )
        
        return jsonify({
            'jwtToken': new_token,
            'user': user.to_dict(),
            'expiresAt': user_service.get_token_expiry().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Token refresh failed: {str(e)}")
        return jsonify({'error': 'Token refresh failed'}), 500

@auth_bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    """
    Logout user (token blacklisting could be added here)
    """
    try:
        user_id = get_jwt_identity()
        logger.info(f"User logged out: {user_id}")
        
        # In future: Add token to blacklist
        # token_blacklist.add(get_jwt()['jti'])
        
        return jsonify({'message': 'Logged out successfully'})
        
    except Exception as e:
        logger.error(f"Logout failed: {str(e)}")
        return jsonify({'error': 'Logout failed'}), 500

@auth_bp.route('/user', methods=['GET'])
@jwt_required()
def get_current_user():
    """
    Get current authenticated user information
    """
    try:
        current_user_id = get_jwt_identity()
        user = user_service.get_user_by_id(current_user_id)
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
            
        return jsonify({'user': user.to_dict()})
        
    except Exception as e:
        logger.error(f"Get user failed: {str(e)}")
        return jsonify({'error': 'Failed to get user'}), 500

@auth_bp.route('/user', methods=['PUT'])
@jwt_required()
def update_current_user():
    """
    Update current authenticated user information
    """
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        user = user_service.update_user(current_user_id, data)
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
            
        # Update CloudKit record
        cloudkit.save_user_profile(user_id=user.id, profile_data=user.to_dict())
        
        return jsonify({'user': user.to_dict()})
        
    except Exception as e:
        logger.error(f"Update user failed: {str(e)}")
        return jsonify({'error': 'Failed to update user'}), 500