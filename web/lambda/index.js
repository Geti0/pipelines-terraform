// Lambda function for contact form processing
const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    // Set CORS headers
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
    };

    try {
        // Handle preflight requests
        if (event.httpMethod === 'OPTIONS') {
            return {
                statusCode: 200,
                headers,
                body: ''
            };
        }

        // Only allow POST requests
        if (event.httpMethod !== 'POST') {
            return {
                statusCode: 405,
                headers,
                body: JSON.stringify({
                    success: false,
                    message: 'Method not allowed'
                })
            };
        }

        // Parse the request body
        let body;
        try {
            body = JSON.parse(event.body);
        } catch {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    message: 'Invalid JSON in request body'
                })
            };
        }

        // Trim the input fields first
        const name = body.name ? body.name.trim() : '';
        const email = body.email ? body.email.trim().toLowerCase() : '';
        const message = body.message ? body.message.trim() : '';

        // Validate required fields
        if (!name || !email || !message) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    message: 'Missing required fields: name, email, and message are required'
                })
            };
        }

        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({
                    success: false,
                    message: 'Invalid email format'
                })
            };
        }

        // Create the item for DynamoDB
        const item = {
            id: uuidv4(),
            name: name,
            email: email,
            message: message,
            created_at: new Date().toISOString()
        };

        // Store in DynamoDB
        await dynamodb.put({
            TableName: process.env.DYNAMODB_TABLE,
            Item: item
        }).promise();

        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                success: true,
                message: 'Contact form submitted successfully',
                id: item.id
            })
        };

    } catch (error) {
        console.error('Error processing contact form:', error);

        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                success: false,
                message: 'Internal server error'
            })
        };
    }
};
