'use client';

import { Libre_Bodoni, Berkshire_Swash } from 'next/font/google'
import { useState, ChangeEvent, useEffect } from 'react'
import NavigationMenu from '../components/NavigationMenu'

interface FormData {
  firstName: string;
  lastName: string;
  phoneNumber: string;
  city: string;
  almaMater: string;
}

interface FormErrors {
  firstName: boolean;
  lastName: boolean;
  phoneNumber: boolean;
  city: boolean;
  almaMater: boolean;
}

const berkshireSwash = Berkshire_Swash({
  weight: ['400'],
  subsets: ['latin'],
  style: ['normal']
})

const libreBodoni = Libre_Bodoni({
  weight: ['400', '700'],
  subsets: ['latin'],
  style: ['normal', 'italic']
})

export default function Home() {
  const [showForm, setShowForm] = useState(false);
  const [buttonAnimationComplete, setButtonAnimationComplete] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [imagesLoaded, setImagesLoaded] = useState(false);
  const [formData, setFormData] = useState<FormData>({
    firstName: '',
    lastName: '',
    phoneNumber: '',
    city: '',
    almaMater: ''
  });
  const [formErrors, setFormErrors] = useState<FormErrors>({
    firstName: false,
    lastName: false,
    phoneNumber: false,
    city: false,
    almaMater: false
  });

  /**
   * Preloads all 14 background images before starting the animation
   */
  useEffect(() => {
    // Create a function to handle image loading
    const handleImageLoad = () => {
      console.log('All images loaded via event listener');
      setImagesLoaded(true);
    };

    // Create a function to handle image errors
    const handleImageError = (event: Event) => {
      const img = event.target as HTMLImageElement;
      console.error(`Failed to load image: ${img.src}`);
    };

    // Create and load all images
    const imageUrls = Array.from({ length: 14 }, (_, i) => `/image${i + 1}.svg`);
    let loadedCount = 0;
    
    // Create a container for all images (hidden)
    const imageContainer = document.createElement('div');
    imageContainer.style.display = 'none';
    document.body.appendChild(imageContainer);
    
    // Load each image
    imageUrls.forEach(url => {
      const img = new Image();
      img.src = url;
      
      // Add event listeners
      img.addEventListener('load', () => {
        loadedCount++;
        console.log(`Loaded image ${loadedCount}/14`);
        
        // If all images are loaded, trigger the animation
        if (loadedCount === imageUrls.length) {
          handleImageLoad();
        }
      });
      
      img.addEventListener('error', handleImageError);
      
      // Add to container
      imageContainer.appendChild(img);
    });
    
    // Cleanup function
    return () => {
      // Remove event listeners and container
      imageContainer.remove();
    };
  }, []);

  /**
   * Validates the form data by checking if all required fields are filled
   * and if the phone number has the correct format (10 digits)
   * @returns boolean indicating if the form is valid
   */
  const validateForm = () => {
    // Count digits in phone number
    const phoneDigits = formData.phoneNumber.replace(/\D/g, '').length;
    
    const newErrors = {
      firstName: !formData.firstName.trim(),
      lastName: !formData.lastName.trim(),
      phoneNumber: !formData.phoneNumber.trim() || phoneDigits < 10,
      city: !formData.city.trim(),
      almaMater: !formData.almaMater.trim()
    };
    setFormErrors(newErrors);
    return !Object.values(newErrors).some(error => error);
  };

  /**
   * Handles the form submission when the button is clicked
   * Validates the form data and submits it to the Notion database
   * Triggers animations based on submission state
   */
  const handleButtonClick = async () => {
    if (buttonAnimationComplete && !submitted) {
      if (validateForm()) {
        // Set submitted to true immediately to trigger animations
        setSubmitted(true);
        
        try {
          // Submit to Notion database
          console.log('Client - Attempting to create Notion page...');
          console.log('Client - Form data:', formData);
          
          const response = await fetch('/api/notion', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(formData),
          });

          const result = await response.json();
          
          if (!response.ok) {
            console.error('Client - API Error Response:', result);
            throw new Error(result.error || 'Failed to submit form');
          }

          console.log('Client - Success Response:', result);
        } catch (error) {
          console.error('Client - Detailed Notion error:', error);
          if (error instanceof Error) {
            console.error('Client - Error message:', error.message);
            console.error('Client - Error stack:', error.stack);
          }
        }
      } else {
        console.log('Some fields are empty!');
      }
    }
  };

  /**
   * Handles input changes for all form fields
   * Applies specific formatting and validation rules for each field:
   * - Age: Only numbers, max 3 digits
   * - Phone: Formats as XXX-XXX-XXXX
   * - Name: Only letters, spaces, and hyphens
   * - City: Only letters, spaces, and hyphens
   * @param e ChangeEvent from the input element
   */
  const handleInputChange = (e: ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    
    // Special handling for phone number
    if (name === 'phoneNumber') {
      // Format phone number as user types
      const cleaned = value.replace(/\D/g, '');
      const match = cleaned.match(/^(\d{0,3})(\d{0,3})(\d{0,4})$/);
      if (match) {
        const formatted = match[1] + (match[2] ? '-' + match[2] : '') + (match[3] ? '-' + match[3] : '');
        setFormData(prev => ({
          ...prev,
          [name]: formatted
        }));
      }
    } else if (name === 'firstName' || name === 'lastName') {
      // Only allow letters, spaces, and hyphens for names
      if (value === '' || /^[a-zA-Z\s-]+$/.test(value)) {
        setFormData(prev => ({
          ...prev,
          [name]: value
        }));
      }
    } else if (name === 'city') {
      // Allow letters, spaces, and hyphens for city names
      if (value === '' || /^[a-zA-Z\s-]+$/.test(value)) {
        setFormData(prev => ({
          ...prev,
          [name]: value
        }));
      }
    } else if (name === 'almaMater') {
      // Allow letters, spaces, and hyphens for almaMater
      if (value === '' || /^[a-zA-Z\s-]+$/.test(value)) {
        setFormData(prev => ({
          ...prev,
          [name]: value
        }));
      }
    } else {
      setFormData(prev => ({
        ...prev,
        [name]: value
      }));
    }
  };

  return (
    <div className="relative min-h-screen w-full overflow-hidden">
      {/* Navigation Menu */}
      <NavigationMenu />
      
      {/* Background image container */}
      <div className="fixed inset-0 w-full h-full">
        <div 
          className={`absolute inset-0 w-full h-full bg-[url('/image1.svg')] ${imagesLoaded ? 'animate-backgroundRotate' : ''}`} 
        />
      </div>

      {/* Content container with semi-transparent overlay - fades in after 2000ms */}
      <div className="relative z-10 flex items-center justify-center min-h-screen w-full bg-white/60 dark:bg-[#7a3131ff]/80 opacity-0 fade-in delay-2000">
        <div className="flex flex-col items-center">
          {/* Logo and subtitle container */}
          <div>
            {/* Title fades in after 1000ms */}
            <h1 className={`${berkshireSwash.className} text-9xl text-[#7a3131ff] dark:text-white text-center opacity-0 fade-in delay-1000 transform -skew-x-12`}>
              cove
            </h1>
            {/* Subtitle fades in too */}
            <p className={`${libreBodoni.className} text-xl text-center text-[#7a3131ff] dark:text-white font-bold opacity-0 fade-in delay-1000`}>
              events for young alumni
            </p>
          </div>
          
          {/* Form or Button container */}
          <div className="mt-10">
            {!showForm ? (
              <button 
                onClick={() => setShowForm(true)}
                className={`${libreBodoni.className} px-11 py-3 bg-[#7a3131ff] text-white dark:bg-white dark:text-black rounded-md font-bold hover:bg-[#4a1919] dark:hover:bg-gray-200 transition-colors fade-in delay-1000`} 
              >
                join the waitlist
              </button>
            ) : (
              <div className="relative">
                {!submitted ? (
                  <>
                    <button 
                      onAnimationEnd={() => setButtonAnimationComplete(true)}
                      onClick={handleButtonClick}
                      className={`${libreBodoni.className} px-11 py-3 bg-[#7a3131ff] text-white dark:bg-white dark:text-black rounded-md font-bold float-down absolute ${buttonAnimationComplete ? 'hover:bg-[#3a1010] dark:hover:bg-gray-200 transition-colors duration-300' : ''}`}
                      style={{ transform: buttonAnimationComplete ? 'translateY(400px)' : '' }}
                    >
                      join the waitlist
                    </button>
                    <form className={`flex flex-col gap-4 form-fade-in ${submitted ? 'fade-out' : ''}`}>
                      <p className={`${libreBodoni.className} text-white/80 text-sm text-center mb-2`}>
                        your information is private.
                      </p>
                      <input
                        type="text"
                        name="firstName"
                        value={formData.firstName}
                        onChange={handleInputChange}
                        placeholder="first name"
                        className={`${libreBodoni.className} px-4 py-2 rounded-md bg-[#7a3131] text-white placeholder-white/70 border ${formErrors.firstName ? 'border-red-500' : 'border-white/20'} focus:outline-none focus:ring-2 focus:ring-white/50`}
                      />
                      <input
                        type="text"
                        name="lastName"
                        value={formData.lastName}
                        onChange={handleInputChange}
                        placeholder="last name"
                        className={`${libreBodoni.className} px-4 py-2 rounded-md bg-[#7a3131] text-white placeholder-white/70 border ${formErrors.lastName ? 'border-red-500' : 'border-white/20'} focus:outline-none focus:ring-2 focus:ring-white/50`}
                      />
                      <input
                        type="text"
                        name="phoneNumber"
                        value={formData.phoneNumber}
                        onChange={handleInputChange}
                        placeholder="phone number"
                        className={`${libreBodoni.className} px-4 py-2 rounded-md bg-[#7a3131] text-white placeholder-white/70 border ${formErrors.phoneNumber ? 'border-red-500' : 'border-white/20'} focus:outline-none focus:ring-2 focus:ring-white/50`}
                      />
                      <input
                        type="text"
                        name="city"
                        value={formData.city}
                        onChange={handleInputChange}
                        placeholder="city"
                        className={`${libreBodoni.className} px-4 py-2 rounded-md bg-[#7a3131] text-white placeholder-white/70 border ${formErrors.city ? 'border-red-500' : 'border-white/20'} focus:outline-none focus:ring-2 focus:ring-white/50`}
                      />
                      <input
                        type="text"
                        name="almaMater"
                        value={formData.almaMater}
                        onChange={handleInputChange}
                        placeholder="alma mater"
                        className={`${libreBodoni.className} px-4 py-2 rounded-md bg-[#7a3131] text-white placeholder-white/70 border ${formErrors.almaMater ? 'border-red-500' : 'border-white/20'} focus:outline-none focus:ring-2 focus:ring-white/50`}
                      />
                    </form>
                  </>
                ) : (
                  <div className="flex flex-col items-center gap-4 fade-in">
                    <h2 className={`${libreBodoni.className} text-4xl text-[#7a3131ff] dark:text-white text-center`}>
                      you&apos;re in!
                    </h2>
                    <p className={`${libreBodoni.className} text-xl text-center text-[#7a3131ff] dark:text-white`}>
                      stay tuned for a message from us.
                    </p>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
} 