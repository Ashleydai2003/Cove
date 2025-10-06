'use client';

import { Libre_Bodoni } from 'next/font/google';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';

const libreBodoni = Libre_Bodoni({ 
  subsets: ['latin'],
  weight: ['400', '600', '700'],
  variable: '--font-libre-bodoni'
});

export default function AboutPage() {
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
            <span className="font-libre-bodoni">Back to Home</span>
          </Link>
          <h1 className="text-6xl font-bold text-[#5E1C1D] mb-4">cove</h1>
          <h2 className="text-3xl font-semibold text-[#5E1C1D]">About Us</h2>
        </div>

        {/* Content */}
        <div className="prose prose-lg max-w-none">
          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">Our Mission</h3>
            <p className="mb-4">
              Cove creates events for young alumni to connect, network, and build meaningful relationships. 
              We believe that the connections formed during college should continue to flourish in the professional world, 
              and we're here to make that happen.
            </p>
            <p className="mb-4">
              Our mission is to create a vibrant community where recent graduates can maintain their college connections 
              while building new professional relationships through curated events and experiences.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">What We Do</h3>
            <p className="mb-4">
              Cove organizes exclusive events for young alumni, including:
            </p>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>Networking Events:</strong> Professional mixers and industry meetups</li>
              <li><strong>Social Gatherings:</strong> Casual get-togethers and recreational activities</li>
              <li><strong>Career Development:</strong> Workshops, panels, and mentorship opportunities</li>
              <li><strong>Alumni Reunions:</strong> University-specific events and celebrations</li>
            </ul>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">Our Community</h3>
            <p className="mb-4">
              Cove is built for recent graduates (typically within 10 years of graduation) who want to:
            </p>
            <ul className="list-disc pl-6 mb-4">
              <li>Stay connected with their college community</li>
              <li>Expand their professional network</li>
              <li>Attend exclusive, high-quality events</li>
              <li>Build meaningful relationships with like-minded peers</li>
            </ul>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">Why Cove?</h3>
            <p className="mb-4">
              Unlike generic networking platforms, Cove is specifically designed for young alumni who share the common 
              experience of recent graduation. This creates a more authentic and meaningful community where connections 
              are based on shared experiences and mutual understanding.
            </p>
            <p className="mb-4">
              Our events are carefully curated to ensure quality and relevance, and our platform makes it easy to 
              discover and RSVP to events that match your interests and schedule.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">Join Our Community</h3>
            <p className="mb-4">
              Ready to reconnect with your college community and build new professional relationships? 
              Join Cove today and start attending exclusive events designed just for young alumni.
            </p>
            <div className="bg-[#F8F8F8] p-6 rounded-lg">
              <p className="mb-4">
                <strong>Getting Started:</strong> Simply sign up with your phone number and complete your profile. 
                You'll receive notifications about events in your area and can start building your network immediately.
              </p>
              <Link 
                href="/"
                className="inline-block bg-[#5E1C1D] text-white px-6 py-3 rounded-lg hover:bg-[#4A1718] transition-colors font-libre-bodoni"
              >
                Join the Waitlist
              </Link>
            </div>
          </section>
        </div>

        {/* Footer */}
        <div className="mt-12 pt-8 border-t border-[#E5E5E5] text-center">
          <p className="text-[#8B8B8B] text-sm">
            Questions about Cove? <Link href="/contact" className="text-[#5E1C1D] hover:text-[#4A1718] underline">Contact us</Link>
          </p>
        </div>
      </div>
    </div>
  );
}
