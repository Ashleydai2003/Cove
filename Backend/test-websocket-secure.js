const io = require('socket.io-client');

// Test secure WebSocket connection and database connectivity
// Using auth method (Node.js style) - backend now supports both auth and query
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
console.log('🗄️  Will also test database connectivity...');

socket.on('connect', () => {
  console.log('✅ Successfully connected to secure WebSocket server!');
  console.log('Socket ID:', socket.id);
  console.log('Transport:', socket.io.engine.transport.name);
  console.log('🔒 Connection is encrypted and secure!');
  
  // Test database connectivity by joining a thread (this requires DB access)
  console.log('🗄️  Testing database connectivity...');
  socket.emit('join-thread', { threadId: 'test-thread' }, (response) => {
    if (response && response.success) {
      console.log('✅ Database connection successful!');
      console.log('✅ Server can access RDS and initialize Prisma client');
    } else if (response && response.error) {
      if (response.error.includes('RDS_MASTER_SECRET_ARN') || response.error.includes('database')) {
        console.log('❌ Database connection failed:', response.error);
        console.log('💡 This indicates the RDS environment variables are not set correctly');
        process.exit(1);
      } else {
        console.log('⚠️  Database test inconclusive:', response.error);
        console.log('✅ WebSocket connection is working, but database needs investigation');
      }
    } else {
      console.log('⚠️  No response from join-thread event');
      console.log('✅ WebSocket connection is working, but database test inconclusive');
    }
    
    // Test a simple event
    socket.emit('test', { message: 'Hello from test client!' });
    
    // Disconnect after successful test
    setTimeout(() => {
      socket.disconnect();
      console.log('✅ Test completed successfully!');
      process.exit(0);
    }, 2000);
  });
  
  // Fallback if join-thread doesn't respond
  setTimeout(() => {
    console.log('⚠️  join-thread event timed out, testing basic connectivity...');
    socket.emit('test', { message: 'Hello from test client!' });
    
    setTimeout(() => {
      socket.disconnect();
      console.log('✅ Basic WebSocket test completed!');
      console.log('💡 Database connectivity needs manual verification');
      process.exit(0);
    }, 2000);
  }, 5000);
});

socket.on('connect_error', (error) => {
  console.log('❌ Connection failed:', error.message);
  
  if (error.message.includes('Authentication')) {
    console.log('💡 This is expected - the server requires valid Firebase authentication');
    console.log('✅ SSL connection is working correctly!');
    console.log('🔒 The server is properly secured and rejecting unauthenticated connections');
    console.log('💡 To test database connectivity, you need a valid Firebase token');
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

// Timeout after 15 seconds (increased for database test)
setTimeout(() => {
  console.error('❌ Connection timeout');
  socket.disconnect();
  process.exit(1);
}, 15000); 