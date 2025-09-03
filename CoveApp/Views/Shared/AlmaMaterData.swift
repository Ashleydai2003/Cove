//
//  AlmaMaterData.swift
//  Cove
//
//  Centralized alma mater list for onboarding and profile editing
//

import Foundation

struct AlmaMaterData {
    // Comprehensive list of major universities for both iOS and web
    static let universities: [String] = [
        // Ivy League
        "brown",
        "columbia",
        "cornell",
        "dartmouth",
        "harvard",
        "pennsylvania",
        "princeton",
        "yale",
        
        // Stanford & Top California
        "stanford",
        "stanford gsb",
        "berkeley",
        "ucla",
        "usc",
        "caltech",
        "uc san diego",
        "uc davis",
        "uc irvine",
        "uc santa barbara",
        "uc santa cruz",
        "uc riverside",
        "uc merced",
        
        // Top East Coast
        "mit",
        "nyu",
        "georgetown",
        "george washington",
        "american university",
        "johns hopkins",
        "carnegie mellon",
        "duke",
        "vanderbilt",
        "emory",
        "wake forest",
        "davidson",
        
        // Top Midwest
        "northwestern",
        "university of chicago",
        "university of michigan",
        "michigan state",
        "indiana university",
        "purdue",
        "university of illinois",
        "university of wisconsin",
        "university of minnesota",
        "university of iowa",
        "ohio state",
        "case western reserve",
        
        // Top South
        "university of virginia",
        "virginia tech",
        "university of north carolina",
        "north carolina state",
        "university of florida",
        "florida state",
        "university of miami",
        "university of texas",
        "texas a&m",
        "rice university",
        "baylor university",
        "tulane university",
        
        // Top West & Mountain
        "university of washington",
        "washington state",
        "university of oregon",
        "oregon state",
        "university of arizona",
        "arizona state",
        "university of colorado",
        "colorado state",
        "university of utah",
        "brigham young university",
        "university of nevada",
        
        // Top Northeast
        "boston university",
        "boston college",
        "northeastern",
        "tufts",
        "brandeis",
        "wesleyan",
        "amherst",
        "williams",
        "middlebury",
        "bowdoin",
        "colby",
        "bates",
        
        // Top Public Universities
        "university of california berkeley",
        "university of california los angeles",
        "university of michigan ann arbor",
        "university of virginia",
        "university of north carolina chapel hill",
        "university of florida",
        "university of texas austin",
        "university of washington",
        "university of illinois urbana-champaign",
        "university of wisconsin madison",
        
        // Top Private Universities
        "harvard university",
        "stanford university",
        "massachusetts institute of technology",
        "yale university",
        "princeton university",
        "columbia university",
        "university of pennsylvania",
        "duke university",
        "northwestern university",
        "johns hopkins university",
        
        // Liberal Arts Colleges
        "pomona college",
        "claremont mckenna",
        "harvey mudd",
        "scripps college",
        "pitzer college",
        "swarthmore college",
        "haverford college",
        "bryn mawr college",
        "vassar college",
        "wellesley college",
        "smith college",
        "mount holyoke college",
        "barnard college",
        
        // International Universities
        "university of toronto",
        "university of british columbia",
        "mcgill university",
        "university of oxford",
        "university of cambridge",
        "london school of economics",
        "imperial college london",
        "university college london",
        "king's college london",
        "sciences po",
        "hec paris",
        "esade business school",
        "ie business school"
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


