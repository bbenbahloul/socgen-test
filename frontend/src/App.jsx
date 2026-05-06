import { useState, useEffect } from 'react'

function App() {
  const [message, setMessage] = useState('Loading...');
  const [health, setHealth] = useState('Checking...');

  useEffect(() => {
    // In a real app, use environment variables for the API URL
    const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8081';

    // Fetch Health
    fetch(`${apiUrl}/health`)
      .then(res => res.json())
      .then(data => setHealth(data.status))
      .catch(() => setHealth('unhealthy'));

    // Fetch Message
    fetch(`${apiUrl}/api/message`)
      .then(res => res.json())
      .then(data => setMessage(data.message))
      .catch(() => setMessage('Error fetching data'));
  }, []);

  return (
    <div style={{ padding: '2rem', fontFamily: 'sans-serif' }}>
      <h1>Technical Test Application</h1>
      <div style={{ padding: '1rem', border: '1px solid #ccc', borderRadius: '8px' }}>
        <p><strong>Backend Message:</strong> {message}</p>
        <p><strong>Backend Health:</strong> {health}</p>
      </div>
    </div>
  )
}

export default App