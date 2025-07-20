const io = require('socket.io-client');

// Test the exact same connection that iOS is trying to make
const token = 'eyJhbGciOiJSUzI1NiIsImtpZCI6ImE4ZGY2MmQzYTBhNDRlM2RmY2RjYWZjNmRhMTM4Mzc3NDU5ZjliMDEiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vY292ZS00MGQ5ZiIsImF1ZCI6ImNvdmUtNDBkOWYiLCJhdXRoX3RpbWUiOjE3NTMwMTU1OTYsInVzZXJfaWQiOiJvaVpQdERMc0huaGpHR0o2VWhjUmtxckpiV08yIiwic3ViIjoib2laUHRETHNIbmhqR0dKNlVoY1JrcXJKYldPMiIsImlhdCI6MTc1MzAxNTU5NiwiZXhwIjoxNzUzMDE5MTk2LCJwaG9uZV9udW1iZXIiOiIrMTkxNzM0MDYxMTgiLCJmaXJlYmFzZSI6eyJpZGVudGl0aWVzIjp7InBob25lIjpbIisxOTE3MzQwNjExOCJdfSwic2lnbl9pbl9wcm92aWRlciI6InBob25lIn19.DobK4FJG4DmZZbm25uvvQB-coH4LHY2pivAO7xxWky3ReWWihxNoquZOCkxMd5Ulq0a3DB1vvymZ-ndBzTza090D6ly2UTW6xfzHIUDCS_ZpuajD00zV5jQWcg_bxQ1N_6FrCw7MPL4Zu68Bb85RM4D9SyvxF8h7MC9oo7SvQFK2HpKSpZiFz0FtGR68Qerf2et7XCjIGuiMCKmjCVUcznJynnwdcnUm9BtBAbUrUeDb7qNtn4zSHHb8aWp2ooRJmcHphQo37Hea5yHAzIGOFYbus2gM_DAl8pz-G3rD2BYcqbwU_toiH-HDSeo9bsRaMTbTt4fof1JN9-2rYaB1oA';

console.log('🔍 Testing iOS WebSocket connection locally...');
console.log('URL: wss://socket.coveapp.co:3001');
console.log('Token: ' + token.substring(0, 50) + '...');
console.log('User ID: oiZPtDLsHnhjGGJ6UhcRkqrJbWO2');

// Test with query parameter (like iOS app)
const socketWithQuery = io('wss://socket.coveapp.co:3001', {
  transports: ['websocket'],
  timeout: 5000,
  forceNew: true,
  query: {
    token: token
  }
});

console.log('\n📡 Testing with query parameter (iOS style)...');

socketWithQuery.on('connect', () => {
  console.log('✅ SUCCESS: Connected with query parameter!');
  console.log('Socket ID:', socketWithQuery.id);
  console.log('Transport:', socketWithQuery.io.engine.transport.name);
  
  // Test a simple event
  socketWithQuery.emit('test', { message: 'Hello from iOS-style test!' });
  
  setTimeout(() => {
    socketWithQuery.disconnect();
    console.log('✅ Query parameter test completed successfully!');
    process.exit(0);
  }, 2000);
});

socketWithQuery.on('connect_error', (error) => {
  console.log('❌ FAILED: Query parameter connection failed:', error.message);
  
  // Try with auth parameter (Node.js style)
  console.log('\n📡 Testing with auth parameter (Node.js style)...');
  testWithAuth();
});

function testWithAuth() {
  const socketWithAuth = io('wss://socket.coveapp.co:3001', {
    transports: ['websocket'],
    timeout: 5000,
    forceNew: true,
    auth: {
      token: token
    }
  });

  socketWithAuth.on('connect', () => {
    console.log('✅ SUCCESS: Connected with auth parameter!');
    console.log('Socket ID:', socketWithAuth.id);
    console.log('Transport:', socketWithAuth.io.engine.transport.name);
    
    // Test a simple event
    socketWithAuth.emit('test', { message: 'Hello from auth-style test!' });
    
    setTimeout(() => {
      socketWithAuth.disconnect();
      console.log('✅ Auth parameter test completed successfully!');
      process.exit(0);
    }, 2000);
  });

  socketWithAuth.on('connect_error', (error) => {
    console.log('❌ FAILED: Auth parameter connection failed:', error.message);
    console.log('\n💡 Analysis:');
    console.log('- Both query and auth methods failed');
    console.log('- This suggests the server might be down or there\'s a network issue');
    console.log('- Check if the socket server is running on EC2');
    console.log('- Verify the domain socket.coveapp.co resolves correctly');
    process.exit(1);
  });
}

// Timeout after 15 seconds
setTimeout(() => {
  console.error('❌ Connection timeout');
  socketWithQuery.disconnect();
  process.exit(1);
}, 15000); 