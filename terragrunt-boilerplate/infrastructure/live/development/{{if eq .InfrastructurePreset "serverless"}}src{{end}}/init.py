import json
import boto3
import pymysql
import os
import logging
from datetime import datetime
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

secrets_client = boto3.client('secretsmanager')

def get_secret():
    """Retrieve database credentials from AWS Secrets Manager"""
    secret_arn = os.environ['SECRET_ARN']
    
    try:
        response = secrets_client.get_secret_value(SecretId=secret_arn)
        return json.loads(response['SecretString'])
    except ClientError as e:
        logger.error(f"Error retrieving secret: {e}")
        raise e

def get_db_connection():
    """Create database connection using credentials from Secrets Manager"""
    try:
        db_credentials = get_secret()
        
        connection = pymysql.connect(
            host=db_credentials['host'],
            user=db_credentials['username'],
            password=db_credentials['password'],
            database=db_credentials['dbname'],
            port=int(db_credentials['port']),
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=True
        )
        
        logger.info("Database connection established successfully")
        return connection
        
    except Exception as e:
        logger.error(f"Error connecting to database: {e}")
        raise e

def create_response(status_code, body, headers=None):
    """Create standardized API response"""
    if headers is None:
        headers = {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, X-Amz-Date, Authorization, X-Api-Key, X-Amz-Security-Token'
        }
    
    return {
        'statusCode': status_code,
        'headers': headers,
        'body': json.dumps(body) if isinstance(body, (dict, list)) else body
    }

def handle_get_users(connection):
    """Handle GET /users - retrieve all users"""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT id, name, email, created_at FROM users ORDER BY created_at DESC")
            users = cursor.fetchall()
            
        return create_response(200, {
            'success': True,
            'data': users,
            'count': len(users)
        })
        
    except Exception as e:
        logger.error(f"Error retrieving users: {e}")
        return create_response(500, {
            'success': False,
            'error': 'Failed to retrieve users'
        })

def handle_create_user(connection, user_data):
    """Handle POST /users - create new user"""
    try:
        if not user_data.get('name') or not user_data.get('email'):
            return create_response(400, {
                'success': False,
                'error': 'Name and email are required'
            })
        
        with connection.cursor() as cursor:
            cursor.execute("SELECT id FROM users WHERE email = %s", (user_data['email'],))
            if cursor.fetchone():
                return create_response(409, {
                    'success': False,
                    'error': 'Email already exists'
                })
            
            cursor.execute(
                "INSERT INTO users (name, email) VALUES (%s, %s)",
                (user_data['name'], user_data['email'])
            )
            user_id = cursor.lastrowid
            
            cursor.execute("SELECT id, name, email, created_at FROM users WHERE id = %s", (user_id,))
            new_user = cursor.fetchone()
            
        return create_response(201, {
            'success': True,
            'data': new_user,
            'message': 'User created successfully'
        })
        
    except Exception as e:
        logger.error(f"Error creating user: {e}")
        return create_response(500, {
            'success': False,
            'error': 'Failed to create user'
        })

def handle_health_check():
    """Handle GET /health - health check endpoint"""
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        connection.close()
        
        return create_response(200, {
            'success': True,
            'status': 'healthy',
            'timestamp': str(datetime.utcnow()),
            'environment': os.environ.get('ENVIRONMENT', 'unknown'),
            'version': '1.0.0'
        })
        
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return create_response(503, {
            'success': False,
            'status': 'unhealthy',
            'error': 'Database connection failed'
        })

def lambda_handler(event, context):
    """Main Lambda handler function"""
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        http_method = event.get('httpMethod') or event.get('requestContext', {}).get('http', {}).get('method')
        path = event.get('path') or event.get('requestContext', {}).get('http', {}).get('path', '/')
        
        if http_method == 'OPTIONS':
            return create_response(200, '')
        
        if path == '/health':
            return handle_health_check()
        
        connection = get_db_connection()
        
        try:
            if path == '/users' or path == '/':
                if http_method == 'GET':
                    return handle_get_users(connection)
                elif http_method == 'POST':
                    body = event.get('body', '{}')
                    if isinstance(body, str):
                        body = json.loads(body) if body else {}
                    return handle_create_user(connection, body)
                else:
                    return create_response(405, {
                        'success': False,
                        'error': 'Method not allowed'
                    })
            else:
                return create_response(404, {
                    'success': False,
                    'error': 'Route not found'
                })
                
        finally:
            connection.close()
            
    except Exception as e:
        logger.error(f"Unhandled error: {e}")
        return create_response(500, {
            'success': False,
            'error': 'Internal server error'
        })

if __name__ == "__main__":
    test_event = {
        'httpMethod': 'GET',
        'path': '/health',
        'headers': {},
        'body': None
    }
    
    class MockContext:
        def __init__(self):
            self.function_name = 'test-function'
            self.aws_request_id = 'test-request-id'
    
    result = lambda_handler(test_event, MockContext())
    print(json.dumps(result, indent=2))