// Mock AWS SDK
const mockPut = jest.fn();

// Mock AWS SDK before requiring the handler
jest.mock('aws-sdk', () => ({
  DynamoDB: {
    DocumentClient: jest.fn(() => ({
      put: mockPut
    }))
  }
}));

// Mock uuid
jest.mock('uuid', () => ({
  v4: jest.fn(() => 'test-uuid-123')
}));

const { handler } = require('./index');

describe('Contact Form Lambda Handler', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.DYNAMODB_TABLE = 'test-contact-table';
    
    // Mock successful DynamoDB put
    mockPut.mockReturnValue({
      promise: jest.fn().mockResolvedValue({})
    });
  });

  afterEach(() => {
    delete process.env.DYNAMODB_TABLE;
  });

  test('should handle OPTIONS request (CORS preflight)', async () => {
    const event = {
      httpMethod: 'OPTIONS'
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(200);
    expect(response.headers['Access-Control-Allow-Origin']).toBe('*');
    expect(response.headers['Access-Control-Allow-Methods']).toBe('OPTIONS,POST,GET');
  });

  test('should successfully process valid contact form submission', async () => {
    const event = {
      httpMethod: 'POST',
      body: JSON.stringify({
        name: 'John Doe',
        email: 'john@example.com',
        message: 'Hello, this is a test message'
      })
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(200);
    expect(mockPut).toHaveBeenCalledWith({
      TableName: 'test-contact-table',
      Item: {
        id: 'test-uuid-123',
        name: 'John Doe',
        email: 'john@example.com',
        message: 'Hello, this is a test message',
        created_at: expect.any(String)
      }
    });

    const responseBody = JSON.parse(response.body);
    expect(responseBody.success).toBe(true);
    expect(responseBody.id).toBe('test-uuid-123');
  });

  test('should return 405 for non-POST/OPTIONS methods', async () => {
    const event = {
      httpMethod: 'GET'
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(405);
    const responseBody = JSON.parse(response.body);
    expect(responseBody.success).toBe(false);
    expect(responseBody.message).toBe('Method not allowed');
  });

  test('should return 400 for missing required fields', async () => {
    const event = {
      httpMethod: 'POST',
      body: JSON.stringify({
        name: 'John Doe',
        // missing email and message
      })
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(400);
    const responseBody = JSON.parse(response.body);
    expect(responseBody.success).toBe(false);
    expect(responseBody.message).toContain('Missing required fields');
  });

  test('should return 400 for invalid email format', async () => {
    const event = {
      httpMethod: 'POST',
      body: JSON.stringify({
        name: 'John Doe',
        email: 'invalid-email',
        message: 'Test message'
      })
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(400);
    const responseBody = JSON.parse(response.body);
    expect(responseBody.success).toBe(false);
    expect(responseBody.message).toBe('Invalid email format');
  });

  test('should return 400 for invalid JSON', async () => {
    const event = {
      httpMethod: 'POST',
      body: 'invalid json'
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(400);
    const responseBody = JSON.parse(response.body);
    expect(responseBody.success).toBe(false);
    expect(responseBody.message).toBe('Invalid JSON in request body');
  });

  test('should handle DynamoDB errors', async () => {
    mockPut.mockReturnValue({
      promise: jest.fn().mockRejectedValue(new Error('DynamoDB error'))
    });

    const event = {
      httpMethod: 'POST',
      body: JSON.stringify({
        name: 'John Doe',
        email: 'john@example.com',
        message: 'Test message'
      })
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(500);
    const responseBody = JSON.parse(response.body);
    expect(responseBody.success).toBe(false);
    expect(responseBody.message).toBe('Internal server error');
  });

  test('should trim whitespace from input fields', async () => {
    // Reset mock for this test
    mockPut.mockReturnValue({
      promise: jest.fn().mockResolvedValue({})
    });

    const event = {
      httpMethod: 'POST',
      body: JSON.stringify({
        name: '  John Doe  ',
        email: '  john@example.com  ',
        message: '  Hello, this is a test message  '
      })
    };

    const response = await handler(event);
    
    // Debug: log the actual response
    if (response.statusCode !== 200) {
      console.log('Actual response:', response);
    }

    expect(response.statusCode).toBe(200);
    expect(mockPut).toHaveBeenCalledWith({
      TableName: 'test-contact-table',
      Item: {
        id: 'test-uuid-123',
        name: 'John Doe',
        email: 'john@example.com',
        message: 'Hello, this is a test message',
        created_at: expect.any(String)
      }
    });
  });
});
