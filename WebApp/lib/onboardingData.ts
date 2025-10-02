// Onboarding data that mirrors iOS app structure
// IMPORTANT: This list must stay in sync with CoveApp/Views/Shared/AlmaMaterData.swift
// Centralized alma mater list for onboarding and profile editing

export const AlmaMaterData = {
  // Universities are fetched once from backend API, then filtered client-side
  // This follows the standard pattern used by most modern apps

  universities: [] as string[],
  isLoaded: false,

  async loadUniversities(): Promise<void> {
    if (this.isLoaded) return;
    
    try {
      const response = await fetch('/api/universities');
      if (response.ok) {
        const data = await response.json();
        this.universities = data.universities || [];
        this.isLoaded = true;
      }
    } catch (error) {
      console.error('Error loading universities:', error);
      // Fallback to empty array
      this.universities = [];
    }
  },

  async filteredUniversities(searchQuery: string): Promise<string[]> {
    await this.loadUniversities();
    
    if (searchQuery.trim() === '') {
      // Show "Other" option first, then first 19 universities
      return ['Other', ...this.universities.slice(0, 19)];
    }
    
    const query = searchQuery.toLowerCase().trim();
    const filtered = this.universities
      .filter(university => university.toLowerCase().includes(query));
    
    // Always include "Other" if it matches the search
    if ('other'.includes(query)) {
      return ['Other', ...filtered].slice(0, 20);
    }
    
    return filtered.slice(0, 20); // Limit results
  },

  async isValidUniversity(value: string): Promise<boolean> {
    await this.loadUniversities();
    const lc = value.trim().toLowerCase();
    
    // "Other" is always a valid option
    if (lc === 'other') return true;
    
    return this.universities.some(university => university.toLowerCase() === lc);
  }
};

export const GradYearsData = {
  get years(): string[] {
    const currentYear = new Date().getFullYear();
    const years = [];
    for (let year = currentYear + 4; year >= 2000; year--) {
      years.push(year.toString());
    }
    return years;
  },

  filteredYears(prefix: string): string[] {
    if (prefix.trim() === '') return this.years.slice(0, 10);
    
    const query = prefix.trim();
    return this.years
      .filter(year => year.startsWith(query))
      .slice(0, 10);
  },

  isValidYear(value: string): boolean {
    const year = parseInt(value);
    return !isNaN(year) && year >= 2000 && year <= new Date().getFullYear() + 4;
  }
}; 