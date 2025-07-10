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
    
    @State private var showList: Bool = false
    @State private var universities: [String] = ["Stanford University", "Stanford Graduate School of Business", "Stanford School of Medicine", "Stanford Law School", "Stanford Graduate School of Education"]
    
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
                            .onChange(of: searchUniversity) { oldValue, newValue in
                                searchUniversity = newValue.lowercaseIfNotEmpty
                            }
                    }
                    
                    Divider()
                        .frame(height: 2)
                        .background(Colors.k060505)
                }
                .padding(.top, 30)
                
                // University suggestions list
                if searchUniversity.count > 0 {
                    VStack(spacing: 0) {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(filteredUniversities, id: \.self) { university in
                                    Button {
                                        searchUniversity = university
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
                    .frame(maxHeight: 200)
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
                        .onTapGesture {
                            // MARK: - Store alma mater
                            // TODO: can consider using university IDs instead of names
                            Onboarding.storeAlmaMater(almaMater: searchUniversity)
                            appController.path.append(.moreAboutYou)
                        }
                }
            }
            .padding(.horizontal, 32)
        }
        .navigationBarBackButtonHidden()
    }
    
    var filteredUniversities: [String] {
        if searchUniversity.isEmpty {
            return universities
        } else {
            return universities.filter { $0.localizedCaseInsensitiveContains(searchUniversity) }
        }
    }
}

#Preview {
    AlmaMaterView()
}
