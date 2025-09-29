'use client';

import { useState } from 'react';
import { X } from 'lucide-react';
import { EventPricingTier } from '@/types/event';

interface VenmoConfirmModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  paymentHandle: string;
  ticketPrice?: number;
  pricingTiers?: EventPricingTier[];
  useTieredPricing?: boolean;
}

export default function VenmoConfirmModal({ 
  isOpen, 
  onClose, 
  onConfirm, 
  paymentHandle, 
  ticketPrice,
  pricingTiers,
  useTieredPricing
}: VenmoConfirmModalProps) {
  const [isLoading, setIsLoading] = useState(false);
  
  // Helper function to map tier names to display names
  const getTierDisplayName = (tierType: string) => {
    switch (tierType.toLowerCase()) {
      case 'early bird':
        return 'Early Bird';
      case 'regular':
        return 'Tier 1';
      case 'last minute':
        return 'Tier 2';
      default:
        return tierType;
    }
  };

  // Find the lowest available tier (first tier with spots left)
  const getLowestAvailableTier = () => {
    if (!useTieredPricing || !pricingTiers || pricingTiers.length === 0) {
      return null;
    }
    
    const sortedTiers = pricingTiers.sort((a, b) => a.sortOrder - b.sortOrder);
    return sortedTiers.find(tier => tier.spotsLeft === undefined || tier.spotsLeft > 0) || null;
  };

  const lowestAvailableTier = getLowestAvailableTier();

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
            {/* Pricing Display - Tiered or Single */}
            {useTieredPricing && pricingTiers && pricingTiers.length > 0 ? (
              <div className="space-y-3 mb-6">
                <div className="flex items-center justify-center gap-3 mb-4">
                  <img src="/ticket.svg" alt="Ticket" className="w-6 h-6" />
                  <span className="font-libre-bodoni text-lg font-semibold text-[#5E1C1D]">
                    {lowestAvailableTier ? 'Current Ticket Price' : 'Sold Out'}
                  </span>
                </div>
                
                {lowestAvailableTier && (
                  <div className="flex items-center justify-center gap-4 mb-4 p-4 bg-[#5E1C1D]/10 rounded-lg border-2 border-[#5E1C1D]">
                    <img src="/ticket.svg" alt="Ticket" className="w-6 h-6" />
                    <div className="text-center">
                      <div className="font-libre-bodoni text-lg font-semibold text-[#5E1C1D]">
                        {getTierDisplayName(lowestAvailableTier.tierType)}
                      </div>
                      <div className="font-libre-bodoni text-xl font-bold text-[#5E1C1D]">
                        ${lowestAvailableTier.price.toFixed(2)}
                      </div>
                    </div>
                  </div>
                )}
                
                {/* Show all tiers for context */}
                <div className="space-y-2">
                  <div className="font-libre-bodoni text-sm text-[#8B8B8B] mb-2">Pricing tiers:</div>
                  {pricingTiers
                    .sort((a, b) => a.sortOrder - b.sortOrder)
                    .map((tier) => {
                      const isAvailable = tier.spotsLeft === undefined || tier.spotsLeft > 0;
                      const isCurrentTier = lowestAvailableTier?.id === tier.id;
                      
                      return (
                        <div 
                          key={tier.id}
                          className={`flex items-center justify-between p-3 rounded-lg border ${
                            isCurrentTier 
                              ? 'bg-[#5E1C1D]/10 border-[#5E1C1D]' 
                              : isAvailable
                              ? 'bg-gray-50 border-gray-200'
                              : 'bg-gray-100 border-gray-300'
                          }`}
                        >
                          <span className={`font-libre-bodoni text-base ${
                            isAvailable ? 'text-[#5E1C1D]' : 'text-gray-400'
                          }`}>
                            {getTierDisplayName(tier.tierType)}
                            {isCurrentTier}
                          </span>
                          <div className="text-right">
                            <div className={`font-libre-bodoni font-semibold text-base ${
                              isAvailable ? 'text-[#5E1C1D]' : 'text-gray-400'
                            }`}>
                              ${tier.price.toFixed(2)}
                            </div>
                            {tier.spotsLeft !== undefined && tier.spotsLeft !== null && (
                              <div className={`font-libre-bodoni text-sm ${
                                tier.spotsLeft > 0 ? 'text-green-600' : 'text-red-600'
                              }`}>
                                {tier.spotsLeft > 0 ? `${tier.spotsLeft} left` : 'sold out'}
                              </div>
                            )}
                          </div>
                        </div>
                      );
                    })
                  }
                </div>
              </div>
            ) : ticketPrice && (
              <div className="flex items-center justify-center gap-4 mb-6">
                <img src="/ticket.svg" alt="Ticket" className="w-8 h-8" />
                <span className="font-libre-bodoni text-lg font-semibold text-[#5E1C1D]">
                  ${ticketPrice.toFixed(2)}
                </span>
              </div>
            )}
            
            <p className="font-libre-bodoni text-lg text-[#2D2D2D]">
              Have you sent{' '}
              {useTieredPricing && lowestAvailableTier ? (
                <span className="font-semibold">${lowestAvailableTier.price.toFixed(2)}</span>
              ) : useTieredPricing ? (
                <span className="font-semibold">payment</span>
              ) : (
                <span className="font-semibold">${(ticketPrice || 0).toFixed(2)}</span>
              )}{' '}
              to <span className="font-semibold">@{paymentHandle}</span>?
            </p>
            
            <p className="font-libre-bodoni text-sm text-[#8B8B8B] mt-4">
              Your spot won't be secured until payment is received. Venmo to secure this price now.
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
              disabled={isLoading || (useTieredPricing && !lowestAvailableTier)}
              className="flex-1 py-3 px-6 bg-[#5E1C1D] text-white rounded-lg font-libre-bodoni text-lg font-medium hover:bg-[#4A1718] transition-colors disabled:opacity-50"
            >
              {isLoading 
                ? 'rsvping...' 
                : (useTieredPricing && !lowestAvailableTier)
                ? 'sold out'
                : 'yes, i paid'
              }
            </button>
          </div>
        </div>
      </div>
    </div>
  );
} 