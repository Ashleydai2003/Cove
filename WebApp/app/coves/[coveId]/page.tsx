'use client';

import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { checkAuthStatus } from '@/lib/auth';
import CoveDetailCard from '@/components/CoveDetailCard';

interface Cove {
  id: string;
  name: string;
  description: string;
  location: string;
  createdAt: string;
  creator: {
    id: string;
    name: string;
  };
  coverPhoto: {
    id: string;
    url: string;
  } | null;
  stats: {
    memberCount: number;
    eventCount: number;
  };
}

export default function CovePage() {
  const params = useParams();
  const coveId = params.coveId as string;
  
  const [cove, setCove] = useState<Cove | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState<boolean | null>(null);
  const [showJoinModal, setShowJoinModal] = useState(false);

  useEffect(() => {
    const checkAuth = async () => {
      const authStatus = await checkAuthStatus();
      setIsAuthenticated(authStatus.isAuthenticated);
    };
    
    checkAuth();
  }, []);

  useEffect(() => {
    const fetchCove = async () => {
      try {
        setLoading(true);
        const response = await fetch(`/api/coves/${coveId}`);
        
        if (!response.ok) {
          if (response.status === 404) {
            setError('Cove not found');
          } else {
            setError('Failed to load cove');
          }
          return;
        }
        
        const data = await response.json();
        setCove(data.cove);
      } catch (err) {
        console.error('Error fetching cove:', err);
        setError('Failed to load cove');
      } finally {
        setLoading(false);
      }
    };

    if (coveId) {
      fetchCove();
    }
  }, [coveId]);

  if (loading) {
    return (
      <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#5E1C1D] mx-auto mb-6"></div>
          <p className="font-libre-bodoni text-xl text-[#5E1C1D] mb-2">Loading cove...</p>
          <p className="font-libre-bodoni text-sm text-[#8B8B8B]">Getting everything ready for you</p>
        </div>
      </div>
    );
  }

  if (error || !cove) {
    return (
      <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center">
        <div className="text-center max-w-md mx-auto px-6">
          <h2 className="font-libre-bodoni text-2xl font-semibold text-[#5E1C1D] mb-4">
            Cove not found
          </h2>
          <p className="font-libre-bodoni text-lg text-[#8B8B8B] mb-6">
            This cove may have been deleted or the link is incorrect.
          </p>
          <button 
            onClick={() => window.history.back()}
            className="font-libre-bodoni text-[#5E1C1D] underline underline-offset-4"
          >
            Go back
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F5F0E6]">
      {/* Top Bar */}
      <div className="w-full px-8 pt-8 pb-12">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <span className="font-libre-bodoni text-3xl text-[#5E1C1D]">cove</span>
          <a 
            href="https://coveapp.co"
            className="font-libre-bodoni text-[#5E1C1D] underline underline-offset-4 text-lg"
          >
            join the cove waitlist
          </a>
        </div>
      </div>

      {/* Cove Content */}
      <div className="max-w-7xl mx-auto px-8 pb-16">
        <CoveDetailCard 
          cove={cove}
          isAuthenticated={isAuthenticated}
        />
      </div>

      {/* Join Modal */}
      {showJoinModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-8 max-w-md mx-4">
            <div className="text-center mb-6">
              <div className="text-4xl mb-4">🏠</div>
              <h3 className="font-libre-bodoni text-2xl font-semibold text-[#5E1C1D] mb-2">
                Join {cove?.name} Waitlist
              </h3>
              <p className="font-libre-bodoni text-sm text-[#8B8B8B]">
                You'll need to be invited by a member of this cove to join.
              </p>
            </div>
            
            <div className="space-y-4">
              <button
                onClick={() => setShowJoinModal(false)}
                className="w-full bg-gray-100 text-[#2D2D2D] py-3 px-6 rounded-xl font-libre-bodoni font-semibold hover:bg-gray-200 transition-colors"
              >
                Cancel
              </button>
              <a
                href="https://coveapp.co"
                className="w-full bg-[#5E1C1D] text-white py-3 px-6 rounded-xl font-libre-bodoni font-semibold hover:bg-[#4A1617] transition-colors text-center block"
              >
                Join Waitlist
              </a>
            </div>
          </div>
        </div>
      )}
    </div>
  );
} 