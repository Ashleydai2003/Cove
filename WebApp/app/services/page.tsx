'use client';

import { Libre_Bodoni } from 'next/font/google';
import Link from 'next/link';
import { ArrowLeft, Users, Calendar, MessageSquare, Shield } from 'lucide-react';

const libreBodoni = Libre_Bodoni({ 
  subsets: ['latin'],
  weight: ['400', '600', '700'],
  variable: '--font-libre-bodoni'
});

export default function ServicesPage() {
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
          <h2 className="text-3xl font-semibold text-[#5E1C1D]">Our Services</h2>
        </div>

        {/* Content */}
        <div className="prose prose-lg max-w-none">
          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">What We Offer</h3>
            <p className="mb-6">
              Cove creates events for young alumni to connect, network, and build meaningful relationships. 
              Here's what you can expect from our services:
            </p>
          </section>

          {/* Service Cards */}
          <div className="grid md:grid-cols-2 gap-6 mb-8">
            <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
              <div className="flex items-center gap-3 mb-4">
                <Users className="text-[#5E1C1D]" size={24} />
                <h4 className="text-xl font-semibold text-[#5E1C1D]">Networking Events</h4>
              </div>
              <p className="text-[#2D2D2D] mb-4">
                Professional mixers, industry meetups, and career-focused events designed to help you expand your network.
              </p>
              <ul className="text-sm text-[#8B8B8B] space-y-1">
                <li>• Industry-specific networking</li>
                <li>• Career development workshops</li>
                <li>• Mentorship opportunities</li>
              </ul>
            </div>

            <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
              <div className="flex items-center gap-3 mb-4">
                <Calendar className="text-[#5E1C1D]" size={24} />
                <h4 className="text-xl font-semibold text-[#5E1C1D]">Social Events</h4>
              </div>
              <p className="text-[#2D2D2D] mb-4">
                Casual gatherings, recreational activities, and social events to help you build meaningful friendships.
              </p>
              <ul className="text-sm text-[#8B8B8B] space-y-1">
                <li>• Alumni reunions</li>
                <li>• Recreational activities</li>
                <li>• Cultural events</li>
              </ul>
            </div>

            <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
              <div className="flex items-center gap-3 mb-4">
                <MessageSquare className="text-[#5E1C1D]" size={24} />
                <h4 className="text-xl font-semibold text-[#5E1C1D]">Communication</h4>
              </div>
              <p className="text-[#2D2D2D] mb-4">
                Stay connected with event updates, RSVP confirmations, and important announcements.
              </p>
              <ul className="text-sm text-[#8B8B8B] space-y-1">
                <li>• SMS notifications (optional)</li>
                <li>• Event reminders</li>
                <li>• Community updates</li>
              </ul>
            </div>

            <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
              <div className="flex items-center gap-3 mb-4">
                <Shield className="text-[#5E1C1D]" size={24} />
                <h4 className="text-xl font-semibold text-[#5E1C1D]">Secure Platform</h4>
              </div>
              <p className="text-[#2D2D2D] mb-4">
                Your privacy and security are our top priorities with verified alumni and secure data handling.
              </p>
              <ul className="text-sm text-[#8B8B8B] space-y-1">
                <li>• Verified alumni only</li>
                <li>• Secure data handling</li>
                <li>• Privacy protection</li>
              </ul>
            </div>
          </div>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">Event Types</h3>
            <div className="grid md:grid-cols-3 gap-4 mb-6">
              <div className="bg-[#F8F8F8] p-4 rounded-lg">
                <h5 className="font-semibold text-[#5E1C1D] mb-2">Professional</h5>
                <p className="text-sm text-[#8B8B8B]">
                  Industry panels, career workshops, and networking mixers
                </p>
              </div>
              <div className="bg-[#F8F8F8] p-4 rounded-lg">
                <h5 className="font-semibold text-[#5E1C1D] mb-2">Social</h5>
                <p className="text-sm text-[#8B8B8B]">
                  Happy hours, game nights, and recreational activities
                </p>
              </div>
              <div className="bg-[#F8F8F8] p-4 rounded-lg">
                <h5 className="font-semibold text-[#5E1C1D] mb-2">Educational</h5>
                <p className="text-sm text-[#8B8B8B]">
                  Skill-building workshops and educational seminars
                </p>
              </div>
            </div>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">How It Works</h3>
            <div className="space-y-4">
              <div className="flex items-start gap-4">
                <div className="w-8 h-8 bg-[#5E1C1D] text-white rounded-full flex items-center justify-center text-sm font-semibold flex-shrink-0">
                  1
                </div>
                <div>
                  <h5 className="font-semibold text-[#5E1C1D] mb-1">Sign Up</h5>
                  <p className="text-[#8B8B8B]">Create your profile with your university information and interests</p>
                </div>
              </div>
              <div className="flex items-start gap-4">
                <div className="w-8 h-8 bg-[#5E1C1D] text-white rounded-full flex items-center justify-center text-sm font-semibold flex-shrink-0">
                  2
                </div>
                <div>
                  <h5 className="font-semibold text-[#5E1C1D] mb-1">Discover Events</h5>
                  <p className="text-[#8B8B8B]">Browse and discover events in your area that match your interests</p>
                </div>
              </div>
              <div className="flex items-start gap-4">
                <div className="w-8 h-8 bg-[#5E1C1D] text-white rounded-full flex items-center justify-center text-sm font-semibold flex-shrink-0">
                  3
                </div>
                <div>
                  <h5 className="font-semibold text-[#5E1C1D] mb-1">RSVP & Connect</h5>
                  <p className="text-[#8B8B8B]">RSVP to events and start building your professional network</p>
                </div>
              </div>
            </div>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">Get Started</h3>
            <div className="bg-[#F8F8F8] p-6 rounded-lg">
              <p className="mb-4">
                Ready to join our community of young alumni? Sign up today and start attending exclusive events 
                designed just for recent graduates.
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
            Questions about our services? <a href="/contact" className="text-[#5E1C1D] hover:text-[#4A1718] underline">Contact us</a>
          </p>
        </div>
      </div>
    </div>
  );
}
