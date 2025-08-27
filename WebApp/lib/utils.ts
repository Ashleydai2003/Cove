import { format, parseISO } from 'date-fns';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

// Utility function to merge Tailwind classes
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Date formatting utilities matching iOS app behavior
export function formatDate(dateString: string): string {
  try {
    const date = parseISO(dateString);
    return format(date, 'EEEE, MMMM d'); // e.g., "Friday, March 15"
  } catch (error) {
    console.error('Error formatting date:', error);
    return dateString; // Fallback to original string
  }
}

export function formatTime(dateString: string): string {
  try {
    const date = parseISO(dateString);
    return format(date, 'h:mm a'); // e.g., "7:30 PM"
  } catch (error) {
    console.error('Error formatting time:', error);
    return '';
  }
}

export function formatFullDateTime(dateString: string): string {
  try {
    const date = parseISO(dateString);
    return format(date, 'EEEE, MMMM d \'at\' h:mm a'); // e.g., "Friday, March 15 at 7:30 PM"
  } catch (error) {
    console.error('Error formatting full date time:', error);
    return dateString;
  }
} 