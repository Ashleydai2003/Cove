const { io } = require('socket.io-client');

// Test WebSocket connection with authentication (supports both WS and WSS)
async function testWebSocketConnection() {
    console.log('🔒 Testing WebSocket connection...');
    
    // You'll need to replace this with a real Firebase ID token
    const firebaseToken = process.env.FIREBASE_TOKEN || 'your-firebase-token-here';
    
    if (firebaseToken === 'your-firebase-token-here') {
        console.log('❌ Please set FIREBASE_TOKEN environment variable with a real Firebase ID token');
        console.log('   You can get this from your iOS app or Firebase console');
        return;
    }
    
    // Use appropriate protocol based on environment
    const isProduction = process.env.NODE_ENV === 'production';
    const socketUrl = isProduction 
        ? 'wss://13.52.150.178:3001'
        : 'ws://13.52.150.178:3001';
    
    console.log(`🔗 Connecting to: ${socketUrl}`);
    console.log(`🌐 Environment: ${isProduction ? 'Production (WSS)' : 'Development (WS)'}`);
    
    const socket = io(socketUrl, {
        auth: {
            token: firebaseToken
        },
        transports: ['websocket'], // Force WebSocket transport for security
        rejectUnauthorized: false, // For self-signed certificates in testing
        timeout: 10000
    });

    socket.on('connect', () => {
        console.log('✅ WebSocket connected and authenticated successfully!');
        console.log(`🔒 Connection is ${isProduction ? 'encrypted and secure' : 'unencrypted (development)'}!`);
        console.log(`📡 Transport: ${socket.io.engine.transport.name}`);
        socket.disconnect();
    });

    socket.on('connect_error', (error) => {
        console.log('❌ WebSocket connection failed:', error.message);
        if (error.message.includes('Authentication failed')) {
            console.log('💡 This might be due to an invalid or expired Firebase token');
        } else if (error.message.includes('SSL') || error.message.includes('certificate')) {
            console.log('🔒 SSL certificate issue detected');
            console.log('💡 For development, you can use ws:// instead of wss://');
        } else if (error.message.includes('CORS')) {
            console.log('🌐 CORS issue detected - check allowed origins');
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

testWebSocketConnection(); 