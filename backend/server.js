const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors());
app.use(express.json());

// Add structured logging for visibility (Crucial for production!)
app.use(morgan('combined'));

// 1. Health Check Endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// 2. Data Endpoint
app.get('/api/message', (req, res) => {
    res.json({ message: 'Hello from the Express Backend!' });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Backend server is running on port ${PORT}`);
});