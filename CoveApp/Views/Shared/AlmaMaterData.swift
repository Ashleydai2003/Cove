//
//  AlmaMaterData.swift
//  Cove
//
//  Centralized alma mater list for onboarding and profile editing
//

import Foundation

struct AlmaMaterData {
    // For now, restricted list as requested
    static let universities: [String] = [
        "stanford",
        "stanford gsb",
        "yale",
        "harvard",
        "usc",
        "ucla"
    ]

    static func filteredUniversities(searchQuery: String) -> [String] {
        if searchQuery.isEmpty { return universities }
        return universities.filter { $0.localizedCaseInsensitiveContains(searchQuery) }
    }

    static func isValidUniversity(_ value: String) -> Bool {
        let lc = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return universities.contains { $0.lowercased() == lc }
    }
}


