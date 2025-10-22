//
//  PoolStatusView.swift
//  Cove
//
//  Beautiful waiting screen with intention summary
//

import SwiftUI

struct PoolStatusView: View {
    @ObservedObject var model: IntentionModel
    @ObservedObject var matchModel: MatchModel
    @State private var currentUserName: String = "there"
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.96, green: 0.95, blue: 0.93)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Cove logo/title
                Text("cove")
                    .font(.LibreBodoniSemiBold(size: 48))
                    .foregroundColor(Colors.primaryDark)
                    .padding(.top, 60)
                
                Spacer()
                
                // Intention summary card
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Colors.primaryDark)
                        .overlay(
                            VStack(alignment: .leading, spacing: 24) {
                                // Loading indicator and message
                                VStack(spacing: 20) {
                                    // Bigger animated loading icon
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(2.5)
                                    
                                    Text(currentUserName.isEmpty ? 
                                         "We are finding your\nmatch. We will notify you when we have one!" :
                                         "\(currentUserName), we are finding your\n match. We will notify you when we have one!")
                                        .font(.LibreBodoniSemiBold(size: 22))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Divider
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 1)
                                
                                // Section title
                                Text("chosen intention & activity")
                                    .font(.LibreBodoniItalic(size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                // User's chosen activities (bigger, bold font)
                                VStack(alignment: .leading, spacing: 12) {
                                    // Activities - render as a single bold line
                                    let activities = getNormalizedActivities()
                                    if !activities.isEmpty {
                                        Text(activities.joined(separator: ", "))
                                            .font(.LibreBodoniSemiBold(size: 24))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }

                                    // Time windows + location - one concise line
                                    if let timesLine = getTimeWindowsWithLocationLine() {
                                        Text(timesLine)
                                            .font(Fonts.libreBodoni(size: 18))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                            .padding(32)
                        )
                }
                .frame(maxWidth: 400)
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .onAppear {
            loadUserName()
            startMatchPolling()
        }
        .onDisappear {
            stopMatchPolling()
        }
    }
    
    private func loadUserName() {
        // Get user's first name from UserDefaults or profile
        if let firstName = UserDefaults.standard.string(forKey: "userFirstName"), !firstName.isEmpty {
            currentUserName = firstName
        } else {
            // Fallback to a more natural greeting
            currentUserName = ""
        }
    }
    
    private func getIconForActivity(_ activity: String) -> String {
        let lowercased = activity.lowercased()
        if lowercased.contains("sports") || lowercased.contains("outdoors") {
            return "figure.run"
        } else if lowercased.contains("music") || lowercased.contains("performances") {
            return "music.note"
        } else if lowercased.contains("cocktails") || lowercased.contains("bars") {
            return "wineglass.fill"
        } else if lowercased.contains("food") {
            return "fork.knife"
        } else if lowercased.contains("fashion") || lowercased.contains("arts") {
            return "paintbrush.fill"
        }
        return "star.fill"
    }
    
    private func startMatchPolling() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                matchModel.load()
                if matchModel.currentMatch != nil {
                    // Stop polling when match is found
                }
            }
        }
    }
    
    private func stopMatchPolling() {
        // Task will be cancelled automatically
    }
    
    private func getNormalizedActivities() -> [String] {
        // Prefer live state from composer if present
        let activities = model.selectedActivities.isEmpty ? parseActivitiesFromText() : model.selectedActivities
        let merged = activities
            .map { $0.replacingOccurrences(of: "\n", with: " ") }
            .map { $0.replacingOccurrences(of: "sports, recreation & the outdoors", with: "sports, recreation & the outdoors") }
            .map { $0.replacingOccurrences(of: "music & live performances", with: "music & live performances") }
            .map { $0.replacingOccurrences(of: "nights out—cocktails & bars", with: "nights out — cocktails & bars") }
        // Deduplicate while preserving order
        var seen: Set<String> = []
        var result: [String] = []
        for a in merged {
            if !seen.contains(a) {
                seen.insert(a)
                result.append(a)
            }
        }
        return result
    }

    private func getTimeWindowsLine() -> String? {
        let timesArray = model.selectedTimeWindows.isEmpty ? parseTimesFromText() : Array(model.selectedTimeWindows)
        let unique = Array(Set(timesArray))
        if unique.isEmpty { return nil }
        // Sort by desired presentation order (sunday first per example), lowercase words
        let order: [String: Int] = [
            "sunday daytime": 0,
            "saturday daytime": 1,
            "saturday evening": 2,
            "friday evening": 3
        ]
        let lowered = unique.map { $0.lowercased() }
        let sorted = lowered.sorted { (order[$0] ?? 99) < (order[$1] ?? 99) }
        return sorted.joined(separator: ", ")
    }

    private func getTimeWindowsWithLocationLine() -> String? {
        guard let times = getTimeWindowsLine() else { return nil }
        let city = getLocationFromIntention() ?? model.userCity
        guard !city.isEmpty else { return times }
        return "\(times) near \(city)"
    }

    private func parseActivitiesFromText() -> [String] {
        guard let intention = model.currentIntention else { return [] }
        // Prefer parsing parts from parentheses when present: (Friends, activity, ..., City)
        if let parts = extractParenParts(from: intention.text), parts.count >= 3 {
            // Middle parts excluding first (connection) and last (city)
            let middle = Array(parts[1..<(parts.count - 1)])
            return middle.filter { part in
                let p = part.lowercased()
                return !(p.contains("evening") || p.contains("daytime") || p.contains("morning") || p.contains("friday") || p.contains("saturday") || p.contains("sunday"))
            }
        }
        // Fallback: old comma-based parsing
        let parts = intention.text.components(separatedBy: ", ")
        if parts.count <= 2 { return [] }
        let middleParts = Array(parts[1..<parts.count-1])
        return middleParts.filter { part in
            let p = part.lowercased()
            return !(p.contains("evening") || p.contains("daytime") || p.contains("morning") || p.contains("friday") || p.contains("saturday") || p.contains("sunday"))
        }.map { $0.replacingOccurrences(of: "\n", with: " ") }
    }

    private func parseTimesFromText() -> [String] {
        guard let intention = model.currentIntention else { return [] }
        // Use parentheses section if available
        if let parts = extractParenParts(from: intention.text) {
            return parts.filter { part in
                let p = part.lowercased()
                return p.contains("evening") || p.contains("daytime") || p.contains("morning") || p.contains("friday") || p.contains("saturday") || p.contains("sunday")
            }
        }
        // Fallback to simple comma splitting
        let parts = intention.text.components(separatedBy: ", ")
        return parts.filter { part in
            let p = part.lowercased()
            return p.contains("evening") || p.contains("daytime") || p.contains("morning") || p.contains("friday") || p.contains("saturday") || p.contains("sunday")
        }
    }

    private func extractParenParts(from text: String) -> [String]? {
        guard let open = text.firstIndex(of: "("), let close = text.lastIndex(of: ")"), open < close else {
            return nil
        }
        let inside = text[text.index(after: open)..<close]
        let parts = inside
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return parts
    }

    private func getLocationFromIntention() -> String? {
        if !model.userCity.isEmpty { return model.userCity }
        guard let intention = model.currentIntention else { return nil }
        if let parts = extractParenParts(from: intention.text), let last = parts.last { return last }
        let parts = intention.text.components(separatedBy: ", ")
        return parts.last
    }
}

// MARK: - Intention Item Row
struct IntentionItemRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon circle
            Circle()
                .fill(Color.blue)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("A")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                )
            
            // Text
            Text(text)
                .font(Fonts.libreBodoni(size: 18))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

#Preview {
    PoolStatusView(model: IntentionModel(), matchModel: MatchModel())
}
