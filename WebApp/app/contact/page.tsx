'use client';

import { Libre_Bodoni } from 'next/font/google';
import Link from 'next/link';
import { ArrowLeft, Mail, MessageSquare, HelpCircle } from 'lucide-react';

const libreBodoni = Libre_Bodoni({ 
  subsets: ['latin'],
  weight: ['400', '600', '700'],
  variable: '--font-libre-bodoni'
});

export default function ContactPage() {
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
          <h2 className="text-3xl font-semibold text-[#5E1C1D]">reach out</h2>
        </div>

        {/* Content */}
        <div className="prose prose-lg max-w-none">
          <section className="mb-8">
            <p className="mb-6">
              Have questions about our events for young alumni? We're here to help! Get in touch with us below.
            </p>
          </section>

          {/* Contact Methods */}
          <div className="mb-8">
            <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200 max-w-md">
              <div className="flex items-center gap-3 mb-4">
                <Mail className="text-[#5E1C1D]" size={24} />
            <h4 className="text-xl font-semibold text-[#5E1C1D]">get in touch</h4>
              </div>
              <p className="text-[#2D2D2D] mb-4">
                have questions about our events for young alumni? we're here to help!
              </p>
              <div className="bg-[#F8F8F8] p-4 rounded-lg">
                <p className="text-sm">
                  <strong>contact us:</strong><br />
                  <a href="mailto:tech@coveapp.co" className="text-[#5E1C1D] hover:text-[#4A1718]">
                    tech@coveapp.co
                  </a>
                </p>
                <p className="text-xs text-[#8B8B8B] mt-2">
                  we'll get back to you within 24 hours
                </p>
              </div>
            </div>
          </div>

          {/* FAQ Section */}
          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">Frequently Asked Questions</h3>
            <div className="space-y-4">
              <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
                <h5 className="font-semibold text-[#5E1C1D] mb-2">How do I join Cove?</h5>
                <p className="text-[#8B8B8B] text-sm">
                  Simply sign up with your phone number and complete your profile. You'll be added to our waitlist and 
                  notified when events become available in your area.
                </p>
              </div>
              
              <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
                <h5 className="font-semibold text-[#5E1C1D] mb-2">Who can join Cove?</h5>
                <p className="text-[#8B8B8B] text-sm">
                  Cove is designed for young alumni, typically within 10 years of graduation. You must have graduated 
                  from a university or college to join our community.
                </p>
              </div>
              
              <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
                <h5 className="font-semibold text-[#5E1C1D] mb-2">Are events free?</h5>
                <p className="text-[#8B8B8B] text-sm">
                  Many of our events are free, while some may have a small fee to cover venue costs, food, or activities. 
                  Event pricing is always clearly displayed when you RSVP.
                </p>
              </div>
              
              <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
                <h5 className="font-semibold text-[#5E1C1D] mb-2">How do I opt out of SMS notifications?</h5>
                <p className="text-[#8B8B8B] text-sm">
                  You can opt out of SMS notifications at any time by replying "STOP" to any message, or by updating 
                  your preferences in your account settings.
                </p>
              </div>
            </div>
          </section>

        </div>

        {/* Footer */}
        <div className="mt-12 pt-8 border-t border-[#E5E5E5] text-center">
          <p className="text-[#8B8B8B] text-sm">
            Can't find what you're looking for? <Link href="/" className="text-[#5E1C1D] hover:text-[#4A1718] underline">Return to home</Link>
          </p>
        </div>
      </div>
    </div>
  );
}
