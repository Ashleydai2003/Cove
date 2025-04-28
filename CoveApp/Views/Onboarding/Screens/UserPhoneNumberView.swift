//
//  UserPhoneNumberView.swift
//  Cove
//

import SwiftUI
import Combine

struct UserPhoneNumberView: View {
    
    @EnvironmentObject var appController: AppController
    
    @State private var presentSheet = false
    @State private var searchCountry: String = ""
    @FocusState private var isFocused: Bool
    
    let counrties: [Country] = Bundle.main.decode("CountryList.json")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // For background
                OnboardingBackgroundView(imageName: "phoneNumber_background")
                    .opacity(0.4)
                
                VStack {
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("what's your phone \nnumber?")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 40))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("verification code will be sent to the following number. message and data rates may apply.")
                            .foregroundStyle(Color.black)
                            .font(.LeagueSpartan(size: 15))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 40)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 16) {
                        VStack(spacing: 2) {
                            Button {
                                presentSheet = true
                            } label: {
                                HStack {
                                    Text(appController.selectedCountry.flag)
                                        .foregroundStyle(Color.black)
                                        .font(.LibreBodoni(size: 30))
                                    
                                    Images.downArrowSolid
                                        .resizable()
                                        .frame(width: 19, height: 14)
                                }
                            }
                            
                            Divider()
                                .frame(height: 2)
                                .background(Color.black.opacity(0.58))
                        }
                        .frame(width: 66)
                        
                        VStack(spacing: 2) {
                            HStack {
                                Text(appController.selectedCountry.dial_code)
                                    .foregroundStyle(Color.black)
                                    .font(.LibreCaslon(size: 25))
                                
                                TextField(appController.selectedCountry.pattern, text: $appController.phoneNumber)
                                    .font(.LibreCaslon(size: 25))
                                    .foregroundStyle(Color.black)
                                    .keyboardType(.numberPad)
                                    .focused($isFocused)
                                    .onChange(of: appController.phoneNumber) { _, newValue in
                                        appController.phoneNumber = appController.formatPhoneNumber(newValue, pattern: appController.selectedCountry.pattern)
                                    }
                            }
                            
                            Divider()
                                .frame(height: 2)
                                .background(Color.black.opacity(0.58))
                        }
                    }
                    .padding(.top, 85)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Images.smily
                            .resizable()
                            .frame(width: 52, height: 52)
                            .padding(.init(top: 0, leading: 0, bottom: 60, trailing: 20))
                            .onTapGesture {
                                appController.path.append(.otpVerify)
                            }
                    }
                }
                .padding(.horizontal, 20)
                .safeAreaPadding()
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isFocused = false // Dismiss keyboard
                        }
                    }
                }
            }
            .sheet(isPresented: $presentSheet) {
                NavigationView {
                    List(filteredResorts) { country in
                        Button {
                            appController.selectedCountry = country
                            presentSheet = false
                            searchCountry = ""
                        } label: {
                            HStack {
                                Text(country.flag)
                                Text(country.name)
                                    .font(.body)
                                Spacer()
                                Text(country.dial_code)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.08))
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchCountry, prompt: "Your country")
                }
                .presentationDetents([.medium, .large])
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    var filteredResorts: [Country] {
        if searchCountry.isEmpty {
            return counrties
        } else {
            return counrties.filter { $0.name.localizedCaseInsensitiveContains(searchCountry) }
        }
    }
}

#Preview {
    UserPhoneNumberView()
}
