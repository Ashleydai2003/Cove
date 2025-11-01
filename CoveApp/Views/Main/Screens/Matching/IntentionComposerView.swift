//
//  IntentionComposerView.swift
//  Cove
//
//  Chat-style intention composer
//

import SwiftUI

struct IntentionComposerView: View {
    @ObservedObject var model: IntentionModel
    @State private var showingError = false
    @State private var currentStep = 0
    @State private var showFirstMessage = false
    @State private var showSecondMessage = false
    @State private var showFirstQuestion = false
    @State private var connectionType: String? = nil
    @State private var showConnectionResponse = false
    @State private var showActivitiesPrompt = false
    @State private var selectedActivities: Set<String> = []
    @State private var showActivitiesResponse = false
    @State private var showTimeQuestion = false
    @State private var selectedTimeWindows: Set<String> = []
    @State private var showTimeResponse = false
    @State private var showFinalMessage = false
    
    let activityOptions = [
        "sports, recreation\n& the outdoors",
        "music & live\nperformances",
        "nights out—cocktails\n& bars",
        "food & good\ncompany",
        "fashion,\narts & crafts"
    ]
    
    let timeWindowOptions = [
        "friday evening",
        "saturday daytime",
        "saturday evening",
        "sunday daytime"
    ]
    
    var body: some View {
        ZStack {
            // Background
            Colors.background
                .ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Spacer().frame(height: 40)
                        
                        // First message from Cove
                        if showFirstMessage {
                            CoveChatBubble(text: "set your intention...\n\nnow that we know a bit about you, we want to understand how you want to show up for yourself.")
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Second message from Cove
                        if showSecondMessage {
                            CoveChatBubble(text: "first things first, what are you looking for?")
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .id("question1")
                        }
                        
                        // User response options (connection type)
                        if showFirstQuestion {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    UserResponseButton(
                                        text: "new friends & connections",
                                        isSelected: connectionType == "friends",
                                        action: {
                                            connectionType = "friends"
                                            handleFirstResponse()
                                        }
                                    )
                                    
                                    UserResponseButton(
                                        text: "romantic connection",
                                        isSelected: connectionType == "romantic",
                                        action: {
                                            connectionType = "romantic"
                                            handleFirstResponse()
                                        }
                                    )
                                }
                                .frame(maxWidth: 280)
                            }
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                        
                        // User's selected connection type (stays on screen)
                        if showConnectionResponse, let connection = connectionType {
                            HStack {
                                Spacer()
                                UserSentMessage(text: connection == "friends" ? "new friends & connections" : "romantic connection")
                            }
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .id("connectionResponse")
                        }
                        
                        // Activities prompt
                        if showActivitiesPrompt {
                            CoveChatBubble(text: "fantastic. now select the activities that excite you, and we will match you with people who are on the same wavelength.")
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .id("activities")
                        }
                        
                        // Activity options
                        if showActivitiesPrompt && !showActivitiesResponse {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    ForEach(activityOptions, id: \.self) { activity in
                                        ActivityButton(
                                            text: activity,
                                            isSelected: selectedActivities.contains(activity),
                                            action: {
                                                toggleActivity(activity)
                                            }
                                        )
                                    }
                                    
                                    // Continue button (only show if at least one activity selected)
                                    if !selectedActivities.isEmpty {
                                        Button(action: {
                                            showActivitiesAfterSelection()
                                        }) {
                                            Text("continue")
                                                .font(.LibreBodoniSemiBold(size: 18))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 14)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(Colors.primaryDark)
                                                )
                                        }
                                        .padding(.top, 8)
                                    }
                                }
                                .frame(maxWidth: 280)
                            }
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .id("activityButtons")
                        }
                        
                        // User's selected activities (stays on screen)
                        if showActivitiesResponse {
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 8) {
                                    ForEach(Array(selectedActivities), id: \.self) { activity in
                                        UserSentMessage(text: activity)
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .id("activitiesResponse")
                        }
                        
                        // Time window question
                        if showTimeQuestion {
                            CoveChatBubble(text: "great! when are you free to meet up?")
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .id("timeQuestion")
                        }
                        
                        // Time window options
                        if showTimeQuestion && !showTimeResponse {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    ForEach(timeWindowOptions, id: \.self) { time in
                                        ActivityButton(
                                            text: time,
                                            isSelected: selectedTimeWindows.contains(time),
                                            action: {
                                                toggleTimeWindow(time)
                                            }
                                        )
                                    }
                                    
                                    // Continue button (only show if at least one time selected)
                                    if !selectedTimeWindows.isEmpty {
                                        Button(action: {
                                            submitIntention()
                                        }) {
                                            Text("continue")
                                                .font(.LibreBodoniSemiBold(size: 18))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 14)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(Colors.primaryDark)
                                                )
                                        }
                                        .padding(.top, 8)
                                    }
                                }
                                .frame(maxWidth: 280)
                            }
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .id("timeButtons")
                        }
                        
                        // User's selected time windows (stays on screen)
                        if showTimeResponse {
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 8) {
                                    ForEach(Array(selectedTimeWindows), id: \.self) { time in
                                        UserSentMessage(text: time)
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .id("timeResponse")
                        }
                        
                        // Final message
                        if showFinalMessage {
                            CoveChatBubble(text: "setting you up with your perfect match!")
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .id("final")
                        }
                        
                        Spacer().frame(height: 100)
                    }
                    .padding()
                }
                .onChange(of: showSecondMessage) { _, newValue in
                    if newValue {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("question1", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: showFirstQuestion) { _, newValue in
                    if newValue {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("question1", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: showConnectionResponse) { _, newValue in
                    if newValue {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("connectionResponse", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: showActivitiesPrompt) { _, newValue in
                    if newValue {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("activities", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: showActivitiesResponse) { _, newValue in
                    if newValue {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("activitiesResponse", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: showTimeQuestion) { _, newValue in
                    if newValue {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("timeQuestion", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: showTimeResponse) { _, newValue in
                    if newValue {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("timeResponse", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: showFinalMessage) { _, newValue in
                    if newValue {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("final", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .onAppear {
            startConversation()
        }
    }
    
    private func startConversation() {
        // Show first message immediately
        withAnimation(.easeInOut(duration: 0.5)) {
            showFirstMessage = true
        }
        
        // Show second message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showSecondMessage = true
            }
            
            // Show response options
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showFirstQuestion = true
                }
            }
        }
    }
    
    private func handleFirstResponse() {
        // Hide question options and show user's response
        withAnimation(.easeInOut(duration: 0.3)) {
            showFirstQuestion = false
            showConnectionResponse = true
        }
        
        // Show activities prompt after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showActivitiesPrompt = true
            }
        }
    }
    
    private func toggleActivity(_ activity: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedActivities.contains(activity) {
                selectedActivities.remove(activity)
            } else {
                selectedActivities.insert(activity)
            }
        }
    }
    
    private func showActivitiesAfterSelection() {
        // Show user's activity selections as sent messages
        withAnimation(.easeInOut(duration: 0.3)) {
            showActivitiesResponse = true
        }
        
        // Show time question
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showTimeQuestion = true
            }
        }
    }
    
    private func toggleTimeWindow(_ time: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedTimeWindows.contains(time) {
                selectedTimeWindows.remove(time)
            } else {
                selectedTimeWindows.insert(time)
            }
        }
    }
    
    private func submitIntention() {
        // Show user's time window selections as sent messages
        withAnimation(.easeInOut(duration: 0.3)) {
            showTimeResponse = true
        }
        
        // Show final message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showFinalMessage = true
            }
            
            // Submit to backend and store in database after final message shows
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.performIntentionSubmission()
            }
        }
    }
    
    private func performIntentionSubmission() {
        print("🚀 [IntentionComposer] Starting intention submission...")
        print("   - Activities: \(Array(selectedActivities))")
        print("   - Time windows: \(Array(selectedTimeWindows))")
        print("   - Connection type: \(connectionType ?? "none")")
        print("   - User city: \(model.userCity)")
        
        // Build concise intention text (max 140 chars)
        var intentionParts: [String] = []
        
        if let connection = connectionType {
            // Short version: "friends" or "dating"
            let connectionText = connection == "friends" ? "friends" : "dating"
            intentionParts.append(connectionText)
        }
        
        if !selectedActivities.isEmpty {
            // Just the first activity or shorten long names
            let firstActivity = selectedActivities.first ?? ""
            let shortActivity = firstActivity
                .replacingOccurrences(of: "sports, recreation & the outdoors", with: "outdoors")
                .replacingOccurrences(of: "music & live performances", with: "music")
                .replacingOccurrences(of: "nights out—cocktails & bars", with: "nightlife")
                .replacingOccurrences(of: "food & good company", with: "food")
                .replacingOccurrences(of: "fashion, arts & crafts", with: "arts")
            intentionParts.append(shortActivity)
        }
        
        if !selectedTimeWindows.isEmpty {
            // Include all selected time windows
            let timeWindowsText = Array(selectedTimeWindows).joined(separator: ", ")
            intentionParts.append(timeWindowsText)
        }
        
        intentionParts.append(model.userCity)
        
        // Build natural text: "friends, music, saturday evening, sunday daytime, palo alto"
        let intentionText = intentionParts.joined(separator: ", ")
        
        print("📝 [IntentionComposer] Built intention text (\(intentionText.count) chars): \(intentionText)")
        print("   - Selected time windows: \(Array(selectedTimeWindows))")
        print("   - Intention parts: \(intentionParts)")
        
        // Submit to database
        model.submitIntention(
            intention: connectionType ?? "friends",
            activities: Array(selectedActivities),
            timeWindows: Array(selectedTimeWindows)
        ) { success in
            DispatchQueue.main.async {
                if success {
                    print("✅ [IntentionComposer] Intention saved to database successfully!")
                    print("   - Current intention: \(self.model.currentIntention?.id ?? "nil")")
                    print("   - Pool entry: \(self.model.poolEntry?.tier ?? -1)")
                    
                    // The model's currentIntention should now be set
                    // MatchingTabView will automatically detect this change and navigate
                } else {
                    print("❌ [IntentionComposer] Failed to save intention to database")
                    self.showingError = true
                }
            }
        }
    }
}

// MARK: - Cove Chat Bubble
struct CoveChatBubble: View {
    let text: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(text)
                    .font(Fonts.libreBodoni(size: 16))
                    .foregroundColor(Colors.primaryDark)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            Spacer()
        }
        .frame(maxWidth: 280, alignment: .leading)
    }
}

// MARK: - User Sent Message
struct UserSentMessage: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(Fonts.libreBodoni(size: 16))
            .foregroundColor(.white)
            .padding(16)
            .background(Colors.primaryDark)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .frame(maxWidth: 280, alignment: .trailing)
    }
}

// MARK: - User Response Button
struct UserResponseButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(Fonts.libreBodoni(size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Colors.primaryDark)
                .cornerRadius(20)
        }
    }
}

// MARK: - Activity Button
struct ActivityButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(Fonts.libreBodoni(size: 14))
                .foregroundColor(isSelected ? .white : Colors.primaryDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Colors.primaryDark : Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Colors.primaryDark, lineWidth: 1)
                )
        }
    }
}

#Preview {
    IntentionComposerView(model: IntentionModel())
}
