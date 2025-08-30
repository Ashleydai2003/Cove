//
//  GradYearsData.swift
//  Cove
//
//  Centralized graduation years for onboarding and profile editing
//

import Foundation

struct GradYearsData {
    static var years: [String] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let maxYear = currentYear + 4
        // Most recent first to match onboarding feel
        return Array(2000...maxYear).map { String($0) }.reversed()
    }

    static func filteredYears(prefix: String) -> [String] {
        if prefix.isEmpty { return years }
        return years.filter { $0.hasPrefix(prefix) }
    }

    static func isValidYear(_ value: String) -> Bool {
        return years.contains(value)
    }
}


