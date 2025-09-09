// Lambda function for contact form processing
const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();
const { v4: uuidv4 } = require('uuid');

exports.handler = async (event) => {
  const body = JSON.parse(event.body);
  const item = {
    id: uuidv4(),
    name: body.name,
    email: body.email,
    message: body.message,
    created_at: new Date().toISOString()
  };
  await dynamodb.put({
    TableName: process.env.DYNAMODB_TABLE,
    Item: item
  }).promise();
  return {
    statusCode: 200,
    body: JSON.stringify({ success: true })
  };
};
