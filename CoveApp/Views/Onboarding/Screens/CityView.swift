//
//  CityView.swift
//  Cove
//
//  Created by Ashley Dai on 10/23/25.
//

import SwiftUI

struct CityView: View {

    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController

    @State private var searchCity = ""
    @State private var showCityDropdown = false
    @FocusState private var isCityFocused: Bool
    @State private var cities: [String] = CitiesData.cities

    /// Error state
    @State private var showingError = false

    var body: some View {
        ZStack {
            OnboardingBackgroundView()

            VStack {
                // Back button
                HStack {
                    Button {
                        appController.path.removeLast()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Colors.primaryDark)
                    }
                    Spacer()
                }
                .padding(.top, 10)

                // Header section
                VStack(alignment: .leading, spacing: 10) {
                    Text("what city are you \nliving in?")
                        .foregroundStyle(Colors.primaryDark)
                        .font(.LibreBodoni(size: 40))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("connect with others in your area")
                        .font(.LeagueSpartan(size: 15))
                        .foregroundColor(Colors.k0B0B0B)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 40)

                // City search input section
                VStack(spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        // Input field
                        TextField("enter your city", text: $searchCity)
                            .font(.LibreBodoni(size: 18))
                            .foregroundColor(Colors.primaryDark)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .stroke(Colors.primaryDark, lineWidth: 1)
                            )
                            .focused($isCityFocused)
                            .onChange(of: searchCity) { _, newValue in
                                showCityDropdown = !newValue.isEmpty
                            }

                        // Dropdown suggestions
                        if showCityDropdown {
                            VStack(spacing: 0) {
                                ForEach(filteredCities, id: \.self) { city in
                                    Button {
                                        searchCity = city
                                        showCityDropdown = false
                                        isCityFocused = false
                                    } label: {
                                        HStack {
                                            Text(city)
                                                .font(.LibreBodoni(size: 16))
                                                .foregroundColor(Colors.background)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                    .buttonStyle(.plain)
                                    .background(Colors.primaryDark)

                                    if city != filteredCities.last {
                                        Divider().background(Colors.background.opacity(0.15))
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                .padding(.top, 10)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                Spacer()

                // Continue button
                SignOnButton(text: "next") {
                    let trimmedCity = searchCity.trimmingCharacters(in: .whitespacesAndNewlines)

                    if trimmedCity.isEmpty {
                        appController.errorMessage = "Please enter your city"
                        showingError = true
                        return
                    }

                    // Validate that the city is in our list
                    let isValidCity = CitiesData.cities.contains { $0.lowercased() == trimmedCity.lowercased() }
                    if !isValidCity {
                        appController.errorMessage = "Please select a city from the list"
                        showingError = true
                        return
                    }

                    Onboarding.storeCity(city: trimmedCity)
                    // Complete onboarding now that all required fields are collected
                    Onboarding.completeOnboarding { success in
                        DispatchQueue.main.async {
                            if success {
                                appController.path = [.pluggingIn]
                            } else {
                                showingError = true
                            }
                        }
                    }
                }
                .disabled(searchCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(appController.errorMessage)
        }
        .onAppear {
            isCityFocused = true
        }
    }

    private var filteredCities: [String] {
        return CitiesData.filteredCities(searchQuery: searchCity)
    }
}

// MARK: - Preview
#Preview {
    CityView()
        .environmentObject(AppController.shared)
}
