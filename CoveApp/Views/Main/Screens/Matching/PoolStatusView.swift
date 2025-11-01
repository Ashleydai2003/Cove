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
    
    private var greetingText: String {
        if currentUserName.isEmpty {
            return "we are finding your\nmatch. we will notify you when we have one!"
        } else {
            let firstName = currentUserName.components(separatedBy: " ").first ?? currentUserName
            return "\(firstName), we are finding your\n match. we will notify you when we have one!"
        }
    }
    
    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                Spacer()
                statusCard
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
    
    private var headerView: some View {
        Text("cove")
            .font(.LibreBodoniSemiBold(size: 48))
            .foregroundColor(Colors.primaryDark)
            .padding(.top, 60)
    }
    
    private var statusCard: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Colors.primaryDark)
                .overlay(cardContent)
        }
        .frame(maxWidth: 400)
        .padding(.horizontal, 24)
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            greetingSection
            divider
            intentionTitle
            intentionDetails
        }
        .padding(32)
    }
    
    private var greetingSection: some View {
        VStack(spacing: 20) {
            Image("sparkle")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(.white)
                .scaleEffect(1.2)
            
            Text(greetingText)
                .font(.LibreBodoniSemiBold(size: 22))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.3))
            .frame(height: 1)
    }
    
    private var intentionTitle: some View {
        Text("chosen intention & activity")
            .font(.LibreBodoniItalic(size: 16))
            .foregroundColor(.white.opacity(0.8))
    }
    
    private var intentionDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            activitiesList
            timeLocationText
        }
    }
    
    @ViewBuilder
    private var activitiesList: some View {
        let activities = getNormalizedActivities()
        if !activities.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(activities.enumerated()), id: \.offset) { index, activity in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(Fonts.libreBodoni(size: 20))
                            .foregroundColor(.white)
                            .padding(.top, 2)
                        
                        Text(activity)
                            .font(Fonts.libreBodoni(size: 20))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private var timeLocationText: some View {
        if let timesLine = getTimeWindowsWithLocationLine() {
            Text(timesLine)
                .font(Fonts.libreBodoni(size: 18))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
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
        // Try to get from parsedJson first
        if let intention = model.currentIntention,
           let parsed = parseIntentionFromParsedJson(intention) {
            return parsed.activities
        }
        // Fallback to selected activities
        return Array(model.selectedActivities)
    }

    private func getTimeWindowsLine() -> String? {
        // Try to get from parsedJson first
        if let intention = model.currentIntention,
           let parsed = parseIntentionFromParsedJson(intention) {
            return parsed.availability.map { $0.lowercased() }.joined(separator: ", ")
        }
        // Fallback to selected time windows
        return Array(model.selectedTimeWindows).map { $0.lowercased() }.joined(separator: ", ")
    }

    private func getTimeWindowsWithLocationLine() -> String? {
        guard let times = getTimeWindowsLine() else { return nil }
        // Try to get location from parsedJson first
        if let intention = model.currentIntention,
           let parsed = parseIntentionFromParsedJson(intention) {
            return "\(times) near \(parsed.location)"
        }
        // Fallback to model's city
        let city = model.userCity
        guard !city.isEmpty else { return times }
        return "\(times) near \(city)"
    }
    
    private func parseIntentionFromParsedJson(_ intention: Intention) -> (intention: String, activities: [String], availability: [String], location: String)? {
        if let json = intention.parsedJson?.value as? [String: Any] {
            var intentionType: String?
            var activities: [String] = []
            var availability: [String] = []
            var location: String = ""
            
            // CURRENT STRUCTURE: { who: {}, what: { intention, activities }, when: [], where: "" }
            if let what = json["what"] as? [String: Any],
               let intent = what["intention"] as? String,
               let acts = what["activities"] as? [String] {
                intentionType = intent
                activities = acts
                availability = json["when"] as? [String] ?? []
                location = json["where"] as? String ?? ""
            }
            // LEGACY SUPPORT: Old format with what.notes
            // { who: {}, what: { notes, activities }, when: [], location: "" }
            else if let what = json["what"] as? [String: Any],
                    let notes = what["notes"] as? String,
                    let acts = what["activities"] as? [String] {
                // Extract intention from notes
                intentionType = notes.lowercased().contains("dating") || notes.lowercased().contains("romantic") ? "romantic" : "friends"
                activities = acts
                availability = json["when"] as? [String] ?? []
                location = json["location"] as? String ?? ""
            }
            
            if let finalIntention = intentionType, !activities.isEmpty {
                return (finalIntention, activities, availability, location)
            }
        }
        
        return nil
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
                            Text("a")
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
