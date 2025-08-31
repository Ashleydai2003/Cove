import React from 'react';
import type { Metadata } from 'next';
import './globals.css';
import { SessionProvider } from '@/components/SessionProvider';

export const metadata: Metadata = {
  metadataBase: new URL('https://coveapp.co'),
  title: {
    template: '%s | Cove',
    default: 'cove - events for young alumni',
  },
  description: 'your city, unlocked.',
  keywords: ['events', 'community', 'social', 'meetups'],
  authors: [{ name: 'Cove Team' }],
  viewport: 'width=device-width, initial-scale=1',
  robots: 'index, follow',
  openGraph: {
    type: 'website',
    siteName: 'Cove',
    title: 'cove - events for young alumni',
    description: 'your city, unlocked',
    images: ['/cove-logo.png'],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'cove - events for young alumni',
    description: 'your city, unlocked',
    images: ['/cove-logo.png'],
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="scroll-smooth">
      <head>
        <link rel="icon" href="/cove-logo.svg" type="image/svg+xml" />
        {/* Security Headers */}
        <meta httpEquiv="X-Content-Type-Options" content="nosniff" />
        <meta httpEquiv="X-Frame-Options" content="DENY" />
        <meta httpEquiv="X-XSS-Protection" content="1; mode=block" />
        <meta httpEquiv="Referrer-Policy" content="strict-origin-when-cross-origin" />
        <meta httpEquiv="Permissions-Policy" content="camera=(), microphone=(), geolocation=()" />
      </head>
      <body className="min-h-screen bg-faf8f4 text-k292929 antialiased">
        <SessionProvider>
          <main className="relative">
            {children}
          </main>
        </SessionProvider>
      </body>
    </html>
  );
} 