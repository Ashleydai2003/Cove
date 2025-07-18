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

    // MARK: - Data

    /// Sections with their respective hobby buttons
    private let hobbyDataSections: [(String, String, [(String, String, [(String, String)])])] = [
        ("going out", "🍻", [
            ("bars", "🍸", [
                ("dive bars", "🍺"),
                ("cocktail bars", "🍸"),
                ("karaoke", "🎤")
            ]),
            ("nightclubs", "💃", [
                ("reggaeton", "🎵"),
                ("house", "🏠"),
                ("techno", "🔊"),
                ("pop", "🎶"),
                ("afro", "🌍")
            ]),
            ("live music", "🎸", [
                ("indie", "🎸"),
                ("rock", "🤘"),
                ("country", "🤠")
            ])
        ]),
        ("fitness", "🏃‍♀️", [
            ("running", "🏃‍♀️", [
                ("casual", "🏃"),
                ("marathons", "🏃"),
                ("trail running", "🏃")
            ]),
            ("triathlon", "💪🏼", [
                ("newbie", "💪🏼"),
                ("competitive", "💪🏼")
            ]),
            ("cycling", "🚴‍♀️", []),
            ("pickleball", "🥎", []),
            ("soccer", "⚽️", [
                ("casual", "⚽️"),
                ("competitive", "⚽️")
            ]),
            ("swimming", "🏊‍♀️", [
                ("casual", "🏊‍♀️"),
                ("competitive", "🏊‍♀️")
            ]),
            ("basketball", "🏀", []),
            ("volleyball", "🏐", []),
            ("tennis", "🎾", [
                ("casual tennis", "🎾"),
                ("competitive tennis", "🎾")
            ]),
            ("workout classes", "🏋🏽‍♀️", [
                ("yoga", "🧘‍♀️"),
                ("pilates", "🤸‍♀️"),
                ("strength", "💪"),
                ("dance", "💃")
            ]),
            ("hiking", "🥾", [
                ("casual", "🥾"),
                ("intense", "🥾")
            ]),
            ("surfing", "🏄‍♀️", [
                ("beginner", "🏄‍♀️"),
                ("dawn patrol", "🏄‍♀️")
            ]),
            ("climbing", "🧗‍♀️", [
                ("indoor", "🧗‍♀️"),
                ("outdoor", "🧗‍♀️")
            ])
        ]),
        ("activities", "🎨", [
            ("board games", "🎲", []),
            ("poker", "♠️", [
                ("casual", "♠️"),
                ("serious", "♠️")
            ]),
            ("art classes", "🖼️", [
                ("drawing", "✏️"),
                ("painting", "🎨"),
                ("ceramics", "🏺")
            ])
        ]),
        ("career", "💼", [
            ("founders groups", "👨‍💻", [
                ("aspiring founders", "💡"),
                ("current founders", "🚀")
            ]),
            ("remote work & cafe", "☕️", []),
            ("interview prep", "💼", []),
            ("leetcode", "💻", []),
            ("consulting", "📊", []),
            ("finance", "💰", [])
        ])
    ]

    /// Flattened hobby data for existing logic compatibility
    private var hobbyData: [(String, String, [(String, String)])] {
        hobbyDataSections.flatMap { section in
            section.2.map { (name, emoji, subOptions) in
                (name, emoji, subOptions)
            }
        }
    }

    /// Data structure for unified button display
    private struct ButtonData: Identifiable {
        let id: String
        let text: String
        let emoji: String
        let isTopLevel: Bool

        init(id: String, text: String, emoji: String, isTopLevel: Bool) {
            self.id = id
            self.text = text
            self.emoji = emoji
            self.isTopLevel = isTopLevel
        }
    }

    /// Helper function to get buttons for a specific section
    private func getSectionButtonsToShow(for sectionName: String, buttons: [(String, String, [(String, String)])]) -> [ButtonData] {
        var sectionButtons: [ButtonData] = []

        for (topLevelName, topLevelEmoji, subOptions) in buttons {
            // Add the top-level button
            sectionButtons.append(ButtonData(
                id: topLevelName,
                text: topLevelName,
                emoji: topLevelEmoji,
                isTopLevel: true
            ))

            // Add sub-buttons if expanded
            if expandedButtons.contains(topLevelName) {
                for (subName, subEmoji) in subOptions {
                    sectionButtons.append(ButtonData(
                        id: "\(topLevelName)-\(subName)",
                        text: subName,
                        emoji: subEmoji,
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
                            let (sectionName, sectionEmoji, sectionButtons) = section

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
