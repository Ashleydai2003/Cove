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
        "New York", "San Francisco", "Los Angeles", "Boston", "Chicago", "Seattle", "Austin",
        "Washington D.C.", "Denver", "Atlanta", "Philadelphia", "San Diego", "Miami", "Portland",
        "Nashville", "Dallas", "Houston", "Phoenix", "Minneapolis", "Charlotte", "Raleigh",
        "Tampa", "Orlando", "San Jose", "Oakland", "Sacramento", "Boulder", "Madison",
        "Ann Arbor", "Pittsburgh", "Baltimore", "Richmond", "Columbus", "Cincinnati",
        "Cleveland", "Detroit", "Milwaukee", "Kansas City", "St. Louis", "New Orleans",
        "Salt Lake City", "Boise", "Las Vegas", "Tucson", "Albuquerque", "Oklahoma City",
        "Omaha", "Des Moines", "Buffalo", "Hartford"
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