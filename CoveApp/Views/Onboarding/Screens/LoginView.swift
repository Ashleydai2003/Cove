// Created by Nesib Muhedin
import SwiftUI

/// Main login screen view that serves as the entry point to the app
struct LoginView: View {
    
    /// AppController environment object used for navigation and app state management
    @EnvironmentObject var appController: AppController
    
    // MARK: - Main View Body
    var body: some View {
        ZStack {
            OnboardingBackgroundView()
            
            VStack {
                // MARK: - App logo and tagline
                Text("cove")
                    .font(.LibreBodoni(size: 125))
                    .foregroundColor(Colors.primaryDark)
                    .frame(height: 70)
                    .padding(.top, 100)
                
                // App tagline with matching font style
                Text("plug back into community.")
                    .font(.LibreBodoni(size: 18))
                
                // Flexible space to push content to top and bottom
                Spacer()
                
                // MARK: - Main call-to-action button
                // Initiates the sign-in flow
                SignOnButton(text: "let's go") {
                    // TODO: DEV ONLY - Remove this and uncomment line below when done testing
                    appController.path.append(.almaMater)
                    // appController.path.append(.birthdate)
                    // appController.path.append(.userDetails)
                    // appController.path.append(.otpVerify)
                    // appController.path.append(.enterPhoneNumber) 
                }
                .padding(.bottom)
                     
                // Terms and privacy notice with interactive links
                Text(attributedString)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white)
                    .padding([.horizontal, .vertical])
                    .font(.LeagueSpartan(size: 15))
            }
        }
    }
    
    /// Creates an attributed string for the terms and privacy notice
    /// Includes interactive links for Terms & Conditions and Privacy Policy
    // TODO: Add links to Terms and Privacy Policy
    var attributedString: AttributedString {
        var string = AttributedString("By tapping 'Get Started' you agree to our Terms and Conditions. Learn how we process you data in our Privacy Policy.")
        string.foregroundColor = .white
        
        // Add underline and link styling to both interactive text elements
        ["Terms and Conditions", "Privacy Policy"].forEach { text in
            if let range = string.range(of: text) {
                string[range].underlineStyle = .single
                string[range].link = URL(string: "")
            }
        }
        
        return string
    }
}

// MARK: - SignOnButton
/// Reusable button component for sign-on actions
/// Features a consistent style with custom text and action
struct SignOnButton: View {
    let text: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.LibreBodoni(size: 25))
                .frame(maxWidth: .infinity)  // Makes button expand to full width
                .padding()
                .foregroundStyle(Colors.primaryLight)
                .background(Colors.primaryDark)
                .cornerRadius(16.99)  // Consistent corner radius for rounded appearance
                .padding(.horizontal, 50)  // Horizontal padding for button container
        }
    }
}

struct OnboardingBackgroundView: View {
    var body: some View {
        Color(Colors.primaryLight).ignoresSafeArea()
    }
}

/// Preview provider for SwiftUI canvas
#Preview {
    LoginView()
        .environmentObject(AppController.shared)
} 
