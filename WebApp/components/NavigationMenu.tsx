'use client';

import { useState } from 'react';
import { Menu, X } from 'lucide-react';
import Link from 'next/link';

export default function NavigationMenu() {
  const [isOpen, setIsOpen] = useState(false);

  const toggleMenu = () => {
    setIsOpen(!isOpen);
  };

  const closeMenu = () => {
    setIsOpen(false);
  };

  return (
    <div className="relative">
      {/* Menu Button */}
      <button
        onClick={toggleMenu}
        className="fixed top-4 right-4 z-50 w-12 h-12 bg-[#7a3131ff] text-white rounded-full flex items-center justify-center hover:bg-[#4a1919] transition-colors shadow-lg"
        aria-label="Open navigation menu"
      >
        {isOpen ? <X size={20} /> : <Menu size={20} />}
      </button>

      {/* Menu Overlay */}
      {isOpen && (
        <div className="fixed inset-0 z-40 bg-black bg-opacity-50" onClick={closeMenu} />
      )}

      {/* Menu Content */}
      {isOpen && (
        <div className="fixed top-4 right-4 z-50 bg-white rounded-lg shadow-xl border border-gray-200 min-w-[200px]">
          <div className="p-4">
            <nav className="space-y-3">
              <a
                href="/about"
                onClick={closeMenu}
                className="block font-libre-bodoni text-[#2D2D2D] hover:text-[#5E1C1D] transition-colors"
              >
                about
              </a>
              <a
                href="/how-it-works"
                onClick={closeMenu}
                className="block font-libre-bodoni text-[#2D2D2D] hover:text-[#5E1C1D] transition-colors"
              >
                how it works
              </a>
              <a
                href="https://www.coveapp.co/coves/cmebw8cg40001jv02f7zh22lj"
                target="_blank"
                rel="noopener noreferrer"
                onClick={closeMenu}
                className="block font-libre-bodoni text-[#2D2D2D] hover:text-[#5E1C1D] transition-colors"
              >
                events
              </a>
              <a
                href="/contact"
                onClick={closeMenu}
                className="block font-libre-bodoni text-[#2D2D2D] hover:text-[#5E1C1D] transition-colors"
              >
                reach out
              </a>
              <div className="border-t border-gray-200 pt-3 mt-3">
                <a
                  href="/privacy"
                  onClick={closeMenu}
                  className="block font-libre-bodoni text-sm text-[#8B8B8B] hover:text-[#5E1C1D] transition-colors"
                >
                  privacy policy
                </a>
                <a
                  href="/terms"
                  onClick={closeMenu}
                  className="block font-libre-bodoni text-sm text-[#8B8B8B] hover:text-[#5E1C1D] transition-colors mt-2"
                >
                  terms of service
                </a>
              </div>
            </nav>
          </div>
        </div>
      )}
    </div>
  );
}
