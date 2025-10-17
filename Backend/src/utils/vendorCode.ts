/**
 * Vendor Code Utility Functions
 * Generates and validates secure vendor invitation codes
 */

import crypto from 'crypto';

/**
 * Generate a secure, human-readable vendor code
 * Format: XXXX-XXXX (8 characters, uppercase letters and numbers)
 * Example: AB3K-7M9P
 */
export function generateVendorCode(): string {
  // Use uppercase letters (excluding similar-looking: O, I, L) and numbers (excluding 0, 1)
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  const codeLength = 8;
  
  let code = '';
  const randomBytes = crypto.randomBytes(codeLength);
  
  for (let i = 0; i < codeLength; i++) {
    code += chars[randomBytes[i] % chars.length];
    if (i === 3) {
      code += '-'; // Add separator after 4 characters
    }
  }
  
  return code;
}

/**
 * Validate vendor code format
 */
export function isValidVendorCodeFormat(code: string): boolean {
  // Must be 9 characters: XXXX-XXXX
  if (code.length !== 9) return false;
  if (code[4] !== '-') return false;
  
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  const parts = code.split('-');
  
  if (parts.length !== 2) return false;
  if (parts[0].length !== 4 || parts[1].length !== 4) return false;
  
  // Check all characters are valid
  for (const part of parts) {
    for (const char of part) {
      if (!chars.includes(char)) return false;
    }
  }
  
  return true;
}

/**
 * Check if a vendor code should be rotated (older than 90 days)
 */
export function shouldRotateCode(codeRotatedAt: Date): boolean {
  const ninetyDaysAgo = new Date();
  ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);
  return codeRotatedAt < ninetyDaysAgo;
}

