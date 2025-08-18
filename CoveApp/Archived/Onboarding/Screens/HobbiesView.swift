// Created by Ananya Agarwal

import SwiftUI

/// View for collecting user's hobbies during onboarding
/// Dynamic expandable hobby selection with visual feedback
struct HobbiesView: View {
    // MARK: - Environment & State Properties

    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController

    /// Tracks which hobbies are currently selected
    @State private var selectedHobbies: Set<String> = []

    /// Tracks which top-level buttons are expanded
    @State private var expandedButtons: Set<String> = []

    /// Tracks whether to show the error alert
    @State private var showingError = false

    // MARK: - Data

    /// Sections with their respective hobby buttons (now using shared data)
    private let hobbyDataSections: [HobbySection] = HobbiesData.hobbyDataSections

    /// Flattened hobby data for existing logic compatibility
    private var hobbyData: [HobbyButtonOption] {
        hobbyDataSections.flatMap { $0.buttons }
    }

    /// Helper function to get buttons for a specific section
    private func getSectionButtonsToShow(for sectionName: String, buttons: [HobbyButtonOption]) -> [HobbiesData.ButtonData] {
        return HobbiesData.getSectionButtonsToShow(for: sectionName, buttons: buttons, expandedButtons: expandedButtons)
    }

    // MARK: - View Body

    var body: some View {
        ZStack {
            OnboardingBackgroundView()

            VStack {
                // Back button
                HStack {
                    Button {
                        appController.path.removeLast()
                    } label: {
                        Images.backArrow
                    }
                    Spacer()
                }
                .padding(.top, 10)

                // Header section
                VStack(alignment: .leading, spacing: 10) {
                    Text("what do you want to do in your city?")
                        .foregroundStyle(Colors.primaryDark)
                        .font(.LibreBodoniMedium(size: 40))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("select whatever stands out to you")
                        .font(.LeagueSpartan(size: 15))
                        .foregroundColor(Colors.k0B0B0B)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 40)

                // Dynamic expandable hobby buttons organized by sections
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(hobbyDataSections.enumerated()), id: \.offset) { sectionIndex, section in
                            let sectionName = section.name
                            let sectionEmoji = section.emoji
                            let sectionButtons = section.buttons

                            // Section header on its own line
                            HStack {
                                Text("\(sectionEmoji) \(sectionName)")
                                    .font(.LeagueSpartan(size: 18))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Colors.primaryDark)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                            }
                            .padding(.top, sectionIndex == 0 ? 0 : 20)
                            .padding(.bottom, 8)

                            // Buttons for this section in a grid
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(getSectionButtonsToShow(for: sectionName, buttons: sectionButtons), id: \.id) { buttonData in
                                    HobbyButton(
                                        text: buttonData.text,
                                        emoji: buttonData.emoji,
                                        isSelected: selectedHobbies.contains(buttonData.text),
                                        borderWidth: buttonData.isTopLevel ? 2 : 1
                                    ) {
                                        if buttonData.isTopLevel {
                                            // Top-level button: toggle expansion and selection
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                if expandedButtons.contains(buttonData.text) {
                                                    expandedButtons.remove(buttonData.text)
                                                } else {
                                                    expandedButtons.insert(buttonData.text)
                                                }
                                            }

                                            // Also toggle selection
                                            if selectedHobbies.contains(buttonData.text) {
                                                selectedHobbies.remove(buttonData.text)
                                            } else {
                                                selectedHobbies.insert(buttonData.text)
                                            }
                                        } else {
                                            // Sub-level button: only toggle selection
                                            if selectedHobbies.contains(buttonData.text) {
                                                selectedHobbies.remove(buttonData.text)
                                            } else {
                                                selectedHobbies.insert(buttonData.text)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 30)
                }

                Spacer()

                // Continue button
                HStack {
                    // Show selected hobbies count
                    if !selectedHobbies.isEmpty {
                        Text("\(selectedHobbies.count) hobby\(selectedHobbies.count == 1 ? "" : "ies") selected")
                            .font(.LeagueSpartan(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    Images.nextArrow
                        .resizable()
                        .frame(width: 52, height: 52)
                        .padding(.bottom, 20)
                        .opacity(selectedHobbies.isEmpty ? 0.5 : 1.0)
                        .onTapGesture {
                            // MARK: - Validate hobbies selection
                            if selectedHobbies.isEmpty {
                                // Show error message
                                appController.errorMessage = "Please select at least one hobby before continuing"
                                showingError = true
                                return
                            }
                            
                            // MARK: - Store hobbies
                            Onboarding.storeHobbies(hobbies: selectedHobbies)
                            appController.path.append(.profilePics)
                        }
                }
            }
            .padding(.horizontal, 32)
        }
        .navigationBarBackButtonHidden()
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {
                showingError = false
            }
        } message: {
            Text(appController.errorMessage)
        }
    }
}



// MARK: - Preview
#Preview {
    HobbiesView()
        .environmentObject(AppController.shared)
}
