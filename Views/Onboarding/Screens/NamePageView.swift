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

    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // Main content container
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
                        .onChange(of: firstName) { oldValue, newValue in
                            if !newValue.isEmpty {
                                let filtered = newValue.filter { $0.isLetter || $0 == "-" }
                                if filtered != newValue {
                                    firstName = filtered
                                }
                            }
                        }
                    
                    Divider()
                        .frame(height: 2)
                        .background(Color.black.opacity(0.58))
                    
                    // Last name input field
                    TextField("last name", text: $lastName)
                        .font(.LibreCaslon(size: 25))
                        .padding(.top)
                        .padding(.horizontal, 10)
                        .onChange(of: lastName) { oldValue, newValue in
                            if !newValue.isEmpty {
                                let filtered = newValue.filter { $0.isLetter || $0 == "-" }
                                if filtered != newValue {
                                    lastName = filtered
                                }
                            }
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
                    Images.smily
                        .resizable()
                        .frame(width: 52, height: 52)
                        .padding(.init(top: 0, leading: 0, bottom: 60, trailing: 20))
                        .onTapGesture {
                            //TODO: Push first name & last name on Cloud
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
    }
}

// MARK: - Preview
#Preview {
    NamePageView()
        .environmentObject(AppController.shared)
} 
