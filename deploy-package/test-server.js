const { spawn } = require('child_process');

console.log('Starting SkillLink server...');

const server = spawn('node', ['src/server.js'], {
  stdio: 'inherit',
  shell: true
});

server.on('error', (error) => {
  console.error('Failed to start server:', error);
});

server.on('close', (code) => {
  console.log(`Server process exited with code ${code}`);
});

// Wait 10 seconds then test the health endpoint
setTimeout(() => {
  console.log('\nTesting server health endpoint...');
  const test = spawn('curl', ['http://localhost:3001/api/health'], {
    stdio: 'inherit',
    shell: true
  });
  
  test.on('error', (error) => {
    console.error('Health check failed:', error);
  });
}, 10000);

