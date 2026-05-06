const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors()); // Allows your React app to make requests here
app.use(express.json());

// 1. Health Check Endpoint (Required for Cloud Deployment)
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// 2. Data Endpoint
app.get('/api/message', (req, res) => {
    res.json({ message: 'Hello from the Express Backend!' });
});

app.listen(PORT, '0.0.0.0', () => { // 0.0.0.0 is required for Docker
    console.log(`Backend server is running on port ${PORT}`);
});