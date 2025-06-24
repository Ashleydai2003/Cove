import React, { useEffect, useState } from 'react';
import type { NextPage } from 'next';
import Head from 'next/head';
import Image from 'next/image';
import Link from 'next/link';

const Home: NextPage = () => {
  const [showForm, setShowForm] = useState(false);
  const [showContactForm, setShowContactForm] = useState(false);
  const [resultsHovered, setResultsHovered] = useState(false);
  const [joinHovered, setJoinHovered] = useState(false);
  const [contactHovered, setContactHovered] = useState(false);
  const [isFading, setIsFading] = useState(false);

  useEffect(() => {
    if (showForm || showContactForm) {
      // Load Typeform embed script only when a form should be shown
      const script = document.createElement('script');
      script.src = '//embed.typeform.com/next/embed.js';
      script.async = true;
      document.body.appendChild(script);

      return () => {
        document.body.removeChild(script);
      };
    }
  }, [showForm, showContactForm]);

  const handleButtonClick = () => {
    setIsFading(true);
    setTimeout(() => {
      setShowForm(true);
    }, 500); // Match this with the CSS transition duration
  };

  const handleContactButtonClick = () => {
    setIsFading(true);
    setTimeout(() => {
      setShowContactForm(true);
    }, 500);
  };

  return (
    <>
      <Head>
        <title>Stanford Loop</title>
        <meta property="og:title" content="Stanford Loop"/>
        <meta name="description" content="Find out who's moving to your city." />
        <meta property="og:description" content="Find out who's moving to your city." />
        <meta property="og:image" content="/assets/PNG image.png" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <link
          href="https://fonts.googleapis.com/css2?family=Libre+Bodoni:ital,wght@0,400;0,500;0,600;0,700;1,400;1,500;1,600;1,700&display=swap"
          rel="stylesheet"
        />
      </Head>
      <div style={{
        color: '#8E413A',
        fontFamily: '"Libre Bodoni", serif',
        minHeight: '100vh',
        background: '#F5F0E6',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        padding: '1rem',
        opacity: isFading ? 0 : 1,
        transition: 'opacity 0.5s ease-in-out',
        width: '100%',
        boxSizing: 'border-box',
        maxWidth: '1200px',
        margin: '0 auto'
      }}>
        <div style={{
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          maxWidth: '900px'
        }}>
          <Link href="/" style={{ textDecoration: 'none', display: 'flex', justifyContent: 'center', width: '100%' }}>
            <Image
              src="/assets/PNG image.png"
              alt="Stanford Loop Logo"
              width={220}
              height={70}
              style={{ marginBottom: '1.5rem', width: 'min(220px, 80%)', height: 'auto', cursor: 'pointer' }}
            />
          </Link>
          <h1 style={{ 
            fontWeight: 600, 
            fontSize: 'clamp(1.5rem, 5vw, 2.2rem)', 
            marginBottom: '1rem', 
            textAlign: 'center',
            padding: '0 1rem'
          }}>
            Stanford Loop
          </h1>
          <p style={{ 
            fontSize: 'clamp(1rem, 3vw, 1.2rem)', 
            marginBottom: '0.5rem', 
            textAlign: 'center',
            color: '#8E413A',
            fontWeight: 500,
            padding: '0 1rem'
          }}>
            Results have been released!
          </p>
          <p style={{ 
            fontSize: 'clamp(0.9rem, 2.5vw, 1.1rem)', 
            marginBottom: '2rem', 
            textAlign: 'center',
            color: '#8E413A',
            fontWeight: 500,
            padding: '0 1rem'
          }}>
            Woohoo! We received over 1000 responses 🎉
          </p>
          <div style={{ 
            display: 'flex', 
            flexDirection: 'column', 
            gap: '1rem', 
            alignItems: 'center',
            width: '100%',
            maxWidth: '300px',
            padding: '0 1rem'
          }}>
            <a 
              href="/directory" 
              style={{
                padding: '0.8rem 1.5rem',
                backgroundColor: '#8E413A',
                color: '#F5F0E6',
                textDecoration: 'none',
                borderRadius: '8px',
                fontSize: 'clamp(0.9rem, 2.5vw, 1.1rem)',
                fontWeight: 500,
                fontFamily: '"Libre Bodoni", serif',
                transition: 'transform 0.2s ease-in-out',
                transform: resultsHovered ? 'scale(1.05)' : 'scale(1)',
                width: '250px',
                textAlign: 'center',
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                boxSizing: 'border-box'
              }}
              onMouseEnter={() => setResultsHovered(true)}
              onMouseLeave={() => setResultsHovered(false)}
            >
              Take me to the results
            </a>
            <button
              onClick={handleContactButtonClick}
              style={{
                padding: '0.8rem 1.5rem',
                backgroundColor: '#8E413A',
                color: '#F5F0E6',
                border: 'none',
                borderRadius: '8px',
                fontSize: 'clamp(0.9rem, 2.5vw, 1.1rem)',
                fontWeight: 500,
                fontFamily: '"Libre Bodoni", serif',
                cursor: 'pointer',
                transition: 'all 0.2s ease-in-out',
                transform: contactHovered ? 'scale(1.05)' : 'scale(1)',
                width: '250px',
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                boxSizing: 'border-box'
              }}
              onMouseEnter={() => setContactHovered(true)}
              onMouseLeave={() => setContactHovered(false)}
            >
              Add contact info
            </button>
            <button
              onClick={handleButtonClick}
              style={{
                padding: '0.8rem 1.5rem',
                backgroundColor: '#F5F0E6',
                color: '#8E413A',
                border: '2px solid #8E413A',
                borderRadius: '8px',
                fontSize: 'clamp(0.9rem, 2.5vw, 1.1rem)',
                fontWeight: 500,
                fontFamily: '"Libre Bodoni", serif',
                cursor: 'pointer',
                transition: 'all 0.2s ease-in-out',
                transform: joinHovered ? 'scale(1.05)' : 'scale(1)',
                width: '250px',
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                boxSizing: 'border-box'
              }}
              onMouseEnter={() => setJoinHovered(true)}
              onMouseLeave={() => setJoinHovered(false)}
            >
              Join Stanford Loop
            </button>
          </div>
        </div>
      </div>
      {showForm && (
        <div style={{ 
          position: 'fixed', 
          top: 0, 
          left: 0, 
          width: '100%', 
          height: '100%', 
          zIndex: 1000,
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          backgroundColor: '#F5F0E6',
          padding: '1rem'
        }}>
          <a href="/" style={{ display: 'block', margin: '0 auto 1rem auto', width: 'min(220px, 80%)', textAlign: 'center' }}>
            <Image
              src="/assets/PNG image.png"
              alt="Stanford Loop Logo"
              width={220}
              height={70}
              style={{ width: 'min(220px, 80%)', height: 'auto', cursor: 'pointer', marginBottom: '1rem' }}
            />
          </a>
          <div style={{
            width: '100%',
            maxWidth: '800px',
            height: '100%',
            maxHeight: '800px',
            margin: 'auto'
          }}>
            <div data-tf-live="01JV837X4GZWH5B6D87PZKWAJ1" style={{ width: '100%', height: '100%' }}></div>
          </div>
        </div>
      )}
      {showContactForm && (
        <div style={{ 
          position: 'fixed', 
          top: 0, 
          left: 0, 
          width: '100%', 
          height: '100%', 
          zIndex: 1000,
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          backgroundColor: '#F5F0E6',
          padding: '1rem'
        }}>
          <a href="/" style={{ display: 'block', margin: '0 auto 1rem auto', width: 'min(220px, 80%)', textAlign: 'center' }}>
            <Image
              src="/assets/PNG image.png"
              alt="Stanford Loop Logo"
              width={220}
              height={70}
              style={{ width: 'min(220px, 80%)', height: 'auto', cursor: 'pointer', marginBottom: '1rem' }}
            />
          </a>
          <div style={{
            width: '100%',
            maxWidth: '800px',
            height: '100%',
            maxHeight: '800px',
            margin: 'auto'
          }}>
            <div data-tf-live="01JWYMSJGGHJR17MJSRJ24X7HK" style={{ width: '100%', height: '100%' }}></div>
          </div>
        </div>
      )}
    </>
  );
};

export default Home; 