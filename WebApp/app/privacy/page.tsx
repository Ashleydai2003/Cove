'use client';

import { Libre_Bodoni } from 'next/font/google';

const libreBodoni = Libre_Bodoni({ 
  subsets: ['latin'],
  weight: ['400', '600', '700'],
  variable: '--font-libre-bodoni'
});

export default function PrivacyPolicy() {
  return (
    <div className={`${libreBodoni.variable} font-libre-bodoni min-h-screen bg-[#F5F0E6] text-[#2D2D2D]`}>
      <div className="max-w-4xl mx-auto px-4 py-12">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-6xl font-bold text-[#5E1C1D] mb-4">cove</h1>
          <h2 className="text-3xl font-semibold text-[#5E1C1D]">Privacy Policy</h2>
          <p className="text-lg text-[#8B8B8B] mt-2">Last updated: {new Date().toLocaleDateString()}</p>
        </div>

        {/* Content */}
        <div className="prose prose-lg max-w-none">
          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">1. Introduction</h3>
            <p className="mb-4">
              Cove ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our web application and services.
            </p>
            <p className="mb-4">
              By using Cove, you consent to the data practices described in this policy. If you do not agree with the terms of this Privacy Policy, please do not use our services.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">2. Information We Collect</h3>
            
            <h4 className="text-xl font-semibold text-[#5E1C1D] mb-3">2.1 Personal Information</h4>
            <p className="mb-4">We collect the following personal information when you create an account and use our services:</p>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>Contact Information:</strong> Phone number (for authentication and SMS notifications)</li>
              <li><strong>Identity Information:</strong> First name, last name, birthdate</li>
              <li><strong>Educational Information:</strong> University/college name, graduation year</li>
              <li><strong>Personal Preferences:</strong> Hobbies and interests</li>
              <li><strong>Location Information:</strong> City (if provided during registration)</li>
            </ul>

            <h4 className="text-xl font-semibold text-[#5E1C1D] mb-3">2.2 Automatically Collected Information</h4>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>Device Information:</strong> Browser type, operating system, device identifiers</li>
              <li><strong>Usage Data:</strong> Pages visited, time spent on site, interactions with features</li>
              <li><strong>Analytics Data:</strong> Firebase Analytics data (anonymized)</li>
              <li><strong>Cookies and Local Storage:</strong> Session data, preferences, authentication tokens</li>
            </ul>

            <h4 className="text-xl font-semibold text-[#5E1C1D] mb-3">2.3 Event-Related Information</h4>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>RSVP Data:</strong> Event attendance status, payment information (if applicable)</li>
              <li><strong>Event Interactions:</strong> Comments, photos, check-ins</li>
              <li><strong>Social Connections:</strong> Friends, cove memberships, event participation</li>
            </ul>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">3. How We Use Your Information</h3>
            <p className="mb-4">We use your information for the following purposes:</p>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>Service Provision:</strong> To provide and maintain our event platform and social features</li>
              <li><strong>Authentication:</strong> To verify your identity and secure your account</li>
              <li><strong>Communication:</strong> To send you SMS notifications about events and important updates (with your consent)</li>
              <li><strong>Personalization:</strong> To customize your experience and suggest relevant events</li>
              <li><strong>Analytics:</strong> To understand how our service is used and improve functionality</li>
              <li><strong>Safety and Security:</strong> To prevent fraud, abuse, and ensure platform safety</li>
              <li><strong>Legal Compliance:</strong> To comply with applicable laws and regulations</li>
            </ul>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">4. Third-Party Services</h3>
            <p className="mb-4">We use the following third-party services that may collect and process your data:</p>
            
            <h4 className="text-xl font-semibold text-[#5E1C1D] mb-3">4.1 Firebase (Google)</h4>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>Authentication:</strong> Phone number verification and user authentication</li>
              <li><strong>Analytics:</strong> Usage analytics and performance monitoring</li>
              <li><strong>Data Processing:</strong> User data is processed by Google according to their privacy policy</li>
            </ul>

            <h4 className="text-xl font-semibold text-[#5E1C1D] mb-3">4.2 Twilio</h4>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>SMS Services:</strong> Sending verification codes and event notifications</li>
              <li><strong>Phone Number Processing:</strong> Phone numbers are processed by Twilio for SMS delivery</li>
            </ul>

            <h4 className="text-xl font-semibold text-[#5E1C1D] mb-3">4.3 AWS (Amazon Web Services)</h4>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>Data Storage:</strong> User data and event information stored securely</li>
              <li><strong>Secrets Management:</strong> Secure storage of API keys and credentials</li>
              <li><strong>Infrastructure:</strong> Hosting and processing of application data</li>
            </ul>

            <h4 className="text-xl font-semibold text-[#5E1C1D] mb-3">4.4 Notion</h4>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>Waitlist Management:</strong> Processing waitlist submissions and user data</li>
              <li><strong>Data Processing:</strong> Information shared with Notion for waitlist purposes</li>
            </ul>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">5. Data Sharing and Disclosure</h3>
            <p className="mb-4">We do not sell, trade, or rent your personal information to third parties. We may share your information in the following limited circumstances:</p>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>With Your Consent:</strong> When you explicitly agree to share information</li>
              <li><strong>Service Providers:</strong> With trusted third-party services that help us operate our platform</li>
              <li><strong>Legal Requirements:</strong> When required by law or to protect our rights and safety</li>
              <li><strong>Business Transfers:</strong> In connection with a merger, acquisition, or sale of assets</li>
            </ul>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">6. Data Security</h3>
            <p className="mb-4">We implement appropriate security measures to protect your information:</p>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>Encryption:</strong> Data is encrypted in transit and at rest</li>
              <li><strong>Access Controls:</strong> Limited access to personal data on a need-to-know basis</li>
              <li><strong>Secure Infrastructure:</strong> AWS-hosted infrastructure with security best practices</li>
              <li><strong>Regular Audits:</strong> Ongoing security assessments and updates</li>
            </ul>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">7. Your Rights and Choices</h3>
            <p className="mb-4">You have the following rights regarding your personal information:</p>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>Access:</strong> Request a copy of your personal data</li>
              <li><strong>Correction:</strong> Update or correct inaccurate information</li>
              <li><strong>Deletion:</strong> Request deletion of your account and data</li>
              <li><strong>Portability:</strong> Export your data in a machine-readable format</li>
            </ul>
            <p className="mb-4">
              To exercise these rights, please contact us at the information provided below.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">8. Data Retention</h3>
            <p className="mb-4">
              We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this Privacy Policy. We may retain certain information for longer periods for legal, regulatory, or business purposes.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">9. Children's Privacy</h3>
            <p className="mb-4">
              Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">10. International Data Transfers</h3>
            <p className="mb-4">
              Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your data in accordance with this Privacy Policy.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">11. Changes to This Privacy Policy</h3>
            <p className="mb-4">
              We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new Privacy Policy on this page and updating the "Last updated" date. Your continued use of our services after any changes constitutes acceptance of the updated Privacy Policy.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">12. Contact Information</h3>
            <p className="mb-4">
              If you have any questions about this Privacy Policy or our data practices, please contact us:
            </p>
            <div className="bg-[#F8F8F8] p-6 rounded-lg">
              <p className="mb-2"><strong>Email:</strong> privacy@coveapp.co</p>
              <p className="mb-2"><strong>Website:</strong> https://coveapp.co</p>
              <p><strong>Response Time:</strong> We will respond to your inquiry within 30 days.</p>
            </div>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">13. SMS Consent</h3>
            <p className="mb-4">
              By providing your phone number, you consent to receive SMS messages from Cove for authentication and event notifications. SMS consent is required to use our services.
            </p>
            <p className="mb-4">
              Standard message and data rates may apply. Message frequency varies based on your activity and preferences.
            </p>
          </section>
        </div>

        {/* Footer */}
        <div className="mt-12 pt-8 border-t border-[#E5E5E5] text-center">
          <p className="text-[#8B8B8B] text-sm">
            This Privacy Policy is effective as of {new Date().toLocaleDateString()} and will remain in effect except with respect to any changes in its provisions in the future.
          </p>
        </div>
      </div>
    </div>
  );
}
