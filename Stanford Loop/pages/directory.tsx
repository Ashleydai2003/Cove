import React, { useEffect, useState } from 'react';
import Head from 'next/head';
import Image from 'next/image';
import Link from 'next/link';

interface DirectoryEntry {
  response_id: string;
  submitted_at: string;
  firstName: string;
  lastName: string;
  currentAffiliation: string;
  city: string;
  otherCity: string | null;
  duration: string;
  roommates: boolean;
  waitlistInterest: boolean;
  friendEmails: string[];
  contact?: {
    fullName: string;
    contactMethod: string;
    linkedinUrl?: string;
    phoneNumber?: string;
    stanfordEmail?: string;
    instagramHandle?: string;
  };
}

// Helper function to capitalize words
function capitalize(str: string): string {
  return str
    .split(' ')
    .map(word => {
      // Special case for D.C.
      if (word.toLowerCase() === 'd.c.') return 'D.C.';
      return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
    })
    .join(' ');
}

const DirectoryPage = () => {
  const [entries, setEntries] = useState<DirectoryEntry[]>([]);
  const [filtered, setFiltered] = useState<DirectoryEntry[]>([]);
  const [city, setCity] = useState('');
  const [affiliation, setAffiliation] = useState('');
  const [duration, setDuration] = useState('');
  const [roommates, setRoommates] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [showContactForm, setShowContactForm] = useState(false);
  const [isFading, setIsFading] = useState(false);

  useEffect(() => {
    if (showContactForm) {
      // Load Typeform embed script only when form should be shown
      const script = document.createElement('script');
      script.src = '//embed.typeform.com/next/embed.js';
      script.async = true;
      document.body.appendChild(script);

      return () => {
        document.body.removeChild(script);
      };
    }
  }, [showContactForm]);

  const handleContactButtonClick = () => {
    setIsFading(true);
    setTimeout(() => {
      setShowContactForm(true);
    }, 500);
  };

  useEffect(() => {
    async function fetchData() {
      setLoading(true);
      try {
        // Fetch directory entries
        const res = await fetch('/api/submit');
        const data = await res.json();

        // Fetch contact information
        const contactRes = await fetch('/api/contact');
        const contactData = await contactRes.json();

        // Capitalize names and cities when setting entries
        const processedEntries = (data.responses || []).map((entry: DirectoryEntry) => {
          const capitalizedEntry = {
            ...entry,
            firstName: capitalize(entry.firstName),
            lastName: capitalize(entry.lastName),
            city: capitalize(entry.city),
            otherCity: entry.otherCity ? capitalize(entry.otherCity) : null
          };

          // Find matching contact information
          const matchingContact = contactData.responses?.find((contact: any) => {
            const contactName = contact.fullName.toLowerCase();
            const entryName = `${capitalizedEntry.firstName} ${capitalizedEntry.lastName}`.toLowerCase();
            return contactName === entryName;
          });

          if (matchingContact) {
            capitalizedEntry.contact = matchingContact;
          }

          return capitalizedEntry;
        });

        setEntries(processedEntries);
        setFiltered(processedEntries);
      } catch (error) {
        console.error('Error fetching data:', error);
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, []);

  useEffect(() => {
    let filteredEntries = entries;
    if (city) {
      const searchCity = city.toLowerCase();
      filteredEntries = filteredEntries.filter(e => 
        e.city.toLowerCase() === searchCity || 
        (e.otherCity && e.otherCity.toLowerCase() === searchCity)
      );
    }
    if (affiliation) filteredEntries = filteredEntries.filter(e => e.currentAffiliation === affiliation);
    if (duration) filteredEntries = filteredEntries.filter(e => e.duration === duration);
    if (roommates) {
      const lookingForRoommates = roommates === 'Yes';
      filteredEntries = filteredEntries.filter(e => e.roommates === lookingForRoommates);
    }
    setFiltered(filteredEntries);
  }, [city, affiliation, duration, roommates, entries]);

  // Get unique values for filters
  const cities = Array.from(new Set(entries.flatMap(e => [e.city, e.otherCity].filter(Boolean))));
  const affiliations = Array.from(new Set(entries.map(e => e.currentAffiliation)));
  const durations = Array.from(new Set(entries.map(e => e.duration)));

  // Helper function to format contact information
  const formatContactInfo = (entry: DirectoryEntry) => {
    if (!entry.contact) return '';
    
    const { contactMethod, phoneNumber, stanfordEmail, linkedinUrl, instagramHandle } = entry.contact;
    
    switch (contactMethod) {
      case 'Phone Number':
        return phoneNumber || '';
      case 'Stanford Email':
        return stanfordEmail || '';
      case 'LinkedIn URL':
        return linkedinUrl || '';
      case 'Instagram Handle':
        return instagramHandle || '';
      default:
        return '';
    }
  };

  return (
    <>
      <Head>
        <title>Stanford Loop Directory</title>
        <meta property="og:title" content="Stanford Loop Directory"/>
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
        margin: '0 auto',
        opacity: isFading ? 0 : 1,
        transition: 'opacity 0.5s ease-in-out',
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
            marginBottom: '1.5rem', 
            textAlign: 'center',
            padding: '0 1rem'
          }}>
            Stanford Loop Directory
          </h1>
          <div style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '0.5rem',
            marginBottom: '1.5rem',
            width: '100%',
            maxWidth: '600px',
            padding: '0 1rem',
          }}>
            <p style={{ 
              fontSize: 'clamp(0.9rem, 2.5vw, 1.1rem)', 
              textAlign: 'center',
              color: '#8E413A',
              fontWeight: 500,
              marginBottom: '0.5rem'
            }}>
              Want people to reach out? Add your contact information below.
            </p>
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
                width: '250px',
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                boxSizing: 'border-box'
              }}
            >
              Add contact info
            </button>
          </div>
          <div style={{
            display: 'flex',
            gap: '0.5rem',
            marginBottom: '1.5rem',
            flexWrap: 'wrap',
            justifyContent: 'center',
            width: '100%',
            maxWidth: '600px',
            padding: '0 1rem',
          }}>
            <select value={city} onChange={e => setCity(e.target.value)} style={{ 
              padding: '0.5rem', 
              borderRadius: 8, 
              border: '1px solid #8E413A', 
              fontFamily: 'inherit',
              width: '100%',
              maxWidth: '200px',
              fontSize: 'clamp(0.9rem, 2vw, 1rem)'
            }}>
              <option value=''>All Cities</option>
              {cities.map(c => <option key={c} value={c as string}>{c}</option>)}
            </select>
            <select value={affiliation} onChange={e => setAffiliation(e.target.value)} style={{ 
              padding: '0.5rem', 
              borderRadius: 8, 
              border: '1px solid #8E413A', 
              fontFamily: 'inherit',
              width: '100%',
              maxWidth: '200px',
              fontSize: 'clamp(0.9rem, 2vw, 1rem)'
            }}>
              <option value=''>All Affiliations</option>
              {affiliations.map(a => <option key={a} value={a}>{a}</option>)}
            </select>
            <select value={duration} onChange={e => setDuration(e.target.value)} style={{ 
              padding: '0.5rem', 
              borderRadius: 8, 
              border: '1px solid #8E413A', 
              fontFamily: 'inherit',
              width: '100%',
              maxWidth: '200px',
              fontSize: 'clamp(0.9rem, 2vw, 1rem)'
            }}>
              <option value=''>All Durations</option>
              {durations.map(d => <option key={d} value={d}>{d}</option>)}
            </select>
            <select value={roommates} onChange={e => setRoommates(e.target.value)} style={{ 
              padding: '0.5rem', 
              borderRadius: 8, 
              border: '1px solid #8E413A', 
              fontFamily: 'inherit',
              width: '100%',
              maxWidth: '200px',
              fontSize: 'clamp(0.9rem, 2vw, 1rem)'
            }}>
              <option value=''>All Roommate Prefs</option>
              <option value='Yes'>Looking</option>
              <option value='No'>Not Looking</option>
            </select>
          </div>
          {loading ? (
            <div style={{ color: '#8E413A', fontSize: '1.2rem' }}>Loading...</div>
          ) : (
            <div style={{ 
              width: '100%', 
              maxWidth: 900, 
              background: '#fff', 
              borderRadius: 16, 
              boxShadow: '0 2px 12px #8e413a22', 
              padding: '1rem',
              margin: '0 1rem',
              overflowX: 'auto' 
            }}>
              <table style={{ 
                width: '100%', 
                borderCollapse: 'collapse', 
                fontSize: 'clamp(0.8rem, 2vw, 1rem)',
                minWidth: '600px' // Ensure table doesn't get too compressed
              }}>
                <thead>
                  <tr style={{ background: '#F5F0E6', color: '#8E413A' }}>
                    <th style={{ padding: '0.7rem', borderBottom: '2px solid #8E413A', textAlign: 'left' }}>Name</th>
                    <th style={{ padding: '0.7rem', borderBottom: '2px solid #8E413A', textAlign: 'left' }}>Affiliation</th>
                    <th style={{ padding: '0.7rem', borderBottom: '2px solid #8E413A', textAlign: 'left' }}>City</th>
                    <th style={{ padding: '0.7rem', borderBottom: '2px solid #8E413A', textAlign: 'left' }}>Duration</th>
                    <th style={{ padding: '0.7rem', borderBottom: '2px solid #8E413A', textAlign: 'left' }}>Looking for roommates?</th>
                    <th style={{ padding: '0.7rem', borderBottom: '2px solid #8E413A', textAlign: 'left' }}>Contact</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.length === 0 ? (
                    <tr><td colSpan={6} style={{ textAlign: 'center', color: '#8E413A', padding: '2rem' }}>No results found.</td></tr>
                  ) : (
                    filtered.map(entry => (
                      <tr key={entry.response_id} style={{ borderBottom: '1px solid #eee' }}>
                        <td style={{ padding: '0.7rem 0.5rem' }}>{entry.firstName} {entry.lastName}</td>
                        <td style={{ padding: '0.7rem 0.5rem' }}>{entry.currentAffiliation}</td>
                        <td style={{ padding: '0.7rem 0.5rem' }}>{entry.city === 'Other' && entry.otherCity ? entry.otherCity : entry.city}</td>
                        <td style={{ padding: '0.7rem 0.5rem' }}>{entry.duration}</td>
                        <td style={{ padding: '0.7rem 0.5rem' }}>{entry.roommates ? 'Looking' : 'Not Looking'}</td>
                        <td style={{ padding: '0.7rem 0.5rem' }}>{formatContactInfo(entry)}</td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
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

export default DirectoryPage; 