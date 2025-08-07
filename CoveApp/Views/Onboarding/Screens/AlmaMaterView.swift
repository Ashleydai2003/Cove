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
    @State private var universities: [String] = ["Stanford University", "Stanford Graduate School of Business", "Stanford School of Medicine", "Stanford Law School", "Stanford Graduate School of Education"]

    /// Error state
    @State private var showingError = false

    // Generate years from 2000 to current year + 4
    private var availableYears: [String] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let maxYear = currentYear + 4
        return Array(2000...maxYear).map { String($0) }.reversed()
    }

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
            Text("what is your alma \nmater?")
                .foregroundStyle(Colors.primaryDark)
                .font(.LibreBodoniMedium(size: 40))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("find people from within your network, then others. (optional)")
                .font(.LeagueSpartan(size: 15))
                .foregroundColor(Colors.k0B0B0B)
                .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 40)

                // Search input section
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        if searchUniversity.isEmpty {
                            Text("search universities...")
                                .foregroundColor(Colors.k656566)
                                .font(.LeagueSpartan(size: 30))
                        }

                TextField("", text: $searchUniversity)
                    .font(.LeagueSpartan(size: 30))
                    .foregroundStyle(Colors.k060505)
                    .keyboardType(.alphabet)
                            .focused($isUniversityFocused)
                    .onChange(of: searchUniversity) { oldValue, newValue in
                                let processedValue = newValue.lowercaseIfNotEmpty
                                searchUniversity = processedValue
                                // Only show dropdown if user is typing (length increased or changed but not empty)
                                if !processedValue.isEmpty && processedValue != oldValue {
                                    showUniversityDropdown = true
                                } else if processedValue.isEmpty {
                                    showUniversityDropdown = false
                                }
                            }
                    }

                Divider()
                    .frame(height: 2)
                    .background(Colors.k060505)
            }
                .padding(.top, 30)

                // Graduation year input section
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        if gradYear.isEmpty {
                            Text("graduation year...")
                                .foregroundColor(Colors.k656566)
                                .font(.LeagueSpartan(size: 30))
                        }

                        TextField("", text: $gradYear)
                            .font(.LeagueSpartan(size: 30))
                            .foregroundStyle(Colors.k060505)
                            .keyboardType(.numberPad)
                            .onChange(of: gradYear) { oldValue, newValue in
                                // Only allow numeric input and limit to 4 digits
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered.count <= 4 {
                                    gradYear = filtered
                                    // Only show dropdown if user is typing (value changed and not empty)
                                    if !filtered.isEmpty && filtered != oldValue {
                                        showYearDropdown = true
                                    } else if filtered.isEmpty {
                                        showYearDropdown = false
                                    }
                                } else {
                                    gradYear = oldValue
                                }
                            }
                    }

                    Divider()
                        .frame(height: 2)
                        .background(Colors.k060505)
                }
                .padding(.top, 20)

                // University suggestions list
                if searchUniversity.count > 0 && showUniversityDropdown {
                    VStack(spacing: 0) {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                        ForEach(filteredUniversities, id: \.self) { university in
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

                                    if university != filteredUniversities.last {
                                        Divider()
                                            .background(Colors.k060505.opacity(0.2))
                            }
                        }
                    }
                        }
                    }
                    .background(Colors.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(height: min(CGFloat(filteredUniversities.count * 44), 200))
                    .padding(.top, 10)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }

                // Graduation year suggestions list
                if gradYear.count > 0 && showYearDropdown {
                    VStack(spacing: 0) {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(filteredYears, id: \.self) { year in
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

                                    if year != filteredYears.last {
                                        Divider()
                                            .background(Colors.k060505.opacity(0.2))
                                    }
                                }
                            }
                        }
                    }
                    .background(Colors.primaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(height: min(CGFloat(filteredYears.count * 44), 200))
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
                    .opacity((searchUniversity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || gradYear.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.5 : 1.0)
                    .onTapGesture {
                        // MARK: - Validate university and graduation year
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
                        
                        // Validate graduation year is a reasonable year
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
                        
                            // MARK: - Store alma mater and grad year
                        // TODO: can consider using university IDs instead of names
                        Onboarding.storeAlmaMater(almaMater: trimmedUniversity)
<<<<<<< HEAD
                        Onboarding.storeGraduationYear(year: trimmedYear)
                            // TODO: Store grad year when backend supports it
                            appController.path.append(.citySelection)
=======
                        Onboarding.storeGradYear(gradYear: trimmedYear)
                        appController.path.append(.citySelection)
>>>>>>> c45d4ab99592d1a55f4c93c21d7061d5f4adfa12
                    }
            }
        }
        .padding(.horizontal, 32)
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
        if searchUniversity.isEmpty {
            return universities
        } else {
            return universities.filter { $0.localizedCaseInsensitiveContains(searchUniversity) }
        }
    }

    var filteredYears: [String] {
        if gradYear.isEmpty {
            return availableYears
        } else {
            return availableYears.filter { $0.hasPrefix(gradYear) }
        }
    }
}

#Preview {
    AlmaMaterView()
}
