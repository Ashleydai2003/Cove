import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject var appController: AppController
    
    var body: some View {
        ZStack {
            // For background
            OnboardingBackgroundView(imageName: "login_background")
                .opacity(0.6)
            
            VStack {
                Text("cove")
                    .font(.LibreBodoni(size: 125))
                    .foregroundColor(Colors.primary)
                    .frame(height: 70)
                    .padding(.top, 100)
                
                Text("plug back into community.")
                    .font(.LibreBodoni(size: 18))
                
                // to create space in middle
                Spacer()
                
                SignOnButton(text: "let's go") {
                    appController.path.append(.enterPhoneNumber)
                }
                .padding(.bottom)
                     
                Text(attributedString)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white)
                    .padding([.horizontal, .vertical])
                    .font(.LeagueSpartan(size:15))
            }
        }
    }
    
    var attributedString: AttributedString {
        var string = AttributedString("By tapping 'Get Started' you agree to our Terms and Conditions. Learn how we process you data in our Privacy Policy.")
        string.foregroundColor = Color.white
        
        if let termsServiceRange = string.range(of: "Terms and Conditions") {
            string[termsServiceRange].underlineStyle = .single
            string[termsServiceRange].link = URL(string: "")
        }
        
        if let privacyPolicyRange = string.range(of: "Privacy Policy") {
            string[privacyPolicyRange].underlineStyle = .single
            string[privacyPolicyRange].link = URL(string: "")
        }
        
        return string
    }
}

struct SignOnButton: View {
    let text: String
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(text)
                .font(.LibreBodoni(size: 25))
                .frame(maxWidth: .infinity, minHeight: 30, maxHeight: 30)
                .padding()
                .foregroundStyle(Color.white)
                .background(Color.white)
                .cornerRadius(16.99)
                .padding(.horizontal, 50)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppController.shared)
} 
