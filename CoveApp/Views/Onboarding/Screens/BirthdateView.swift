//
//  BirthdateView.swift
//  Cove
//

import SwiftUI

struct BirthdateView: View {
    
    @EnvironmentObject var appController: AppController
    
    @State private var date: String = ""
    @State private var month: String = ""
    @State private var year: String = ""
    @FocusState private var isFocused: Bool
    
    // Custom input accessory view for keyboard
    private var keyboardAccessoryView: some View {
        HStack {
            Spacer()
            Button("Done") {
                isFocused = false
            }
            .padding(.trailing, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                OnboardingBackgroundView(imageName: "birthdate_background")
                    .opacity(0.2)
                
                VStack {
                    HStack {
                        Button {
                            appController.path.removeLast()
                        } label: {
                            Images.backArrow
                        }
                        Spacer()
                    }
                    .padding(.top, 10)
                    
                    VStack(alignment: .leading) {
                        
                        Text("when's your \nbirthday?")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 40))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("only your age will be displayed on your profile")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LeagueSpartan(size: 15))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 40)
                    
                    HStack(spacing: 10) {
                        Spacer()
                        
                        VStack(alignment: .center) {
                            TextField("mm", text: $month)
                                .keyboardType(.numberPad)
                                .foregroundStyle(Color.black)
                                .multilineTextAlignment(.center)
                                .font(.LibreCaslon(size: 24))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                .focused($isFocused)
                                .onChange(of: month) { oldValue, newValue in
                                    validateMonth(newValue, oldValue: oldValue)
                                }
                                .toolbar {
                                    ToolbarItem(placement: .keyboard) {
                                        keyboardAccessoryView
                                    }
                                }
                            
                            Divider()
                                .frame(height: 2)
                                .background(Color.black.opacity(0.58))
                        }
                        
                        Images.lineDiagonal
                        
                        VStack {
                            TextField("dd", text: $date)
                                .keyboardType(.numberPad)
                                .foregroundStyle(Color.black)
                                .multilineTextAlignment(.center)
                                .font(.LibreCaslon(size: 24))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                .focused($isFocused)
                                .onChange(of: date) { oldValue, newValue in
                                    validateDate(newValue, oldValue: oldValue)
                                }
                                .toolbar {
                                    ToolbarItem(placement: .keyboard) {
                                        keyboardAccessoryView
                                    }
                                }
                            
                            Divider()
                                .frame(height: 2)
                                .background(Color.black.opacity(0.58))
                        }
                        
                        Images.lineDiagonal
                        
                        VStack {
                            TextField("yyyy", text: $year)
                                .keyboardType(.numberPad)
                                .foregroundStyle(Color.black)
                                .multilineTextAlignment(.center)
                                .font(.LibreCaslon(size: 24))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                .focused($isFocused)
                                .toolbar {
                                    ToolbarItem(placement: .keyboard) {
                                        keyboardAccessoryView
                                    }
                                }
                            
                            Divider()
                                .frame(height: 2)
                                .background(Color.black.opacity(0.58))
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Images.smily
                            .resizable()
                            .frame(width: 52, height: 52)
                            .padding(.init(top: 0, leading: 0, bottom: 60, trailing: 20))
                            .onTapGesture {
                                appController.completeOnboarding()
                            }
                    }
                }
                .padding(.horizontal, 20)
                .safeAreaPadding()
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    func validateMonth(_ newValue: String, oldValue: String) {
        // Remove non-digits and limit to 2 characters
        if newValue.isEmpty {
            return
        }
        let filtered = newValue.filter { $0.isNumber }
        if let number = Int(filtered), (1...12).contains(number) {
            month = filtered
        } else {
            month = oldValue
        }
    }
    
    func validateDate(_ newValue: String, oldValue: String) {
        if newValue.isEmpty {
            return
        }
        let filtered = newValue.filter { $0.isNumber }
        if let number = Int(filtered), (1...31).contains(number) {
            date = filtered
        } else {
            date = oldValue
        }
    }
}

#Preview {
    BirthdateView()
}
