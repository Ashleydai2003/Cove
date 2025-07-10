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
        VStack {
            OnboardingBackgroundView()
            HStack {
                Button {
                    appController.path.removeLast()
                } label: {
                    Images.backArrow
                }
                Spacer()
            }
            .padding(.top, 10)
            
            Text("what is your alma \nmater?")
                .foregroundStyle(Colors.primaryDark)
                .font(.LibreBodoniMedium(size: 40))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
            
            Text("find people from within your network, then others. (optional)")
                .font(.LeagueSpartan(size: 15))
                .foregroundColor(Colors.k0B0B0B)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack {
                TextField("", text: $searchUniversity)
                    .font(.LeagueSpartan(size: 30))
                    .foregroundStyle(Colors.k060505)
                    .keyboardType(.alphabet)
                    .onChange(of: searchUniversity) { oldValue, newValue in
                        searchUniversity = newValue.lowercaseIfNotEmpty
                    }
                
                Divider()
                    .frame(height: 2)
                    .background(Colors.k060505)
            }
            .padding(.top, 40)
            
            if searchUniversity.count > 0 {
                VStack(spacing: 5) {
                    Spacer().frame(height: 5)
                    
                    ScrollView(.vertical) {
                        ForEach(filteredUniversities, id: \.self) { university in
                            Button {
                                searchUniversity = university
                            } label: {
                                Text(university)
                                    .font(.LeagueSpartanMedium(size: 20))
                                    .foregroundColor(Colors.k0F100F)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding([.horizontal], 10)
                                    .padding(.vertical, 5)
                            }
                        }
                    }
                    
                    Spacer().frame(height: 5)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .frame(height: 185)
                .padding(.top, 5)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Images.smily
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
