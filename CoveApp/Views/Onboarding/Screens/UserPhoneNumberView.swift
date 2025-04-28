//
//  UserPhoneNumberView.swift
//  Cove
//

import SwiftUI
import Combine

struct UserPhoneNumberView: View {
    
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
    @State private var presentSheet = false
    @State private var mobileNumber = ""
    @State private var searchCountry: String = ""
    @FocusState private var isFocused: Bool
    
    @State private var country: Country = Country(id: "0235", name: "USA", flag: "🇺🇸", code: "US", dial_code: "+1", pattern: "### ### ####", limit: 17)
    
    let counrties: [Country] = Bundle.main.decode("CountryList.json")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // For background
                OnboardingBackgroundView(imageName: "phoneNumber_background")
                    .opacity(0.4)
                
                VStack {
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("what’s your phone \nnumber?")
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
                                    Text(country.flag)
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
                                Text(country.dial_code)
                                    .foregroundStyle(Color.black)
                                    .font(.LibreCaslon(size: 25))
                                
                                TextField(country.pattern, text: $mobileNumber)
                                    .font(.LibreCaslon(size: 25))
                                    .foregroundStyle(Color.black)
                                    .keyboardType(.numberPad)
                                    .focused($isFocused)
                                    .onReceive(Just(mobileNumber)) { _ in
                                        applyPatternOnNumbers(&mobileNumber, pattern: country.pattern, replacementCharacter: "#")
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
                                onboardingViewModel.path.append(.optVerify)
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
                            self.country = country
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
    
    func applyPatternOnNumbers(_ stringvar: inout String, pattern: String, replacementCharacter: Character) {
        var pureNumber = stringvar.replacingOccurrences( of: "[^0-9]", with: "", options: .regularExpression)
        for index in 0 ..< pattern.count {
            guard index < pureNumber.count else {
                stringvar = pureNumber
                return
            }
            let stringIndex = String.Index(utf16Offset: index, in: pattern)
            let patternCharacter = pattern[stringIndex]
            guard patternCharacter != replacementCharacter else { continue }
            pureNumber.insert(patternCharacter, at: stringIndex)
        }
        stringvar = pureNumber
    }
}

#Preview {
    UserPhoneNumberView()
}
