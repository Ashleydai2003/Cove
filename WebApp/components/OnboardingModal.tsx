'use client';

import { useState, useEffect } from 'react';
import { X } from 'lucide-react';
import { auth } from '../lib/firebase';
import {
  PhoneAuthProvider,
  signInWithCredential,
  RecaptchaVerifier,
  signInWithPhoneNumber
} from 'firebase/auth';

interface OnboardingModalProps {
  isOpen: boolean;
  onClose: () => void;
  onComplete: (userId: string) => void;
  originalAction?: string; // e.g., "RSVP to this event"
}

type OnboardingStep = 'phone' | 'otp' | 'onboarding';

export default function OnboardingModal({ isOpen, onClose, onComplete, originalAction }: OnboardingModalProps) {
  const [step, setStep] = useState<OnboardingStep>('phone');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [otpCode, setOtpCode] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [verificationId, setVerificationId] = useState<string | null>(null);
  const [recaptchaVerifier, setRecaptchaVerifier] = useState<RecaptchaVerifier | null>(null);
  const [recaptchaCompleted, setRecaptchaCompleted] = useState(false);

  // Onboarding form data
  const [formData, setFormData] = useState({
    name: '',
    birthdate: '',
    almaMater: '',
    gradYear: '',
    hobbies: [] as string[]
  });

  // Initialize reCAPTCHA verifier
  useEffect(() => {
    if (typeof window !== 'undefined' && !recaptchaVerifier && isOpen) {
      // Wait for the modal to be open and DOM to be ready
      const initializeRecaptcha = () => {
        try {
          console.log('Initializing reCAPTCHA verifier...');
          
          // Check if the container exists
          const container = document.getElementById('recaptcha-container');
          if (!container) {
            console.log('reCAPTCHA container not found, retrying...');
            // Retry after a short delay
            setTimeout(initializeRecaptcha, 200);
            return;
          }
          
          // Clear any existing content
          container.innerHTML = '';
          
          const verifier = new RecaptchaVerifier(auth, 'recaptcha-container', {
            'size': 'normal',
            'callback': () => {
              console.log('reCAPTCHA callback executed');
              setRecaptchaCompleted(true);
            },
            'expired-callback': () => {
              console.log('reCAPTCHA expired');
              setRecaptchaCompleted(false);
            }
          });
          console.log('reCAPTCHA verifier created successfully');
          setRecaptchaVerifier(verifier);
        } catch (error) {
          console.error('Failed to initialize reCAPTCHA:', error);
          setError('Failed to initialize verification. Please refresh the page.');
        }
      };
      
      // Start initialization
      initializeRecaptcha();
    }
    
    // Cleanup when modal closes
    return () => {
      if (!isOpen) {
        if (recaptchaVerifier) {
          try {
            recaptchaVerifier.clear();
          } catch (error) {
            console.log('Error clearing reCAPTCHA:', error);
          }
        }
        setRecaptchaVerifier(null);
        setRecaptchaCompleted(false);
        setStep('phone');
        setError('');
      }
    };
  }, [recaptchaVerifier, isOpen]);

  const handlePhoneSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      // Use existing reCAPTCHA verifier
      if (!recaptchaVerifier) {
        setError('Please complete the reCAPTCHA verification first.');
        return;
      }
      
      let verifier = recaptchaVerifier;

      // Format phone number for Firebase (remove all non-digits and ensure it starts with +)
      let formattedPhone = phoneNumber.replace(/\D/g, ''); // Remove all non-digits
      
      // If it doesn't start with +, add +1 for US numbers
      if (!formattedPhone.startsWith('+')) {
        // If it's 10 digits, assume US number
        if (formattedPhone.length === 10) {
          formattedPhone = '+1' + formattedPhone;
        } else if (formattedPhone.length === 11 && formattedPhone.startsWith('1')) {
          formattedPhone = '+' + formattedPhone;
        } else {
          setError('Please enter a valid US phone number');
          return;
        }
      }

      console.log('Sending OTP to:', formattedPhone);
      console.log('Current domain:', window.location.hostname);

      // Send OTP using Firebase
      const confirmationResult = await signInWithPhoneNumber(auth, formattedPhone, verifier);
      setVerificationId(confirmationResult.verificationId);
      setStep('otp');
    } catch (err: any) {
      console.error('Firebase phone auth error:', err);
      
      // Handle specific Firebase errors
      if (err.code === 'auth/captcha-check-failed') {
        setError('Domain not authorized. Please contact support or try from a different domain.');
      } else if (err.code === 'auth/invalid-app-credential') {
        setError('reCAPTCHA verification failed. Please refresh the page and try again.');
      } else if (err.code === 'auth/invalid-phone-number') {
        setError('Please enter a valid phone number.');
      } else if (err.code === 'auth/too-many-requests') {
        setError('Too many attempts. Please try again later.');
      } else {
        setError(err.message || 'Failed to send OTP. Please try again.');
      }
    } finally {
      setIsLoading(false);
    }
  };

  const handleOtpSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      if (!verificationId) {
        setError('Verification ID not found. Please try sending the code again.');
        return;
      }

      // Verify OTP using Firebase
      const credential = PhoneAuthProvider.credential(verificationId, otpCode);
      const userCredential = await signInWithCredential(auth, credential);

      // Get the Firebase ID token
      const idToken = await userCredential.user.getIdToken();

      // Call backend login with the ID token
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include', // Include cookies
        body: JSON.stringify({ idToken })
      });

      if (response.ok) {
        const data = await response.json();
        if (data.user?.onboarding) {
          setStep('onboarding');
        } else {
          // User already completed onboarding, complete the original action
          onComplete(data.user?.uid || '');
        }
      } else {
        const data = await response.json();
        setError(data.message || 'Backend authentication failed');
      }
    } catch (err: any) {
      console.error('OTP verification error:', err);
      setError(err.message || 'Invalid verification code. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleOnboardingSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const response = await fetch('/api/onboard', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include', // Include cookies
        body: JSON.stringify({
          name: formData.name,
          birthdate: formData.birthdate,
          almaMater: formData.almaMater,
          gradYear: formData.gradYear,
          hobbies: formData.hobbies
        })
      });

      if (response.ok) {
        const data = await response.json();
        onComplete(data.userId);
      } else {
        const data = await response.json();
        setError(data.message || 'Failed to complete onboarding');
      }
    } catch (err) {
      setError('Network error. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const addHobby = (hobby: string) => {
    if (hobby && !formData.hobbies.includes(hobby)) {
      setFormData(prev => ({ ...prev, hobbies: [...prev.hobbies, hobby] }));
    }
  };

  const removeHobby = (hobby: string) => {
    setFormData(prev => ({ ...prev, hobbies: prev.hobbies.filter(h => h !== hobby) }));
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-[#F5F0E6] rounded-lg shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="relative p-6">
          <h2 className="text-6xl font-libre-bodoni text-[#5E1C1D] text-center font-bold">
            cove
          </h2>
          <button
            onClick={onClose}
            className="absolute top-4 right-4 w-8 h-8 bg-[#5E1C1D] rounded-full flex items-center justify-center text-white hover:bg-[#4A1718] transition-colors"
          >
            <X size={16} />
          </button>
        </div>

        {/* Content */}
        <div className="px-6 pb-6">
          {error && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
              {error}
            </div>
          )}

          {/* Phone Number Step */}
          {step === 'phone' && (
            <form onSubmit={handlePhoneSubmit} className="space-y-6">
              <div>
                <input
                  type="tel"
                  value={phoneNumber}
                  onChange={(e) => setPhoneNumber(e.target.value)}
                  placeholder="phone number"
                  className="w-full px-0 py-3 border-0 border-b-2 border-gray-300 focus:border-[#5E1C1D] focus:outline-none text-lg font-libre-bodoni bg-transparent"
                  required
                />
              </div>
              
              <button
                type="submit"
                disabled={isLoading}
                className="w-full bg-white text-[#5E1C1D] py-4 px-6 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-all font-libre-bodoni text-lg font-medium"
              >
                {isLoading ? 'Sending...' : 'send code'}
              </button>
            </form>
          )}

          {/* OTP Step */}
          {step === 'otp' && (
            <form onSubmit={handleOtpSubmit} className="space-y-6">
              <div>
                <input
                  type="text"
                  value={otpCode}
                  onChange={(e) => setOtpCode(e.target.value)}
                  placeholder="verification code"
                  className="w-full px-0 py-3 border-0 border-b-2 border-gray-300 focus:border-[#5E1C1D] focus:outline-none text-lg font-libre-bodoni bg-transparent"
                  required
                />
              </div>
              <button
                type="submit"
                disabled={isLoading}
                className="w-full bg-white text-[#5E1C1D] py-4 px-6 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-all font-libre-bodoni text-lg font-medium"
              >
                {isLoading ? 'Verifying...' : 'verify code'}
              </button>
              <button
                type="button"
                onClick={() => {
                  setStep('phone');
                  setRecaptchaCompleted(false);
                  setRecaptchaVerifier(null);
                }}
                className="w-full text-[#5E1C1D] hover:text-[#4A1718] text-sm"
              >
                back to phone number
              </button>
            </form>
          )}

          {/* Onboarding Step */}
          {step === 'onboarding' && (
            <form onSubmit={handleOnboardingSubmit} className="space-y-6">
              <div>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                  placeholder="full name"
                  className="w-full px-0 py-3 border-0 border-b-2 border-gray-300 focus:border-[#5E1C1D] focus:outline-none text-lg font-libre-bodoni bg-transparent"
                  required
                />
              </div>

              <div>
                <input
                  type="date"
                  value={formData.birthdate}
                  onChange={(e) => setFormData(prev => ({ ...prev, birthdate: e.target.value }))}
                  className="w-full px-0 py-3 border-0 border-b-2 border-gray-300 focus:border-[#5E1C1D] focus:outline-none text-lg font-libre-bodoni bg-transparent"
                  required
                />
              </div>

              <div>
                <input
                  type="text"
                  value={formData.almaMater}
                  onChange={(e) => setFormData(prev => ({ ...prev, almaMater: e.target.value }))}
                  placeholder="alma mater"
                  className="w-full px-0 py-3 border-b-2 border-gray-300 focus:border-[#5E1C1D] focus:outline-none text-lg font-libre-bodoni bg-transparent"
                  required
                />
              </div>

              <div>
                <input
                  type="text"
                  value={formData.gradYear}
                  onChange={(e) => setFormData(prev => ({ ...prev, gradYear: e.target.value }))}
                  placeholder="graduation year"
                  className="w-full px-0 py-3 border-0 border-b-2 border-gray-300 focus:border-[#5E1C1D] focus:outline-none text-lg font-libre-bodoni bg-transparent"
                  required
                />
              </div>

              <button
                type="submit"
                disabled={isLoading}
                className="w-full bg-white text-[#5E1C1D] py-4 px-6 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-all font-libre-bodoni text-lg font-medium"
              >
                {isLoading ? 'Creating...' : "let's go"}
              </button>
            </form>
          )}
        </div>
        
        {/* reCAPTCHA container */}
        {step === 'phone' && !recaptchaCompleted && (
          <div id="recaptcha-container" className="flex justify-center mt-4 p-2 transform scale-90"></div>
        )}
      </div>
    </div>
  );
} 