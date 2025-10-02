export default function TmpPage() {
  
  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg shadow-lg p-8 max-w-md w-full">
        <h1 className="text-2xl font-bold text-gray-800 mb-6 text-center">
          Temporary Image Endpoint
        </h1>
        
        <div className="space-y-4">
          <div className="text-center">
            <img 
              src="/proof.png" 
              alt="Proof image" 
              className="w-full h-64 object-cover rounded-lg border-2 border-gray-200"
            />
          </div>
          
          <div className="text-center text-sm text-gray-600">
            <p>Endpoint: <code className="bg-gray-100 px-2 py-1 rounded">coveapp.co/tmp</code></p>
            <p className="mt-2">This is a temporary testing endpoint</p>
          </div>
          
          {/* SMS Opt-in Information */}
          <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <h3 className="text-lg font-semibold text-blue-800 mb-3">SMS Opt-in During Onboarding</h3>
            <div className="text-sm text-blue-700 space-y-2">
              <p><strong>When users click "Login" and create an account:</strong></p>
              <ul className="list-disc list-inside space-y-1 ml-4">
                <li>Users go through phone number verification (OTP)</li>
                <li>During onboarding, there's a <strong>required SMS opt-in checkbox</strong></li>
                <li>Users must consent to receive SMS notifications from Cove</li>
                <li>This enables event reminders, RSVP confirmations, and updates</li>
                <li>Opt-in is mandatory - users cannot complete onboarding without it</li>
              </ul>
              <p className="mt-3 text-xs text-blue-600">
                <strong>Note:</strong> SMS consent is required by Twilio's terms of service for sending messages.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
