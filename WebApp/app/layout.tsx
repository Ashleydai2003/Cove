import React from 'react';
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: {
    template: '%s | Cove',
    default: 'Cove - Connect Through Events',
  },
  description: 'Discover and attend events in your community through Cove.',
  keywords: ['events', 'community', 'social', 'meetups'],
  authors: [{ name: 'Cove Team' }],
  viewport: 'width=device-width, initial-scale=1',
  robots: 'index, follow',
  openGraph: {
    type: 'website',
    siteName: 'Cove',
    title: 'Cove - Connect Through Events',
    description: 'Discover and attend events in your community through Cove.',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Cove - Connect Through Events',
    description: 'Discover and attend events in your community through Cove.',
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
      </head>
      <body className="min-h-screen bg-faf8f4 text-k292929 antialiased">
        <main className="relative">
          {children}
        </main>
      </body>
    </html>
  );
} 