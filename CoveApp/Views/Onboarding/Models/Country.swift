//
//  Country.swift
//  Cove
//
//  Created by Nesib Muhedin

import Foundation

struct Country: Codable, Identifiable {

    let id: String
    let name: String
    let flag: String
    let code: String
    let dial_code: String
    let pattern: String
    let limit: Int
}

extension Bundle {
    func decode<T: Decodable>(_ file: String) -> T {
        // 1. Find the file in the bundle
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle.")
        }

        do {
            // 2. Load its raw Data
            let data = try Data(contentsOf: url)

            // 3. Decode using a JSONDecoder
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        }
        catch {
            // 4. Print the exact decoding error so you can fix it
            Log.debug("❌ Error decoding '\(file)': \(error)")
            fatalError("Decoding '\(file)' failed; see console for details.")
        }
    }
}

