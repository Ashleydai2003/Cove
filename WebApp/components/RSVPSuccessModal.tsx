'use client';

import { CheckCircle } from 'lucide-react';

interface RSVPSuccessModalProps {
  isOpen: boolean;
  onClose: () => void;
  eventName: string;
}

export default function RSVPSuccessModal({ isOpen, onClose, eventName }: RSVPSuccessModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl max-w-md w-full p-8 text-center">
        {/* Success Icon */}
        <div className="flex justify-center mb-6">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center">
            <CheckCircle className="w-8 h-8 text-green-600" />
          </div>
        </div>

        {/* Success Message */}
        <h2 className="font-libre-bodoni text-2xl text-[#2D2D2D] mb-4">
          RSVP Sent!
        </h2>
        
        <p className="font-libre-bodoni text-base text-[#8B8B8B] mb-6">
          Your RSVP for <span className="font-semibold text-[#2D2D2D]">"{eventName}"</span> has been sent to the host for approval.
        </p>

        <p className="font-libre-bodoni text-sm text-[#A8A8A8] mb-8">
          You'll be notified once the host approves your RSVP.
        </p>

        {/* Close Button */}
        <button
          onClick={onClose}
          className="w-full bg-[#5E1C1D] text-white py-3 px-6 rounded-lg font-libre-bodoni text-lg hover:bg-[#4A1718] transition-colors"
        >
          Got it!
        </button>
      </div>
    </div>
  );
} 