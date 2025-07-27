//
//  HobbiesData.swift
//  Cove
//
//  Shared hobbies data model for use across onboarding and profile views

import Foundation

// MARK: - Hobby Data Models

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

// MARK: - Shared Hobbies Data

/// Centralized hobbies data that can be used across the app
struct HobbiesData {
    /// Complete hobby sections with their respective hobby buttons
    static let hobbyDataSections: [HobbySection] = [
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
                HobbySubOption(name: "marathons", emoji: "🏃"),
                HobbySubOption(name: "trail running", emoji: "🏃")
            ]),
            HobbyButtonOption(name: "triathlon", emoji: "💪🏼", subOptions: [
                HobbySubOption(name: "newbie", emoji: "💪🏼"),
                HobbySubOption(name: "competitive", emoji: "💪🏼")
            ]),
            HobbyButtonOption(name: "cycling", emoji: "🚴‍♀️", subOptions: []),
            HobbyButtonOption(name: "pickleball", emoji: "🥎", subOptions: []),
            HobbyButtonOption(name: "soccer", emoji: "⚽️", subOptions: []),
            HobbyButtonOption(name: "swimming", emoji: "🏊‍♀️", subOptions: []),
            HobbyButtonOption(name: "basketball", emoji: "🏀", subOptions: []),
            HobbyButtonOption(name: "volleyball", emoji: "🏐", subOptions: []),
            HobbyButtonOption(name: "tennis", emoji: "🎾", subOptions: []),
            HobbyButtonOption(name: "weightlifting", emoji: "💪", subOptions: []),
            HobbyButtonOption(name: "workout classes", emoji: "🏋🏽‍♀️", subOptions: [
                HobbySubOption(name: "yoga", emoji: "🧘‍♀️"),
                HobbySubOption(name: "pilates", emoji: "🤸‍♀️"),
                HobbySubOption(name: "dance", emoji: "💃")
            ]),
            HobbyButtonOption(name: "hiking", emoji: "🥾", subOptions: []),
            HobbyButtonOption(name: "surfing", emoji: "🏄‍♀️", subOptions: []),
            HobbyButtonOption(name: "indoor climbing", emoji: "🧗‍♀️", subOptions: []),
            HobbyButtonOption(name: "outdoor climbing", emoji: "🧗‍♀️", subOptions: []),
        ]),
        HobbySection(name: "activities", emoji: "🎨", buttons: [
            HobbyButtonOption(name: "board games", emoji: "🎲", subOptions: []),
            HobbyButtonOption(name: "poker", emoji: "♠️", subOptions: []),
            HobbyButtonOption(name: "art classes", emoji: "🖼️", subOptions: [
                HobbySubOption(name: "drawing", emoji: "✏️"),
                HobbySubOption(name: "painting", emoji: "🎨"),
                HobbySubOption(name: "ceramics", emoji: "🏺")
            ])
        ]),
        HobbySection(name: "career", emoji: "💼", buttons: [
            HobbyButtonOption(name: "founders groups", emoji: "👨‍💻", subOptions: [
                HobbySubOption(name: "aspiring founder", emoji: "💡"),
                HobbySubOption(name: "current founder", emoji: "🚀")
            ]),
            HobbyButtonOption(name: "remote work & cafe", emoji: "☕️", subOptions: []),
            HobbyButtonOption(name: "interview prep", emoji: "💼", subOptions: [
                HobbySubOption(name: "leetcode", emoji: "💻"),
                HobbySubOption(name: "consulting", emoji: "📊"),
                HobbySubOption(name: "finance", emoji: "💰")
            ]),
        ])
    ]
    
    /// Flattened hobby data for existing logic compatibility
    static var hobbyData: [HobbyButtonOption] {
        hobbyDataSections.flatMap { $0.buttons }
    }
    
    /// Get all hobby names (including sub-options) as a flat array
    static var allHobbyNames: [String] {
        var names: [String] = []
        for section in hobbyDataSections {
            for button in section.buttons {
                names.append(button.name)
                for subOption in button.subOptions {
                    names.append(subOption.name)
                }
            }
        }
        return names
    }
    
    /// Data structure for unified button display
    struct ButtonData: Identifiable {
        let id: String
        let text: String
        let emoji: String
        let isTopLevel: Bool
    }
    
    /// Helper function to get buttons for a specific section
    static func getSectionButtonsToShow(for sectionName: String, buttons: [HobbyButtonOption], expandedButtons: Set<String>) -> [ButtonData] {
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
    
    /// Helper function to find emoji for a given hobby name
    static func getEmoji(for hobbyName: String) -> String {
        for section in hobbyDataSections {
            for button in section.buttons {
                // Check top-level button
                if button.name == hobbyName {
                    return button.emoji
                }
                // Check sub-options
                for subOption in button.subOptions {
                    if subOption.name == hobbyName {
                        return subOption.emoji
                    }
                }
            }
        }
        // Return default emoji if not found
        return "🎯"
    }
} 