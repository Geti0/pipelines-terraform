document.getElementById('contactForm').addEventListener('submit', async function(e) {
  e.preventDefault();
  const name = document.getElementById('name').value;
  const email = document.getElementById('email').value;
  const message = document.getElementById('message').value;
  const responseDiv = document.getElementById('response');

  try {
    const res = await fetch("YOUR_API_GATEWAY_URL", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, email, message })
    });
    const data = await res.json();
    if (data.success) {
      responseDiv.textContent = "Message sent successfully!";
    } else {
      responseDiv.textContent = "Error sending message.";
    }
  } catch (err) {
    responseDiv.textContent = "Error: " + err.message;
  }
});
