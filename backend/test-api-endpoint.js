const axios = require('axios');

async function testAPIEndpoint() {
  try {
    console.log('🔍 Testing API endpoint...');
    
    // Step 1: Login to get token
    console.log('1. Logging in...');
    const loginResponse = await axios.post('http://localhost:3001/api/auth/login', {
      email: 'simon@test.com',
      password: 'password123'
    });
    
    const token = loginResponse.data.token;
    console.log('✅ Login successful, token received');
    
    // Step 2: Test match creation
    console.log('2. Testing match creation...');
    const matchData = {
      offerSkillId: '6f27bb44-cb32-4539-bd60-1d5d90af1c1d',
      requestSkillId: '98df40eb-4e8e-4663-b0a7-00134f8a4d84',
      message: 'Test match creation'
    };
    
    const matchResponse = await axios.post('http://localhost:3001/api/matches', matchData, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Match creation successful!');
    console.log('Response:', matchResponse.data);
    
  } catch (error) {
    console.error('❌ Error occurred:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
      console.error('Headers:', error.response.headers);
    } else if (error.request) {
      console.error('Request error:', error.request);
    } else {
      console.error('Error:', error.message);
    }
  }
}

testAPIEndpoint();
