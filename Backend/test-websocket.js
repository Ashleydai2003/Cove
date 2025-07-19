const { io } = require('socket.io-client');

// Test WebSocket connection
async function testWebSocket() {
    console.log('🧪 Testing WebSocket connection...');
    
    const socket = io('ws://54.215.105.249:3001', {
        auth: {
            token: 'test-token' // This will fail auth, but we can test connection
        }
    });

    socket.on('connect', () => {
        console.log('✅ WebSocket connected successfully!');
        socket.disconnect();
    });

    socket.on('connect_error', (error) => {
        console.log('❌ WebSocket connection failed:', error.message);
    });

    socket.on('disconnect', () => {
        console.log('🔌 WebSocket disconnected');
    });

    // Timeout after 10 seconds
    setTimeout(() => {
        console.log('⏰ Test timeout - server might still be starting');
        socket.disconnect();
        process.exit(0);
    }, 10000);
}

testWebSocket(); 