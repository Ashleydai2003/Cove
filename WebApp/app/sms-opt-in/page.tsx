import { Metadata } from 'next';
import Image from 'next/image';

export const metadata: Metadata = {
  title: 'SMS Opt-in Documentation - Cove',
  description: '10DLC compliance documentation for SMS opt-in process',
  robots: 'noindex, nofollow', // Prevent search engine indexing
};

export default function SMSOptInDocumentation() {
  return (
    <div className="min-h-screen bg-[#FAF8F4] py-8">
      <div className="max-w-4xl mx-auto px-4">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-[#5E1C1D] mb-4">
            SMS Opt-in Documentation
          </h1>
          <p className="text-lg text-[#2D2D2D]">
            10DLC Compliance Documentation for Cove SMS Notifications
          </p>
          <p className="text-sm text-[#8B8B8B] mt-2">
            This page documents our SMS opt-in process for 10DLC compliance verification
          </p>
        </div>

        {/* Compliance Overview */}
        <div className="bg-white rounded-lg shadow-lg p-6 mb-8">
          <h2 className="text-2xl font-semibold text-[#5E1C1D] mb-4">
            ✅ 10DLC Compliance Status
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <h3 className="font-semibold text-[#5E1C1D]">Required Elements</h3>
              <ul className="text-sm space-y-1">
                <li>✅ Explicit consent checkbox</li>
                <li>✅ Clear program description</li>
                <li>✅ Message frequency disclosure</li>
                <li>✅ Data rates disclaimer</li>
                <li>✅ STOP instructions</li>
                <li>✅ HELP instructions</li>
                <li>✅ Terms & Privacy links</li>
              </ul>
            </div>
            <div className="space-y-2">
              <h3 className="font-semibold text-[#5E1C1D]">Compliance Codes</h3>
              <ul className="text-sm space-y-1">
                <li>✅ CR2017 - No SHAFT content</li>
                <li>✅ CR4005 - Message frequency disclosed</li>
                <li>✅ CR4006 - Data rates disclosed</li>
                <li>✅ CR4003 - HELP instructions included</li>
                <li>✅ CR4004 - STOP instructions included</li>
                <li>✅ CR1104 - Use case matches messages</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Screenshot Section */}
        <div className="bg-white rounded-lg shadow-lg p-6 mb-8">
          <h2 className="text-2xl font-semibold text-[#5E1C1D] mb-4">
            SMS Opt-in Interface Screenshot
          </h2>
          <p className="text-[#2D2D2D] mb-4">
            The following screenshot shows our SMS opt-in form with all required 10DLC compliance elements:
          </p>
          
          {/* Actual Screenshot */}
          <div className="border border-gray-200 rounded-lg overflow-hidden">
            <Image
              src="/sms-optin.png"
              alt="SMS Opt-in Form Screenshot showing 10DLC compliance elements"
              width={800}
              height={600}
              className="w-full h-auto"
              priority
            />
          </div>
          
          <div className="mt-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <h3 className="font-semibold text-blue-800 mb-2">Screenshot Analysis:</h3>
            <ul className="text-sm text-blue-700 space-y-1">
              <li>• <strong>Personal Information Fields:</strong> last name, birthdate, alma mater, graduation year</li>
              <li>• <strong>SMS Opt-in Section:</strong> Clearly marked as "sms notifications (optional)"</li>
              <li>• <strong>Program Description:</strong> "receive sms reminders about event updates from cove"</li>
              <li>• <strong>Consent Checkbox:</strong> Unchecked checkbox with full compliance text</li>
              <li>• <strong>Compliance Text:</strong> All required disclosures included in the consent statement</li>
              <li>• <strong>Terms & Privacy Links:</strong> Direct links to both pages</li>
            </ul>
          </div>
        </div>

        {/* Call-to-Action Text */}
        <div className="bg-white rounded-lg shadow-lg p-6 mb-8">
          <h2 className="text-2xl font-semibold text-[#5E1C1D] mb-4">
            SMS Opt-in Call-to-Action Text
          </h2>
          <div className="bg-[#F8F8F8] p-4 rounded-lg">
            <p className="text-sm text-[#2D2D2D] leading-relaxed">
              "By checking this box, you agree to receive SMS notifications from Cove about event updates and reminders. Message frequency varies and may include up to 3 messages per event. Message and data rates may apply. Reply STOP to unsubscribe or HELP for help. View our Terms & Privacy at https://www.coveapp.co/terms and https://www.coveapp.co/privacy"
            </p>
          </div>
          
          <div className="mt-4">
            <h3 className="font-semibold text-[#5E1C1D] mb-2">Compliance Elements Included:</h3>
            <ul className="text-sm space-y-1 text-[#2D2D2D]">
              <li>• <strong>Explicit Consent:</strong> "By checking this box, you agree to receive SMS notifications"</li>
              <li>• <strong>Program Description:</strong> "about event updates and reminders"</li>
              <li>• <strong>Message Frequency:</strong> "up to 3 messages per event"</li>
              <li>• <strong>Data Rates:</strong> "Message and data rates may apply"</li>
              <li>• <strong>STOP Instructions:</strong> "Reply STOP to unsubscribe"</li>
              <li>• <strong>HELP Instructions:</strong> "HELP for help"</li>
              <li>• <strong>Terms & Privacy:</strong> Direct links provided</li>
            </ul>
          </div>
        </div>

        {/* SMS Message Templates */}
        <div className="bg-white rounded-lg shadow-lg p-6 mb-8">
          <h2 className="text-2xl font-semibold text-[#5E1C1D] mb-4">
            SMS Message Templates
          </h2>
          
          <div className="space-y-6">
            <div>
              <h3 className="font-semibold text-[#5E1C1D] mb-2">RSVP Approved Message</h3>
              <div className="bg-[#F8F8F8] p-3 rounded-lg">
                <p className="text-sm text-[#2D2D2D]">
                  "Your RSVP to [Event Name] has been approved! Event details and guest list: [link]<br/><br/>
                  Reply STOP to opt out, HELP for help. Msg&data rates may apply."
                </p>
              </div>
            </div>

            <div>
              <h3 className="font-semibold text-[#5E1C1D] mb-2">RSVP Declined Message</h3>
              <div className="bg-[#F8F8F8] p-3 rounded-lg">
                <p className="text-sm text-[#2D2D2D]">
                  "Your RSVP to '[Event Name]' was declined. The event may be at capacity.<br/><br/>
                  Reply STOP to opt out, HELP for help. Msg&data rates may apply."
                </p>
              </div>
            </div>

            <div>
              <h3 className="font-semibold text-[#5E1C1D] mb-2">HELP Response</h3>
              <div className="bg-[#F8F8F8] p-3 rounded-lg">
                <p className="text-sm text-[#2D2D2D]">
                  "Cove SMS Help:<br/>
                  • RSVP confirmations and event updates<br/>
                  • Up to 3 msgs per event<br/>
                  • Reply STOP to unsubscribe<br/>
                  • Visit coveapp.co for support<br/><br/>
                  Msg&data rates may apply."
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Technical Implementation */}
        <div className="bg-white rounded-lg shadow-lg p-6 mb-8">
          <h2 className="text-2xl font-semibold text-[#5E1C1D] mb-4">
            Technical Implementation
          </h2>
          
          <div className="space-y-4">
            <div>
              <h3 className="font-semibold text-[#5E1C1D] mb-2">SMS Service Provider</h3>
              <p className="text-sm text-[#2D2D2D]">Sinch REST API with 10DLC compliance</p>
            </div>
            
            <div>
              <h3 className="font-semibold text-[#5E1C1D] mb-2">Webhook Security</h3>
              <ul className="text-sm text-[#2D2D2D] space-y-1">
                <li>• HMAC-SHA256 signature verification</li>
                <li>• Rate limiting (10 requests/minute per IP)</li>
                <li>• Input validation and sanitization</li>
                <li>• Exact phone number matching (E.164 format)</li>
              </ul>
            </div>
            
            <div>
              <h3 className="font-semibold text-[#5E1C1D] mb-2">Database Integration</h3>
              <ul className="text-sm text-[#2D2D2D] space-y-1">
                <li>• User opt-in status tracking</li>
                <li>• STOP keyword processing</li>
                <li>• HELP keyword responses</li>
                <li>• Message frequency limits</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Compliance Verification */}
        <div className="bg-green-50 border border-green-200 rounded-lg p-6">
          <h2 className="text-2xl font-semibold text-green-800 mb-4">
            ✅ 10DLC Compliance Verification
          </h2>
          <div className="space-y-2 text-sm text-green-700">
            <p>This documentation demonstrates full compliance with 10DLC requirements:</p>
            <ul className="list-disc list-inside space-y-1 ml-4">
              <li>Explicit user consent with clear program description</li>
              <li>Message frequency and data rates disclosures</li>
              <li>STOP and HELP keyword instructions</li>
              <li>Terms of Service and Privacy Policy links</li>
              <li>Secure webhook implementation</li>
              <li>Proper message templates matching declared use case</li>
            </ul>
          </div>
        </div>

        {/* Footer */}
        <div className="text-center mt-8 text-sm text-[#8B8B8B]">
          <p>Cove SMS Opt-in Documentation</p>
          <p>Generated: {new Date().toLocaleDateString()}</p>
          <p className="mt-2">
            <a href="/" className="text-[#5E1C1D] hover:underline">← Back to Cove</a>
          </p>
        </div>
      </div>
    </div>
  );
}