// Created by Ananya Agarwal

import SwiftUI
import UIKit

/// View for collecting user's first and last name during onboarding
/// Handles name input validation and navigation to birthdate screen
struct NamePageView: View {
    // MARK: - Environment & State Properties

    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController

    /// User's first and last name input fields
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @FocusState private var isFirstNameFocused: Bool
    
    /// Error state
    @State private var showingError = false

    // MARK: - View Body

    var body: some View {
        ZStack {
            // Main content container
            OnboardingBackgroundView()
            VStack {
                // MARK: - Header Section
                VStack(alignment: .leading) {
                    Text("what's your \nname?")
                        .font(.LibreBodoni(size: 40))
                        .foregroundColor(Colors.primaryDark)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("only your first name will be displayed.")
                        .font(.LeagueSpartan(size: 15))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 40)

                // MARK: - Name Input Section
                VStack {
                    // First name input field
                    TextField("first name", text: $firstName)
                        .font(.LibreCaslon(size: 25))
                        .padding(.horizontal, 10)
                        .focused($isFirstNameFocused)
                        .autocorrectionDisabled()
                        .onChange(of: firstName) { oldValue, newValue in
                            firstName = newValue.lettersAndHyphensOnly
                        }

                    Divider()
                        .frame(height: 2)
                        .background(Color.black.opacity(0.58))

                    // Last name input field
                    TextField("last name", text: $lastName)
                        .font(.LibreCaslon(size: 25))
                        .padding(.top)
                        .padding(.horizontal, 10)
                        .autocorrectionDisabled()
                        .onChange(of: lastName) { oldValue, newValue in
                            lastName = newValue.lettersAndHyphensOnly
                        }

                    Divider()
                        .frame(height: 2)
                        .background(Color.black.opacity(0.58))
                }
                .padding(.top, 40)

                Spacer()

                // MARK: - Navigation Helper
                HStack {
                    Spacer()
                    Images.nextArrow
                        .resizable()
                        .frame(width: 52, height: 52)
                        .padding(.init(top: 0, leading: 0, bottom: 60, trailing: 20))
                        .opacity((firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.5 : 1.0)
                        .onTapGesture {
                            // MARK: - Validate names
                            let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
                            let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if trimmedFirstName.isEmpty || trimmedLastName.isEmpty {
                                appController.errorMessage = "Please enter both your first and last name"
                                showingError = true
                                return
                            }
                            
                            // TODO: Strip whitespace from first and last name
                            // TODO: Maybe make a dedicated struct for onboarding functions
                            Onboarding.storeName(firstName: trimmedFirstName, lastName: trimmedLastName)
                            appController.path.append(.birthdate)
                        }
                }
            }
            .padding(.horizontal, 20)
            .safeAreaPadding()
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            isFirstNameFocused = true
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {
                showingError = false
            }
        } message: {
            Text(appController.errorMessage)
        }
    }
}

// MARK: - Preview
#Preview {
    NamePageView()
        .environmentObject(AppController.shared)
}
