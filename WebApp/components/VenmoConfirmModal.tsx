'use client';

import { useState } from 'react';
import { X } from 'lucide-react';

interface VenmoConfirmModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  paymentHandle: string;
  ticketPrice: number;
}

export default function VenmoConfirmModal({ 
  isOpen, 
  onClose, 
  onConfirm, 
  paymentHandle, 
  ticketPrice 
}: VenmoConfirmModalProps) {
  const [isLoading, setIsLoading] = useState(false);

  const handleConfirm = async () => {
    setIsLoading(true);
    try {
      await onConfirm();
    } finally {
      setIsLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl w-full max-w-md overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-6">
          <div className="flex-1"></div>
          <h2 className="font-libre-bodoni text-xl text-[#5E1C1D] text-center flex-1">confirm payment</h2>
          <div className="flex-1 flex justify-end">
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-full bg-[#5E1C1D] text-white flex items-center justify-center hover:bg-[#4A1718] transition-colors"
            >
              <X size={16} />
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="px-6 pb-6">
          <div className="text-center space-y-4">
            <div className="flex items-center justify-center gap-4 mb-6">
              <img src="/ticket.svg" alt="Ticket" className="w-8 h-8" />
              <span className="font-libre-bodoni text-lg font-semibold text-[#5E1C1D]">
                ${ticketPrice.toFixed(2)}
              </span>
            </div>
            
            <p className="font-libre-bodoni text-lg text-[#2D2D2D]">
              Have you sent payment to <span className="font-semibold">@{paymentHandle}</span>?
            </p>
            
            <p className="font-libre-bodoni text-sm text-[#8B8B8B]">
              Please confirm you've sent the payment before RSVPing
            </p>
          </div>

          {/* Buttons */}
          <div className="flex gap-4 mt-8">
            <button
              onClick={onClose}
              disabled={isLoading}
              className="flex-1 py-3 px-6 bg-gray-100 text-[#2D2D2D] rounded-lg font-libre-bodoni text-lg font-medium hover:bg-gray-200 transition-colors disabled:opacity-50"
            >
              no, not yet
            </button>
            <button
              onClick={handleConfirm}
              disabled={isLoading}
              className="flex-1 py-3 px-6 bg-[#5E1C1D] text-white rounded-lg font-libre-bodoni text-lg font-medium hover:bg-[#4A1718] transition-colors disabled:opacity-50"
            >
              {isLoading ? 'rsvping...' : 'yes, i paid'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
} 