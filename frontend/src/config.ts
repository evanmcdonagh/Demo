/**
 * API Configuration
 * 
 * To connect to your deployed AWS API:
 * 1. Deploy your backend to AWS
 * 2. Get the API Gateway URL from the deployment output
 * 3. Update the API_BASE_URL below with your API URL
 * 
 * Example: https://abc123.execute-api.us-east-1.amazonaws.com/prod
 */

export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

export const config = {
  apiBaseUrl: API_BASE_URL,
};
