/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // Cove brand colors from iOS app (exact match)
        primary: '#F5F0E6', // Primary light (cream/beige)
        'primary-dark': '#5E1C1D', // Primary dark (dark reddish-brown)
        'faf8f4': '#FAF8F4', // Background color
        'k292929': '#292929', // Dark text
        'k6F6F73': '#6F6F73', // Secondary text
        'k171719': '#171719', // Very dark text
        'k262627': '#262627', // Dark gray
        'f3f3f3': '#F3F3F3', // Light gray
        'kE8DFCB': '#E8DFCB', // Light cream
        gray: {
          100: '#F5F5F5',
          200: '#E5E5E5',
          300: '#D4D4D4',
          400: '#A3A3A3',
          500: '#737373',
          600: '#525252',
          700: '#404040',
          800: '#262626',
          900: '#171717',
        },
      },
      fontFamily: {
        'libre-bodoni': ['Libre Bodoni', 'serif'],
        'league-spartan': ['League Spartan', 'sans-serif'],
      },
      fontSize: {
        'display': ['2.5rem', { lineHeight: '1.2' }],
        'headline': ['2rem', { lineHeight: '1.3' }],
        'title': ['1.5rem', { lineHeight: '1.4' }],
        'body': ['1rem', { lineHeight: '1.5' }],
        'caption': ['0.875rem', { lineHeight: '1.4' }],
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
      },
      borderRadius: {
        'xl': '1rem',
        '2xl': '1.5rem',
      },
      boxShadow: {
        'cove': '0 8px 16px rgba(0, 0, 0, 0.1)',
        'cove-hover': '0 12px 24px rgba(0, 0, 0, 0.15)',
      },
    },
  },
  plugins: [],
}; 