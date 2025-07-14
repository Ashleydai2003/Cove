// Created by Ananya Agarwal

import SwiftUI

/// View for collecting user's hobbies during onboarding
/// Simple categorized hobby selection with visual feedback
struct HobbiesView: View {
    // MARK: - Environment & State Properties
    
    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController
    
    /// Tracks which hobbies are currently selected
    @State private var selectedHobbies: Set<String> = []
    
    // MARK: - Data
    
    /// Simple hobby categories with 8 options each
    private let hobbyData: [(String, [(String, String)])] = [
        ("Activities", [
            ("Bars", "🍸"),
            ("Nightclubs", "💃"),
            ("Live Music", "🎸"),
            ("Music Festivals", "🎶"),
            ("Art Classes", "🖼️"),
            ("Cooking Classes", "👨‍🍳"),
            ("Board Games", "🎲"),
            ("Poker", "♠️"),
        ]),
        ("Fitness", [
            ("Running", "🏃‍♀️"),
            ("Soccer", "⚽️"),
            ("Basketball", "🏀"),
            ("Pickleball", "🥎"),
            ("Tennis", "🎾"),
            ("Hiking", "🥾"),
            ("Yoga", "🧘‍♀️"),
            ("Pilates", "💪"),
            ("Surfing", "🏄‍♀️"),
            ("Cycling", "🚴‍♀️"),
            ("Climbing", "🧗‍♀️"),
        ]),
        ("Groups", [
            ("Book Clubs", "📚"),
            ("Remote work & Cafe", "☕️"),
            ("Founders", "👨‍💻"),
            ("Technies and Hackers", "👨‍💻"),
        ])
    ]
    
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
                    Text("What do you want to do in your city?")
                        .foregroundStyle(Colors.primaryDark)
                        .font(.LibreBodoniMedium(size: 40))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("select whatever stands out to you")
                        .font(.LeagueSpartan(size: 15))
                        .foregroundColor(Colors.k0B0B0B)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 40)
                
                // Hobbies categories
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                        ForEach(hobbyData, id: \.0) { category in
                            VStack(alignment: .leading, spacing: 15) {
                                // Category title
                                Text(category.0)
                                    .font(.LeagueSpartanMedium(size: 18))
                                    .foregroundColor(Colors.primaryDark)
                                
                                // Hobby options in 2x4 grid
                                VStack(spacing: 12) {
                                    ForEach(0..<4) { row in
                                        HStack(spacing: 12) {
                                            ForEach(0..<2) { col in
                                                let index = row * 2 + col
                                                if index < category.1.count {
                                                    let hobby = category.1[index]
                                                    HobbyButton(
                                                        text: hobby.0,
                                                        emoji: hobby.1,
                                                        isSelected: selectedHobbies.contains(hobby.0)
                                                    ) {
                                                        if selectedHobbies.contains(hobby.0) {
                                                            selectedHobbies.remove(hobby.0)
                                                        } else {
                                                            selectedHobbies.insert(hobby.0)
                                                        }
                                                    }
                                                }
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
                    .stroke(Colors.primaryDark, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    HobbiesView()
        .environmentObject(AppController.shared)
}
