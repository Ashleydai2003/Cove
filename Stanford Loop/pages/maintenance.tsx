import React from 'react';
import type { NextPage } from 'next';
import Head from 'next/head';

const MaintenancePage: NextPage = () => {
  return (
    <>
      <Head>
        <title>Stanford Loop - Maintenance</title>
        <meta property="og:title" content="Stanford Loop - Maintenance"/>
        <meta name="description" content="Stanford Loop is currently being updated." />
        <meta property="og:description" content="Stanford Loop is currently being updated." />
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
            We are currently updating the Stanford Loop directory for a better user experience.
            We apologize for the delay. 🙏🏼
          </p>
          <p style={{ 
            fontSize: 'clamp(0.9rem, 2.5vw, 1.1rem)', 
            marginBottom: '2rem', 
            textAlign: 'center',
            color: '#8E413A',
            fontWeight: 500,
            padding: '0 1rem'
          }}>
            Check back tomorrow for results.
          </p>
          <a 
            href="https://form.typeform.com/to/GOJbAeuy"
            target="_blank"
            rel="noopener noreferrer"
            style={{
              padding: '0.8rem 1.5rem',
              backgroundColor: '#8E413A',
              color: '#F5F0E6',
              textDecoration: 'none',
              borderRadius: '8px',
              fontSize: 'clamp(0.9rem, 2.5vw, 1.1rem)',
              fontWeight: 500,
              fontFamily: '"Libre Bodoni", serif',
              cursor: 'pointer',
              transition: 'transform 0.2s ease-in-out',
              width: '250px',
              textAlign: 'center',
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              boxSizing: 'border-box'
            }}
          >
            Join Stanford Loop
          </a>
        </div>
      </div>
    </>
  );
};

export default MaintenancePage; 