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

    // MARK: - Hobby Data Structs
    struct HobbySubOption: Identifiable {
        let id = UUID()
        let name: String
        let emoji: String
    }

    struct HobbyButtonOption: Identifiable {
        let id = UUID()
        let name: String
        let emoji: String
        let subOptions: [HobbySubOption]
    }

    struct HobbySection: Identifiable {
        let id = UUID()
        let name: String
        let emoji: String
        let buttons: [HobbyButtonOption]
    }

    // MARK: - Data

    /// Sections with their respective hobby buttons
    private let hobbyDataSections: [HobbySection] = [
        HobbySection(name: "going out", emoji: "🍻", buttons: [
            HobbyButtonOption(name: "bars", emoji: "🍸", subOptions: [
                HobbySubOption(name: "dive bars", emoji: "🍺"),
                HobbySubOption(name: "cocktail bars", emoji: "🍸"),
                HobbySubOption(name: "karaoke", emoji: "🎤")
            ]),
            HobbyButtonOption(name: "nightclubs", emoji: "💃", subOptions: [
                HobbySubOption(name: "reggaeton", emoji: "🎵"),
                HobbySubOption(name: "house", emoji: "🏠"),
                HobbySubOption(name: "techno", emoji: "🔊"),
                HobbySubOption(name: "pop", emoji: "🎶"),
                HobbySubOption(name: "afro", emoji: "🌍")
            ]),
            HobbyButtonOption(name: "live music", emoji: "🎸", subOptions: [
                HobbySubOption(name: "indie", emoji: "🎸"),
                HobbySubOption(name: "rock", emoji: "🤘"),
                HobbySubOption(name: "country", emoji: "🤠")
            ])
        ]),
        HobbySection(name: "fitness", emoji: "🏃‍♀️", buttons: [
            HobbyButtonOption(name: "running", emoji: "🏃‍♀️", subOptions: [
                HobbySubOption(name: "casual", emoji: "🏃"),
                HobbySubOption(name: "marathons", emoji: "🏃"),
                HobbySubOption(name: "trail running", emoji: "🏃")
            ]),
            HobbyButtonOption(name: "triathlon", emoji: "💪🏼", subOptions: [
                HobbySubOption(name: "newbie", emoji: "💪🏼"),
                HobbySubOption(name: "competitive", emoji: "💪🏼")
            ]),
            HobbyButtonOption(name: "cycling", emoji: "🚴‍♀️", subOptions: []),
            HobbyButtonOption(name: "pickleball", emoji: "🥎", subOptions: []),
            HobbyButtonOption(name: "soccer", emoji: "⚽️", subOptions: [
                HobbySubOption(name: "casual", emoji: "⚽️"),
                HobbySubOption(name: "competitive", emoji: "⚽️")
            ]),
            HobbyButtonOption(name: "swimming", emoji: "🏊‍♀️", subOptions: [
                HobbySubOption(name: "casual", emoji: "🏊‍♀️"),
                HobbySubOption(name: "competitive", emoji: "🏊‍♀️")
            ]),
            HobbyButtonOption(name: "basketball", emoji: "🏀", subOptions: []),
            HobbyButtonOption(name: "volleyball", emoji: "🏐", subOptions: []),
            HobbyButtonOption(name: "tennis", emoji: "🎾", subOptions: [
                HobbySubOption(name: "casual tennis", emoji: "🎾"),
                HobbySubOption(name: "competitive tennis", emoji: "🎾")
            ]),
            HobbyButtonOption(name: "workout classes", emoji: "🏋🏽‍♀️", subOptions: [
                HobbySubOption(name: "yoga", emoji: "🧘‍♀️"),
                HobbySubOption(name: "pilates", emoji: "🤸‍♀️"),
                HobbySubOption(name: "strength", emoji: "💪"),
                HobbySubOption(name: "dance", emoji: "💃")
            ]),
            HobbyButtonOption(name: "hiking", emoji: "🥾", subOptions: [
                HobbySubOption(name: "casual", emoji: "🥾"),
                HobbySubOption(name: "intense", emoji: "🥾")
            ]),
            HobbyButtonOption(name: "surfing", emoji: "🏄‍♀️", subOptions: [
                HobbySubOption(name: "beginner", emoji: "🏄‍♀️"),
                HobbySubOption(name: "dawn patrol", emoji: "🏄‍♀️")
            ]),
            HobbyButtonOption(name: "climbing", emoji: "🧗‍♀️", subOptions: [
                HobbySubOption(name: "indoor", emoji: "🧗‍♀️"),
                HobbySubOption(name: "outdoor", emoji: "🧗‍♀️")
            ])
        ]),
        HobbySection(name: "activities", emoji: "🎨", buttons: [
            HobbyButtonOption(name: "board games", emoji: "🎲", subOptions: []),
            HobbyButtonOption(name: "poker", emoji: "♠️", subOptions: [
                HobbySubOption(name: "casual", emoji: "♠️"),
                HobbySubOption(name: "serious", emoji: "♠️")
            ]),
            HobbyButtonOption(name: "art classes", emoji: "🖼️", subOptions: [
                HobbySubOption(name: "drawing", emoji: "✏️"),
                HobbySubOption(name: "painting", emoji: "🎨"),
                HobbySubOption(name: "ceramics", emoji: "🏺")
            ])
        ]),
        HobbySection(name: "career", emoji: "💼", buttons: [
            HobbyButtonOption(name: "founders groups", emoji: "👨‍💻", subOptions: [
                HobbySubOption(name: "aspiring founders", emoji: "💡"),
                HobbySubOption(name: "current founders", emoji: "🚀")
            ]),
            HobbyButtonOption(name: "remote work & cafe", emoji: "☕️", subOptions: []),
            HobbyButtonOption(name: "interview prep", emoji: "💼", subOptions: []),
            HobbyButtonOption(name: "leetcode", emoji: "💻", subOptions: []),
            HobbyButtonOption(name: "consulting", emoji: "📊", subOptions: []),
            HobbyButtonOption(name: "finance", emoji: "💰", subOptions: [])
        ])
    ]

    /// Flattened hobby data for existing logic compatibility
    private var hobbyData: [HobbyButtonOption] {
        hobbyDataSections.flatMap { $0.buttons }
    }

    /// Data structure for unified button display
    private struct ButtonData: Identifiable {
        let id: String
        let text: String
        let emoji: String
        let isTopLevel: Bool
    }

    /// Helper function to get buttons for a specific section
    private func getSectionButtonsToShow(for sectionName: String, buttons: [HobbyButtonOption]) -> [ButtonData] {
        var sectionButtons: [ButtonData] = []

        for button in buttons {
            // Add the top-level button
            sectionButtons.append(ButtonData(
                id: button.name,
                text: button.name,
                emoji: button.emoji,
                isTopLevel: true
            ))

            // Add sub-buttons if expanded
            if expandedButtons.contains(button.name) {
                for sub in button.subOptions {
                    sectionButtons.append(ButtonData(
                        id: "\(button.name)-\(sub.name)",
                        text: sub.name,
                        emoji: sub.emoji,
                        isTopLevel: false
                    ))
                }
            }
        }

        return sectionButtons
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
                    Spacer()
                    Images.nextArrow
                        .resizable()
                        .frame(width: 52, height: 52)
                        .padding(.bottom, 20)
                        .onTapGesture {
                            // MARK: - Store hobbies
                            Onboarding.storeHobbies(hobbies: selectedHobbies)
                            appController.path.append(.profilePics)
                        }
                }
            }
            .padding(.horizontal, 32)
        }
        .navigationBarBackButtonHidden()
    }
}

// MARK: - Hobby Button Component

struct HobbyButton: View {
    let text: String
    let emoji: String
    let isSelected: Bool
    let borderWidth: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 16))

                Text(text)
                    .font(.LeagueSpartan(size: 14))
                    .foregroundColor(isSelected ? .white : Colors.primaryDark)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Colors.primaryDark : Colors.primaryLight)
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Colors.primaryDark, lineWidth: borderWidth)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    HobbiesView()
        .environmentObject(AppController.shared)
}
