//
//  CitiesData.swift
//  Cove
//
//  Shared cities data model for location selection
//  Used by both onboarding CitySelectionView and profile location popup

import Foundation

struct CitiesData {
    // MARK: - Cities List
    // Same cities list as used in onboarding CitySelectionView
    static let cities: [String] = [
        "new york", "san francisco", "los angeles", "boston", "chicago", "seattle", "austin",
        "washington d.c.", "denver", "atlanta", "philadelphia", "san diego", "miami", "portland",
        "nashville", "dallas", "houston", "phoenix", "minneapolis", "charlotte", "raleigh",
        "tampa", "orlando", "san jose", "oakland", "sacramento", "boulder", "madison",
        "ann arbor", "pittsburgh", "baltimore", "richmond", "columbus", "cincinnati",
        "cleveland", "detroit", "milwaukee", "kansas city", "st. louis", "new orleans",
        "salt lake city", "boise", "las vegas", "tucson", "albuquerque", "oklahoma city",
        "omaha", "des moines", "buffalo", "hartford"
    ]
    
    // MARK: - Filtering Logic
    static func filteredCities(searchQuery: String) -> [String] {
        if searchQuery.isEmpty {
            return cities
        } else {
            return cities.filter { $0.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
} 