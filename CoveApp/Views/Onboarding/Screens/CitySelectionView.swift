//
//  CitySelectionView.swift
//  Cove
//
//  Created by Nina Boord

import SwiftUI

struct CitySelectionView: View {

    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController

    @State private var searchCity = ""
    @State private var showCityDropdown = false
    @FocusState private var isCityFocused: Bool
    
    /// Error state
    @State private var showingError = false

    @State private var cities: [String] = [
        "New York", "San Francisco", "Los Angeles", "Boston", "Chicago", "Seattle", "Austin",
        "Washington D.C.", "Denver", "Atlanta", "Philadelphia", "San Diego", "Miami", "Portland",
        "Nashville", "Dallas", "Houston", "Phoenix", "Minneapolis", "Charlotte", "Raleigh",
        "Tampa", "Orlando", "San Jose", "Oakland", "Sacramento", "Boulder", "Madison",
        "Ann Arbor", "Pittsburgh", "Baltimore", "Richmond", "Columbus", "Cincinnati",
        "Cleveland", "Detroit", "Milwaukee", "Kansas City", "St. Louis", "New Orleans",
        "Salt Lake City", "Boise", "Las Vegas", "Tucson", "Albuquerque", "Oklahoma City",
        "Omaha", "Des Moines", "Buffalo", "Hartford"
    ]

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
                    Text("what city are you \nliving in?")
                        .foregroundStyle(Colors.primaryDark)
                        .font(.LibreBodoniMedium(size: 40))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("connect with others in your area. (optional)")
                        .font(.LeagueSpartan(size: 15))
                        .foregroundColor(Colors.k0B0B0B)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 40)

                // City search input section
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        if searchCity.isEmpty {
                            Text("search cities...")
                                .foregroundColor(Colors.k656566)
                                .font(.LeagueSpartan(size: 30))
                        }

                        TextField("", text: $searchCity)
                            .font(.LeagueSpartan(size: 30))
                            .foregroundStyle(Colors.k060505)
                            .keyboardType(.alphabet)
                            .focused($isCityFocused)
                            .onChange(of: searchCity) { oldValue, newValue in
                                let processedValue = newValue.lowercaseIfNotEmpty
                                searchCity = processedValue
                                // Only show dropdown if user is typing (length increased or changed but not empty)
                                if !processedValue.isEmpty && processedValue != oldValue {
                                    showCityDropdown = true
                                } else if processedValue.isEmpty {
                                    showCityDropdown = false
                                }
                            }
                    }

                    Divider()
                        .frame(height: 2)
                        .background(Colors.k060505)
                }
                .padding(.top, 30)

                // City suggestions list
                if searchCity.count > 0 && showCityDropdown {
                    VStack(spacing: 0) {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(filteredCities, id: \.self) { city in
                                    Button {
                                        searchCity = city
                                        Onboarding.storeCity(city: city)
                                        DispatchQueue.main.async {
                                            showCityDropdown = false
                                        }
                                    } label: {
                                        Text(city.lowercased())
                                            .font(.LeagueSpartanMedium(size: 18))
                                            .foregroundColor(Colors.k0F100F)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    }
                                    .background(Color.clear)

                                    if city != filteredCities.last {
                                        Divider()
                                            .background(Colors.k060505.opacity(0.2))
                                    }
                                }
                            }
                        }
                    }
                    .background(Colors.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(height: min(CGFloat(filteredCities.count * 44), 200))
                    .padding(.top, 10)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }

                Spacer()

                // Continue button
                HStack {
                    Spacer()
                    Images.nextArrow
                        .resizable()
                        .frame(width: 52, height: 52)
                        .padding(.bottom, 20)
                        .opacity(searchCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                        .onTapGesture {
                            // MARK: - Validate city selection
                            let trimmedCity = searchCity.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if trimmedCity.isEmpty {
                                appController.errorMessage = "Please select a city"
                                showingError = true
                                return
                            }
                            
                            // Validate that the city is in our list
                            let isValidCity = cities.contains { $0.localizedCaseInsensitiveContains(trimmedCity) }
                            if !isValidCity {
                                appController.errorMessage = "Please select a valid city from the list"
                                showingError = true
                                return
                            }
                            
                            // MARK: - Store city
                            Onboarding.storeCity(city: trimmedCity)
                            appController.path.append(.hobbies)
                        }
                }
            }
            .padding(.horizontal, 32)
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            isCityFocused = true
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {
                showingError = false
            }
        } message: {
            Text(appController.errorMessage)
        }
    }

    var filteredCities: [String] {
        if searchCity.isEmpty {
            return cities
        } else {
            return cities.filter { $0.localizedCaseInsensitiveContains(searchCity) }
        }
    }
}

#Preview {
    CitySelectionView()
}
