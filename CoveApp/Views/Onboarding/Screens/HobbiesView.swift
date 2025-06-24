// Created by Ananya Agarwal

import SwiftUI
import Inject

/// View for collecting user's hobbies during onboarding
/// Features a searchable grid of hobby categories with selectable buttons
/// Allows users to add custom hobbies that don't exist in the predefined list
struct HobbiesView: View {
    // MARK: - Environment & State Properties
    
    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController
    
    /// Tracks which hobbies are currently selected
    @State private var selectedButtons: Set<String> = []
    
    /// Current search text for filtering hobbies
    @State private var searchText: String = ""
    
    /// Stores custom hobbies added by the user
    @State private var customHobbies: [(String, String)] = []
    
    /// Enables hot reloading during development
    @ObserveInjection var inject
    
    // MARK: - Layout Configuration
    
    /// Grid layout configuration for hobby buttons
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    // MARK: - Data Models
    
    /// Predefined categories of hobbies with their associated activities and emojis
    private let hobbyCategories: [(String, [(String, String)])] = [
        ("Sports & Fitness 🏃‍♀️", [
            ("Soccer Teams", "⚽️"),
            ("Basketball Leagues", "🏀"),
            ("Tennis Groups", "🎾"),
            ("Hiking Groups", "🥾"),
            ("Yoga Classes", "🧘‍♀️"),
            ("Surfing Meetups", "🏄‍♀️"),
            ("Rock Climbing", "🧗‍♀️"),
            ("Swimming Clubs", "🏊‍♀️"),
            ("Running Groups", "🏃‍♀️"),
            ("Volleyball Teams", "🏐"),
            ("Spin Classes", "🚴‍♀️"),
            ("Boxing Clubs", "🥊"),
            ("CrossFit Groups", "💪"),
            ("Dance Fitness", "💃"),
            ("Beach Volleyball", "🏖️"),
            ("Ultimate Frisbee", "🥏"),
            ("Pickleball Clubs", "🏓"),
            ("Golf Leagues", "⛳️")
        ]),
        ("Creative Pursuits 🎨", [
            ("Art Museums", "🖼️"),
            ("Pottery Classes", "🏺"),
            ("Dance Studios", "💃"),
            ("Music Festivals", "🎵"),
            ("Theater Groups", "🎭"),
            ("Cooking Classes", "👨‍🍳"),
            ("Craft Workshops", "✂️"),
            ("Writing Circles", "✍️"),
            ("Film Clubs", "🎬"),
            ("Photography Walks", "📸"),
            ("Painting Classes", "🎨"),
            ("Sculpture Workshops", "🗿"),
            ("Jewelry Making", "💍"),
            ("Glass Blowing", "🔥"),
            ("Digital Art Clubs", "🖥️"),
            ("Street Art Tours", "🎯"),
            ("Fashion Design", "👗"),
            ("Woodworking", "🪚")
        ]),
        ("Entertainment 🎉", [
            ("Cocktail Bars", "🍸"),
            ("Clubs", "🍷"),
            ("Wine Tastings", "🍷"),
            ("Comedy Clubs", "😄"),
            ("Karaoke Nights", "🎤"),
            ("Escape Rooms", "🔐"),
            ("Bowling Leagues", "🎳"),
            ("Live Music Venues", "🎸"),
            ("Jazz Clubs", "🎺"),
            ("Rooftop Bars", "🌆"),
            ("Beer Gardens", "🍺"),
            ("Game Nights", "🎲"),
            ("Dance Clubs", "💃"),
            ("Piano Bars", "🎹"),
            ("Magic Shows", "🎩"),
            ("Burlesque Shows", "✨"),
            ("Improv Classes", "🎭"),
            ("Casino Nights", "🎰")
        ]),
        ("Social Activities 🌟", [
            ("Book Clubs", "📚"),
            ("Travel Groups", "✈️"),
            ("Founders Groups", "💻"),
            ("Chess Clubs", "♟️"),
            ("Volunteer Groups", "🤝"),
            ("Language Exchange", "🗣️"),
            ("Food Tours", "🍽️"),
            ("Coffee Meetups", "☕️"),
            ("Tech Meetups", "💻"),
            ("Gardening Clubs", "🌱"),
            ("Cultural Events", "🎪"),
            ("Philosophy Clubs", "🤔"),
            ("Astronomy Groups", "🔭"),
            ("Hiking Meetups", "🥾"),
            ("Wine & Paint", "🎨"),
            ("Cooking Classes", "👨‍🍳"),
            ("Board Game Nights", "🎲"),
            ("Trivia Teams", "🧠")
        ])
    ]
    
    // MARK: - Computed Properties
    
    /// Filters categories and hobbies based on search text
    /// Returns only categories that have matching hobbies
    private var filteredCategories: [(String, [(String, String)])] {
        if searchText.isEmpty {
            return hobbyCategories
        }
        
        return hobbyCategories.compactMap { category in
            let filteredHobbies = category.1.filter { hobby in
                hobby.0.lowercased().contains(searchText.lowercased())
            }
            
            if filteredHobbies.isEmpty {
                return nil
            }
            
            return (category.0, filteredHobbies)
        }
    }
    
    /// Checks if the current search text matches any existing hobby
    private var isExistingHobby: Bool {
        let allHobbies = hobbyCategories.flatMap { $0.1 }
        return allHobbies.contains { $0.0.lowercased() == searchText.lowercased() }
    }
    
    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()
            
            // Main content container
            VStack(spacing: 0) {
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
                    Text("what are your favorite social pass times?")
                        .foregroundStyle(Colors.primary)
                        .font(.LibreBodoni(size: 35))
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text("select at least 5 activities you wish to see in your area.")
                            .foregroundStyle(Colors.primary)
                            .font(.LeagueSpartan(size: 12))
                        
                        Image("smiley")
                            .resizable()
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // Search section
                VStack(spacing: 8) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search or add activities...", text: $searchText)
                            .font(.LeagueSpartan(size: 14))
                            .onChange(of: searchText) { oldValue, newValue in
                                searchText = newValue.lowercaseIfNotEmpty
                            }
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Add custom hobby button
                    if !searchText.isEmpty && !isExistingHobby {
                        Button(action: {
                            customHobbies.append((searchText, "✨"))
                            selectedButtons.insert(searchText)
                            searchText = ""
                        }) {
                            HStack {
                                Text("Add '\(searchText)' as a hobby")
                                    .font(.LeagueSpartan(size: 14))
                                Image(systemName: "plus.circle.fill")
                            }
                            .foregroundColor(Colors.primary)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Hobbies grid
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Predefined categories
                        ForEach(filteredCategories, id: \.0) { category in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(category.0)
                                    .font(.LeagueSpartan(size: 16))
                                    .foregroundStyle(Colors.primary)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(category.1, id: \.0) { hobby in
                                        Button(action: {
                                            if selectedButtons.contains(hobby.0) {
                                                selectedButtons.remove(hobby.0)
                                            } else {
                                                selectedButtons.insert(hobby.0)
                                            }
                                        }) {
                                            ZStack {
                                                Image(selectedButtons.contains(hobby.0) ? "buttonRed" : "buttonWhite")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                
                                                HStack(spacing: 4) {
                                                    Text(hobby.1)
                                                    Text(hobby.0.lowercased())
                                                }
                                                .foregroundColor(selectedButtons.contains(hobby.0) ? .white : .black)
                                                .font(.LeagueSpartan(size: 14))
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .multilineTextAlignment(.center)
                                            }
                                            .frame(height: 48)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Custom hobbies section
                        if !customHobbies.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Custom Hobbies ✨")
                                    .font(.LeagueSpartan(size: 16))
                                    .foregroundStyle(Colors.primary)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(customHobbies, id: \.0) { hobby in
                                        Button(action: {
                                            if selectedButtons.contains(hobby.0) {
                                                selectedButtons.remove(hobby.0)
                                            } else {
                                                selectedButtons.insert(hobby.0)
                                            }
                                        }) {
                                            ZStack {
                                                Image(selectedButtons.contains(hobby.0) ? "buttonRed" : "buttonWhite")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                
                                                HStack(spacing: 4) {
                                                    Text(hobby.1)
                                                    Text(hobby.0.lowercased())
                                                }
                                                .foregroundColor(selectedButtons.contains(hobby.0) ? .white : .black)
                                                .font(.LeagueSpartan(size: 14))
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .multilineTextAlignment(.center)
                                            }
                                            .frame(height: 48)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Navigation helper
                HStack {
                    Spacer()
                    Images.smily
                        .resizable()
                        .frame(width: 52, height: 52)
                        .padding(.init(top: 0, leading: 0, bottom: 20, trailing: 20))
                        .onTapGesture {
                            // MARK: - Store hobbies
                            Onboarding.storeHobbies(hobbies: selectedButtons)
                            appController.path.append(.bio)
                        }
                }
            }
            .padding(.horizontal, 20)
            .safeAreaPadding()
        }
        .navigationBarBackButtonHidden()
        .enableInjection()
    }
}

// MARK: - Preview
#Preview {
    HobbiesView()
        .environmentObject(AppController.shared)
}
