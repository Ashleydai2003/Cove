import express from 'express';
import cors from 'cors';
import { APIGatewayProxyEvent, Context } from 'aws-lambda';
import { handler } from './index';

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Convert Express request to Lambda event format
const createLambdaEvent = (req: express.Request): APIGatewayProxyEvent => {
  return {
    httpMethod: req.method,
    path: req.path,
    pathParameters: req.params,
    queryStringParameters: req.query as { [key: string]: string },
    headers: req.headers as { [key: string]: string },
    body: req.body ? JSON.stringify(req.body) : null,
    isBase64Encoded: false,
    multiValueHeaders: {},
    multiValueQueryStringParameters: {},
    stageVariables: {},
    resource: '',
    requestContext: {
      requestId: 'local-' + Date.now(),
      stage: 'local',
      resourceId: '',
      resourcePath: '',
      httpMethod: req.method,
      requestTime: new Date().toISOString(),
      requestTimeEpoch: Date.now(),
      path: req.path,
      accountId: '000000000000',
      protocol: 'HTTP/1.1',
      identity: {
        accessKey: null,
        accountId: null,
        apiKey: null,
        apiKeyId: null,
        caller: null,
        cognitoAuthenticationProvider: null,
        cognitoAuthenticationType: null,
        cognitoIdentityId: null,
        cognitoIdentityPoolId: null,
        principalOrgId: null,
        sourceIp: req.ip || '127.0.0.1',
        user: null,
        userAgent: req.get('user-agent') || '',
        userArn: null,
        clientCert: null
      },
      authorizer: null,
      apiId: 'local'
    }
  };
};

// Create mock Lambda context
const createLambdaContext = (): Context => {
  return {
    callbackWaitsForEmptyEventLoop: false,
    functionName: 'local-development',
    functionVersion: '$LATEST',
    invokedFunctionArn: 'arn:aws:lambda:local:000000000000:function:local-development',
    memoryLimitInMB: '512',
    awsRequestId: 'local-' + Date.now(),
    logGroupName: '/aws/lambda/local-development',
    logStreamName: 'local-stream',
    getRemainingTimeInMillis: () => 30000,
    done: () => {},
    fail: () => {},
    succeed: () => {}
  };
};

// Catch-all route to handle all API requests
app.all('*', async (req, res) => {
  try {
    // Convert Express request to Lambda event
    const lambdaEvent = createLambdaEvent(req);
    const lambdaContext = createLambdaContext();
    
    console.log(`Processing ${req.method} ${req.path}`);
    
    // Call the Lambda handler
    const result = await handler(lambdaEvent, lambdaContext);
    
    // Send Lambda response back through Express
    res.status(result.statusCode);
    
    // Set headers if they exist
    if (result.headers) {
      Object.entries(result.headers).forEach(([key, value]) => {
        res.set(key, value as string);
      });
    }
    
    // Send response body
    if (result.body) {
      try {
        const parsedBody = JSON.parse(result.body);
        res.json(parsedBody);
      } catch {
        res.send(result.body);
      }
    } else {
      res.end();
    }
    
  } catch (error) {
    console.error('Local server error:', error);
    res.status(500).json({
      message: 'Local server error',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Start the server
app.listen(PORT, () => {
  console.log(`🚀 Local development server running on http://localhost:${PORT}`);
  console.log(`📊 Available endpoints:`);
  console.log(`   GET  /test-database - Test database connection`);
  console.log(`   GET  /profile - Get user profile`);
  console.log(`   POST /login - User login`);
  console.log(`   POST /onboard - User onboarding`);
  console.log(`   POST /create-event - Create new event`);
  console.log(`   POST /create-cove - Create new cove`);
  console.log(`   ... and all other API endpoints`);
  console.log(`\n💡 Make sure your local database is running: npm run db:start`);
});

export default app; 