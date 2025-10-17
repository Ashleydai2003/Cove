'use client';

import { Libre_Bodoni } from 'next/font/google';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';

const libreBodoni = Libre_Bodoni({ 
  subsets: ['latin'],
  weight: ['400', '600', '700'],
  variable: '--font-libre-bodoni'
});

export default function HowItWorksPage() {
  return (
    <div className={`${libreBodoni.variable} font-libre-bodoni min-h-screen bg-[#F5F0E6] text-[#2D2D2D]`}>
      <div className="max-w-4xl mx-auto px-4 py-12">
        {/* header */}
        <div className="mb-8">
          <Link 
            href="/" 
            className="inline-flex items-center gap-2 text-[#5E1C1D] hover:text-[#4A1718] transition-colors mb-6"
          >
            <ArrowLeft size={20} />
            <span className="font-libre-bodoni">back to home</span>
          </Link>
          <h1 className="text-6xl font-bold text-[#5E1C1D] mb-4">cove</h1>
          <h2 className="text-3xl font-semibold text-[#5E1C1D]">how it works</h2>
        </div>

        {/* content */}
        <div className="prose prose-lg max-w-none">
          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">curated events</h3>
            <p className="mb-4">rsvp to exclusive cove events (think: rooftop parties, coffee club afro dj set, gatsby mansion soirées...)</p>
            <ul className="list-disc pl-6 mb-4">
              <li>we handle the vetting - everyone's in your network</li>
              <li>show up and meet people you'd actually want to know</li>
              <li>repeat - same crew starts showing up to the same things</li>
            </ul>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">coming soon: the place to be</h3>
            <p className="mb-4">periodic texts telling you where to be—a thursday bar takeover, saturday morning café session. show up, your people will be there.</p>
          </section>

          <section className="mb-10">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">coming next: matching</h3>
            <p className="mb-4">select from a list of activities you’d do anyway (tuesday tennis, sunday brunch crew, thursday run club…) our algorithm finds your most compatible matches. meet them at recurring weekly activities we organize. no swiping, no logistics—just show up.</p>
            <p className="mb-4"><a href="/" className="text-[#5E1C1D] underline hover:text-[#4A1718]">interested in beta matching? join the waitlist →</a></p>
          </section>
        </div>

        {/* footer */}
        <div className="mt-12 pt-8 border-t border-[#E5E5E5] text-center">
          <p className="text-[#8B8B8B] text-sm">
            questions about cove? <Link href="/contact" className="text-[#5E1C1D] hover:text-[#4A1718] underline">contact us</Link>
          </p>
        </div>
      </div>
    </div>
  );
}


