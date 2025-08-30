//
//  AlmaMaterView.swift
//  Cove
//
//  Created by Nesib Muhedin

import SwiftUI

struct AlmaMaterView: View {

    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController

    @State private var searchUniversity = ""
    @State private var gradYear = ""

    @State private var showUniversityDropdown = false
    @State private var showYearDropdown = false
    @State private var showList: Bool = false
    @FocusState private var isUniversityFocused: Bool
    @State private var universities: [String] = AlmaMaterData.universities

    /// Error state
    @State private var showingError = false

    private var availableYears: [String] { GradYearsData.years }

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
            Text("what is your alma \nmater?")
                .foregroundStyle(Colors.primaryDark)
                .font(.LibreBodoni(size: 40))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("connect to your alumni network!")
                .font(.LeagueSpartan(size: 15))
                .foregroundStyle(Colors.primaryDark)
                .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 40)

                // Search input section
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        if searchUniversity.isEmpty {
                            Text("search universities...")
                                .foregroundColor(Colors.k656566)
                                .font(.LibreCaslon(size: 25))
                        }

                TextField("", text: $searchUniversity)
                    .font(.LibreCaslon(size: 25))
                    .foregroundStyle(Color.black)
                    .keyboardType(.alphabet)
                            .focused($isUniversityFocused)
                    .onChange(of: searchUniversity) { oldValue, newValue in
                                let processedValue = newValue.lowercaseIfNotEmpty
                                searchUniversity = processedValue
                                if processedValue.isEmpty {
                                    showUniversityDropdown = false
                                } else if AlmaMaterData.isValidUniversity(processedValue) {
                                    showUniversityDropdown = false
                                } else if processedValue != oldValue {
                                    showUniversityDropdown = true
                                }
                            }
                    }

                Divider()
                    .frame(height: 2)
                    .background(Color.black.opacity(0.58))
            }
                .padding(.top, 40)

                // Graduation year input section
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        if gradYear.isEmpty {
                            Text("graduation year...")
                                .foregroundColor(Colors.k656566)
                                .font(.LibreCaslon(size: 25))
                        }

                        TextField("", text: $gradYear)
                            .font(.LibreCaslon(size: 25))
                            .foregroundStyle(Color.black)
                            .keyboardType(.numberPad)
                            .onChange(of: gradYear) { oldValue, newValue in
                                // Only allow numeric input and limit to 4 digits
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered.count <= 4 {
                                    gradYear = filtered
                                    if filtered.isEmpty {
                                        showYearDropdown = false
                                    } else if GradYearsData.isValidYear(filtered) {
                                        showYearDropdown = false
                                    } else if filtered != oldValue {
                                        showYearDropdown = true
                                    }
                                } else {
                                    gradYear = oldValue
                                }
                            }
                    }

                    Divider()
                        .frame(height: 2)
                        .background(Color.black.opacity(0.58))
                }
                .padding(.top, 20)

                // University suggestions list
                if searchUniversity.count > 0 && showUniversityDropdown {
                    VStack(spacing: 0) {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                        ForEach(Array(filteredUniversities.prefix(3)), id: \.self) { university in
                            Button {
                                searchUniversity = university
                                        DispatchQueue.main.async {
                                            showUniversityDropdown = false
                                        }
                            } label: {
                                        Text(university.lowercased())
                                            .font(.LeagueSpartanMedium(size: 18))
                                    .foregroundColor(Colors.k0F100F)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    }
                                    .background(Color.clear)

                                    if university != Array(filteredUniversities.prefix(3)).last {
                                        Divider()
                                            .background(Colors.k060505.opacity(0.2))
                            }
                        }
                    }
                        }
                    }
                    .background(Colors.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(height: min(CGFloat(min(filteredUniversities.count, 3) * 44), 132))
                    .padding(.top, 10)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }

                // Graduation year suggestions list
                if gradYear.count > 0 && showYearDropdown {
                    VStack(spacing: 0) {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(Array(filteredYears.prefix(3)), id: \.self) { year in
                                    Button {
                                        gradYear = year
                                        DispatchQueue.main.async {
                                            showYearDropdown = false
                                        }
                                    } label: {
                                        Text(year)
                                            .font(.LeagueSpartanMedium(size: 18))
                                            .foregroundColor(Colors.k0F100F)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    }
                                    .background(Color.clear)

                                    if year != Array(filteredYears.prefix(3)).last {
                                        Divider()
                                            .background(Colors.k060505.opacity(0.2))
                                    }
                                }
                            }
                        }
                    }
                    .background(Colors.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(height: min(CGFloat(min(filteredYears.count, 3) * 44), 132))
                    .padding(.top, 10)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }

            Spacer()

                // Continue button
            SignOnButton(text: "next") {
                let trimmedUniversity = searchUniversity.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedYear = gradYear.trimmingCharacters(in: .whitespacesAndNewlines)

                if trimmedUniversity.isEmpty {
                    appController.errorMessage = "Please enter your university"
                    showingError = true
                    return
                }

                if trimmedYear.isEmpty {
                    appController.errorMessage = "Please enter your graduation year"
                    showingError = true
                    return
                }

                if let yearInt = Int(trimmedYear) {
                    let currentYear = Calendar.current.component(.year, from: Date())
                    if yearInt < 1950 || yearInt > currentYear + 4 {
                        appController.errorMessage = "Please enter a valid graduation year"
                        showingError = true
                        return
                    }
                } else {
                    appController.errorMessage = "Please enter a valid graduation year"
                    showingError = true
                    return
                }

                Onboarding.storeAlmaMater(almaMater: trimmedUniversity)
                Onboarding.storeGradYear(gradYear: trimmedYear)
                // Complete onboarding directly now that city/profile are removed
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
            .disabled(searchUniversity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                      gradYear.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 20)
        .safeAreaPadding()
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            isUniversityFocused = true
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {
                showingError = false
            }
        } message: {
            Text(appController.errorMessage)
        }
    }

    var filteredUniversities: [String] {
        AlmaMaterData.filteredUniversities(searchQuery: searchUniversity)
    }

    var filteredYears: [String] { GradYearsData.filteredYears(prefix: gradYear) }
}

#Preview {
    AlmaMaterView()
}
