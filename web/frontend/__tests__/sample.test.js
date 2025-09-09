/**
 * @jest-environment jsdom
 */

// Mock fetch globally
global.fetch = jest.fn();

// Import the contact.js functionality by requiring it
const fs = require('fs');
const path = require('path');

// Load the contact.js file content
const contactJsPath = path.join(__dirname, '../contact.js');
const contactJsContent = fs.readFileSync(contactJsPath, 'utf8');

describe('Contact Form Tests', () => {
  beforeEach(() => {
    // Set up DOM
    document.body.innerHTML = `
      <form id="contactForm">
        <input type="text" id="name" name="name" required>
        <input type="email" id="email" name="email" required>
        <textarea id="message" name="message" required></textarea>
        <button type="submit">Send</button>
      </form>
      <div id="response"></div>
    `;
    
    // Clear all mocks
    jest.clearAllMocks();
    
    // Execute the contact.js script in the test environment
    eval(contactJsContent);
  });

  test('should show error for empty form submission', async () => {
    const form = document.getElementById('contactForm');
    const responseDiv = document.getElementById('response');
    
    // Submit empty form
    const event = new Event('submit');
    form.dispatchEvent(event);
    
    expect(responseDiv.textContent).toContain('Please fill in all fields');
    expect(responseDiv.style.color).toBe('red');
  });

  test('should show error for invalid email', async () => {
    const form = document.getElementById('contactForm');
    const responseDiv = document.getElementById('response');
    
    // Fill form with invalid email
    document.getElementById('name').value = 'John Doe';
    document.getElementById('email').value = 'invalid-email';
    document.getElementById('message').value = 'Test message';
    
    // Submit form
    const event = new Event('submit');
    form.dispatchEvent(event);
    
    expect(responseDiv.textContent).toContain('valid email address');
    expect(responseDiv.style.color).toBe('red');
  });

  test('should successfully submit valid form', async () => {
    // Mock successful API response
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ success: true, message: 'Message sent successfully' })
    });

    const form = document.getElementById('contactForm');
    const responseDiv = document.getElementById('response');
    
    // Fill form with valid data
    document.getElementById('name').value = 'John Doe';
    document.getElementById('email').value = 'john@example.com';
    document.getElementById('message').value = 'Test message';
    
    // Submit form
    const event = new Event('submit');
    form.dispatchEvent(event);
    
    // Wait for async operations
    await new Promise(resolve => setTimeout(resolve, 0));
    
    expect(global.fetch).toHaveBeenCalledWith(
      'API_GATEWAY_URL_PLACEHOLDER',
      expect.objectContaining({
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          name: 'John Doe',
          email: 'john@example.com',
          message: 'Test message'
        })
      })
    );
  });

  test('should handle API errors gracefully', async () => {
    // Mock API error response
    global.fetch.mockResolvedValueOnce({
      ok: false,
      json: async () => ({ success: false, message: 'Server error' })
    });

    const form = document.getElementById('contactForm');
    const responseDiv = document.getElementById('response');
    
    // Fill form with valid data
    document.getElementById('name').value = 'John Doe';
    document.getElementById('email').value = 'john@example.com';
    document.getElementById('message').value = 'Test message';
    
    // Submit form
    const event = new Event('submit');
    form.dispatchEvent(event);
    
    // Wait for async operations
    await new Promise(resolve => setTimeout(resolve, 0));
    
    expect(responseDiv.style.color).toBe('red');
  });

  test('should handle network errors', async () => {
    // Mock network error
    global.fetch.mockRejectedValueOnce(new Error('Network error'));

    const form = document.getElementById('contactForm');
    const responseDiv = document.getElementById('response');
    
    // Fill form with valid data
    document.getElementById('name').value = 'John Doe';
    document.getElementById('email').value = 'john@example.com';
    document.getElementById('message').value = 'Test message';
    
    // Submit form
    const event = new Event('submit');
    form.dispatchEvent(event);
    
    // Wait for async operations
    await new Promise(resolve => setTimeout(resolve, 0));
    
    expect(responseDiv.textContent).toContain('Network error');
    expect(responseDiv.style.color).toBe('red');
  });

  test('should trim whitespace from form inputs', async () => {
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ success: true })
    });

    const form = document.getElementById('contactForm');
    
    // Fill form with whitespace-padded data
    document.getElementById('name').value = '  John Doe  ';
    document.getElementById('email').value = '  john@example.com  ';
    document.getElementById('message').value = '  Test message  ';
    
    // Submit form
    const event = new Event('submit');
    form.dispatchEvent(event);
    
    // Wait for async operations
    await new Promise(resolve => setTimeout(resolve, 0));
    
    expect(global.fetch).toHaveBeenCalledWith(
      'API_GATEWAY_URL_PLACEHOLDER',
      expect.objectContaining({
        body: JSON.stringify({
          name: 'John Doe',
          email: 'john@example.com',
          message: 'Test message'
        })
      })
    );
  });
});

// Basic math tests to ensure Jest is working
test('adds 1 + 1 to equal 2', () => {
  expect(1 + 1).toBe(2);
});

test('adds 1 + 2 to equal 3', () => {
  expect(1 + 2).toBe(3);
});
