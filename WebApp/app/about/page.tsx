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
            <span className="font-libre-bodoni">back to home</span>
          </Link>
          <h1 className="text-6xl font-bold text-[#5E1C1D] mb-4">cove</h1>
          <h2 className="text-3xl font-semibold text-[#5E1C1D]">about</h2>
        </div>

        {/* Content */}
        <div className="prose prose-lg max-w-none">
          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">about us</h3>
            <p className="mb-4">
              we're three stanford grads who miss how college turned serendipitous encounters into core memories.
            </p>
            <p className="mb-4">
              now, it’s the same five college friends at the same bars, while our future favorite humans probably live two blocks away–but we may never randomly collide.
            </p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">the truth nobody admits:</h3>
            <ul className="list-disc pl-6 mb-4">
              <li>the interesting people aren't swiping through strangers</li>
              <li>meeting your new crush at thursday pickleball beats any app</li>
              <li>random meetups are…random</li>
              <li>your people exist; finding them shouldn't require luck</li>
              <li>alumni events are old and networky—nothing like college was</li>
            </ul>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">why alumni first</h3>
            <p className="mb-4">we're launching with ten elite institutions. vetted network. shared context. the kind of people who start companies, shape culture, and change cities.</p>
            <p className="mb-4">think of it as college after college, curated for you.</p>
            <p className="mb-4">so we built cove.</p>
            <p className="mb-4">you joined college soccer to play soccer. you stayed for the people. cove works the same way.</p>
            <p className="mb-4">carefully curated humans based on real compatibility—young alumni, shared context, and exactly who you're looking for.</p>
            <p className="mb-4">recurring rituals that actually happen (think: sunday brunch club). no logistics drama. we handle everything. just show up.</p>
            <p className="mb-4">friends, roommates, romance–whatever comes next—that's up to you. but we make the odds infinitely better than leaving it up to chance.</p>
          </section>

          <section className="mb-8">
            <h3 className="text-2xl font-semibold text-[#5E1C1D] mb-4">the humans behind this:</h3>
            <ul className="list-disc pl-6 mb-4">
              <li>nina (ceo) - built things people show up to</li>
              <li>ashley (cto) - turns code into human connection</li>
              <li>angela (cmo) - knows what’s next before it’s next</li>
            </ul>
            <p className="mb-4">we know you probably have friends already. but aren't you just a little curious who else is out there?</p>
            <p className="mb-4">we’re in sf. coming to nyc soon.</p>
          </section>
        </div>

        {/* Footer */}
        <div className="mt-12 pt-8 border-t border-[#E5E5E5] text-center">
          <p className="text-[#8B8B8B] text-sm">
            questions about cove? <Link href="/contact" className="text-[#5E1C1D] hover:text-[#4A1718] underline">contact us</Link>
          </p>
        </div>
      </div>
    </div>
  );
}
