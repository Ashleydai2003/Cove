'use client';

import { Libre_Bodoni } from 'next/font/google';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';

const libreBodoni = Libre_Bodoni({ 
  subsets: ['latin'],
  weight: ['400', '600', '700'],
  variable: '--font-libre-bodoni'
});

export default function TermsPage() {
  return (
    <div className={`${libreBodoni.variable} font-libre-bodoni min-h-screen bg-[#F5F0E6] text-[#2D2D2D]`}>
      <div className="max-w-4xl mx-auto px-4 py-12">
        {/* Header */}
        <div className="mb-8">
          <Link 
            href="/" 
            className="inline-flex items-center gap-2 text-[#5E1C1D] hover:text-[#4A1718] transition-colors mb-6"
          >
            <ArrowLeft size={20} />
            <span className="font-libre-bodoni">back to home</span>
          </Link>
          <h1 className="text-6xl font-bold text-[#5E1C1D] mb-4">cove</h1>
          <h2 className="text-3xl font-semibold text-[#5E1C1D]">terms of service</h2>
          <p className="text-lg text-[#8B8B8B] mt-2">last updated: {new Date().toLocaleDateString()}</p>
        </div>

        {/* Content */}
        <div className="prose prose-lg max-w-none">
          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">1. Acceptance of Terms</h3>
            <p className="mb-4">
              By accessing and using Cove ("the Service"), you accept and agree to be bound by the terms and provision of this agreement. 
              If you do not agree to abide by the above, please do not use this service.
            </p>
            <p className="mb-4">
              These Terms of Service ("Terms") govern your use of our website and services operated by Cove ("us", "we", or "our").
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">2. Description of Service</h3>
            <p className="mb-4">
              Cove is a platform that connects young alumni through exclusive events and networking opportunities. Our services include:
            </p>
            <ul className="list-disc pl-6 mb-4">
              <li>Event discovery and RSVP management</li>
              <li>Alumni networking and community building</li>
              <li>SMS notifications (with your consent)</li>
              <li>Profile management and social features</li>
            </ul>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">3. User Eligibility</h3>
            <p className="mb-4">
              To use Cove, you must:
            </p>
            <ul className="list-disc pl-6 mb-4">
              <li>Be at least 18 years old</li>
              <li>Have graduated from a university or college</li>
              <li>Provide accurate and complete information during registration</li>
              <li>Maintain the security of your account credentials</li>
            </ul>
            <p className="mb-4">
              Cove is designed for young alumni, typically within 10 years of graduation. We reserve the right to verify your 
              educational background and may request additional documentation.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">4. User Accounts and Registration</h3>
            <p className="mb-4">
              When you create an account with us, you must provide information that is accurate, complete, and current at all times. 
              You are responsible for safeguarding the password and for all activities that occur under your account.
            </p>
            <p className="mb-4">
              You agree not to disclose your password to any third party and to take sole responsibility for any activities 
              or actions under your account, whether or not you have authorized such activities or actions.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">5. Acceptable Use</h3>
            <p className="mb-4">You agree not to use Cove to:</p>
            <ul className="list-disc pl-6 mb-4">
              <li>Violate any laws or regulations</li>
              <li>Infringe on the rights of others</li>
              <li>Transmit harmful or malicious code</li>
              <li>Spam or send unsolicited communications</li>
              <li>Impersonate others or provide false information</li>
              <li>Harass, abuse, or harm other users</li>
              <li>Use the service for commercial purposes without permission</li>
            </ul>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">6. SMS Communications</h3>
            <p className="mb-4">
              By providing your phone number, you consent to receive SMS messages from Cove for authentication and event notifications. 
              SMS consent is optional and you can opt out at any time.
            </p>
            <p className="mb-4">
              <strong>SMS Terms:</strong>
            </p>
            <ul className="list-disc pl-6 mb-4">
              <li>Message frequency: Up to 3 messages per event</li>
              <li>Standard message and data rates may apply</li>
              <li>Text STOP to unsubscribe, HELP for help</li>
              <li>You can opt out at any time</li>
            </ul>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">7. Privacy and Data Protection</h3>
            <p className="mb-4">
              Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the Service, 
              to understand our practices.
            </p>
            <p className="mb-4">
              We collect and process personal data in accordance with applicable privacy laws and our Privacy Policy. 
              You have the right to access, correct, or delete your personal data at any time.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">8. Intellectual Property</h3>
            <p className="mb-4">
              The Service and its original content, features, and functionality are and will remain the exclusive property of Cove 
              and its licensors. The Service is protected by copyright, trademark, and other laws.
            </p>
            <p className="mb-4">
              You may not reproduce, distribute, modify, or create derivative works of our content without our express written permission.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">9. Termination</h3>
            <p className="mb-4">
              We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, 
              including without limitation if you breach the Terms.
            </p>
            <p className="mb-4">
              Upon termination, your right to use the Service will cease immediately. You may delete your account at any time 
              by contacting us or using the account deletion feature in your profile settings.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">10. Disclaimers and Limitation of Liability</h3>
            <p className="mb-4">
              The information on this Service is provided on an "as is" basis. To the fullest extent permitted by law, 
              Cove excludes all representations, warranties, conditions and terms relating to our Service and the use of this Service.
            </p>
            <p className="mb-4">
              In no event shall Cove, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any 
              indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, 
              data, use, goodwill, or other intangible losses, resulting from your use of the Service.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">11. Governing Law</h3>
            <p className="mb-4">
              These Terms shall be interpreted and governed by the laws of the United States, without regard to its conflict of law provisions.
            </p>
            <p className="mb-4">
              Our failure to enforce any right or provision of these Terms will not be considered a waiver of those rights.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">12. Changes to Terms</h3>
            <p className="mb-4">
              We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material, 
              we will try to provide at least 30 days notice prior to any new terms taking effect.
            </p>
            <p className="mb-4">
              By continuing to access or use our Service after those revisions become effective, you agree to be bound by the revised terms.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">13. Contact Information</h3>
            <p className="mb-4">
              If you have any questions about these Terms of Service, please contact us:
            </p>
            <div className="bg-[#F8F8F8] p-6 rounded-lg">
              <p className="mb-2"><strong>Email:</strong> legal@coveapp.co</p>
              <p className="mb-2"><strong>Website:</strong> https://coveapp.co</p>
              <p><strong>Response Time:</strong> We will respond to your inquiry within 30 days.</p>
            </div>
          </section>
        </div>

        {/* Footer */}
        <div className="mt-12 pt-8 border-t border-[#E5E5E5] text-center">
          <p className="text-[#8B8B8B] text-sm">
            These Terms of Service are effective as of {new Date().toLocaleDateString()} and will remain in effect except with respect to any changes in its provisions in the future.
          </p>
        </div>
      </div>
    </div>
  );
}
