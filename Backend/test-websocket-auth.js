const { io } = require('socket.io-client');

// Test WebSocket connection with real authentication
async function testWebSocketAuth() {
    console.log('🧪 Testing WebSocket connection with authentication...');
    
    // You'll need to replace this with a real Firebase ID token
    const firebaseToken = process.env.FIREBASE_TOKEN || 'your-firebase-token-here';
    
    if (firebaseToken === 'your-firebase-token-here') {
        console.log('❌ Please set FIREBASE_TOKEN environment variable with a real Firebase ID token');
        console.log('   You can get this from your iOS app or Firebase console');
        return;
    }
    
    const socket = io('ws://13.52.150.178:3001', {
        auth: {
            token: firebaseToken
        }
    });

    socket.on('connect', () => {
        console.log('✅ WebSocket connected and authenticated successfully!');
        console.log('🎉 Socket.io server is working properly!');
        socket.disconnect();
    });

    socket.on('connect_error', (error) => {
        console.log('❌ WebSocket connection failed:', error.message);
        if (error.message.includes('Authentication failed')) {
            console.log('💡 This might be due to an invalid or expired Firebase token');
        }
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

testWebSocketAuth(); 