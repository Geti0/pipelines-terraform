// Use a fallback for import.meta in test environments
const getApiUrl = () => {
  try {
    return import.meta.env.VITE_API_GATEWAY_URL || 'https://pdytikgkcc.execute-api.eu-north-1.amazonaws.com/prod/contact';
  } catch (e) {
    return 'https://pdytikgkcc.execute-api.eu-north-1.amazonaws.com/prod/contact';
  }
};

document.getElementById('contactForm').addEventListener('submit', async function(e) {
  e.preventDefault();
  const name = document.getElementById('name').value.trim();
  const email = document.getElementById('email').value.trim();
  const message = document.getElementById('message').value.trim();
  const responseDiv = document.getElementById('response');

  // Client-side validation
  if (!name || !email || !message) {
    responseDiv.textContent = 'Please fill in all fields.';
    responseDiv.style.color = 'red';
    return;
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    responseDiv.textContent = 'Please enter a valid email address.';
    responseDiv.style.color = 'red';
    return;
  }

  responseDiv.textContent = 'Sending...';
  responseDiv.style.color = 'blue';

  try {
    const res = await fetch(getApiUrl(), {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({ name, email, message })
    });
    
    const data = await res.json();
    
    if (res.ok && data.success) {
      responseDiv.textContent = 'Message sent successfully! Thank you for contacting us.';
      responseDiv.style.color = 'green';
      document.getElementById('contactForm').reset();
    } else {
      responseDiv.textContent = data.message || 'Error sending message. Please try again.';
      responseDiv.style.color = 'red';
    }
  } catch (err) {
    console.error('Error:', err);
    responseDiv.textContent = 'Network error. Please check your connection and try again.';
    responseDiv.style.color = 'red';
  }
});
