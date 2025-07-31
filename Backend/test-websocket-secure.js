const io = require('socket.io-client');

// Test secure WebSocket connection
const socket = io('wss://socket.coveapp.co:3001', {
  transports: ['websocket'],
  timeout: 5000,
  forceNew: true,
  auth: {
    token: process.env.FIREBASE_TOKEN || 'test-token'
  }
});

console.log('🔒 Testing secure WebSocket connection...');
console.log('URL: wss://socket.coveapp.co:3001');
console.log('🔐 Authentication: ' + (process.env.FIREBASE_TOKEN ? 'Using Firebase token' : 'Using test token'));

socket.on('connect', () => {
  console.log('✅ Successfully connected to secure WebSocket server!');
  console.log('Socket ID:', socket.id);
  console.log('Transport:', socket.io.engine.transport.name);
  console.log('🔒 Connection is encrypted and secure!');
  
  // Test a simple event
  socket.emit('test', { message: 'Hello from test client!' });
  
  // Disconnect after successful test
  setTimeout(() => {
    socket.disconnect();
    console.log('✅ Test completed successfully!');
    process.exit(0);
  }, 2000);
});

socket.on('connect_error', (error) => {
  console.log('❌ Connection failed:', error.message);
  
  if (error.message.includes('Authentication')) {
    console.log('💡 This is expected - the server requires valid Firebase authentication');
    console.log('✅ SSL connection is working correctly!');
    console.log('🔒 The server is properly secured and rejecting unauthenticated connections');
    process.exit(0); // This is actually a success for our SSL test
  } else if (error.message.includes('SSL') || error.message.includes('certificate')) {
    console.error('❌ SSL certificate issue:', error.message);
    process.exit(1);
  } else if (error.message.includes('timeout')) {
    console.error('❌ Connection timeout - server might be down');
    process.exit(1);
  } else {
    console.error('❌ Unexpected error:', error.message);
    process.exit(1);
  }
});

socket.on('error', (error) => {
  console.error('❌ Socket error:', error);
  process.exit(1);
});

// Timeout after 10 seconds
setTimeout(() => {
  console.error('❌ Connection timeout');
  socket.disconnect();
  process.exit(1);
}, 10000); 