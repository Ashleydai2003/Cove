import SwiftUI

/// Main login screen view that serves as the entry point to the app
struct PluggingYouIn: View {
    
    /// AppController environment object used for navigation and app state management
    @EnvironmentObject var appController: AppController
    @State private var rotation: Double = 0
    @State private var profile: Profile?
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Background image with reduced opacity for better text visibility
            OnboardingBackgroundView(imageName: "login_background")
                .opacity(0.6)
            
            VStack {
                Spacer()
                
                Image("smily")
                    .resizable()
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        // Start with a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // First rotation
                            withAnimation(.easeInOut(duration: 0.5)) {
                                rotation = 180
                            }
                            
                            // Second rotation after a short pause
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    rotation = 360
                                }
                                
                                // Fetch profile data
                                fetchProfile()
                                
                                // Repeat the sequence twice more
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        rotation = 540
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            rotation = 720
                                        }
                                        
                                        // Navigate to next screen after all animations
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                            if let error = errorMessage {
                                                appController.errorMessage = error
                                            }
                                            appController.path.append(.profile)
                                        }
                                    }
                                }
                            }
                        }
                    }
                
                // App tagline with matching font style
                Text("plugging you in...")
                    .font(.LibreBodoni(size: 35))
                    .foregroundColor(Colors.primaryDark)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private func fetchProfile() {
        NetworkManager.shared.get(endpoint: "/profile") { (result: Result<ProfileResponse, NetworkError>) in
            switch result {
            case .success(let response):
                profile = response.profile
                // Store profile data in UserDefaults or AppController for later use
                UserDefaults.standard.set(response.profile.name, forKey: "user_name")
                UserDefaults.standard.set(response.profile.bio, forKey: "user_bio")
                UserDefaults.standard.set(response.profile.interests, forKey: "user_interests")
                UserDefaults.standard.set(response.profile.relationStatus, forKey: "user_relation_status")
                UserDefaults.standard.set(response.profile.sexuality, forKey: "user_sexuality")
                UserDefaults.standard.set(response.profile.job, forKey: "user_job")
                UserDefaults.standard.set(response.profile.workLocation, forKey: "user_work_location")
                UserDefaults.standard.set(response.profile.almaMater, forKey: "user_alma_mater")
                UserDefaults.standard.set(response.profile.latitude, forKey: "user_latitude")
                UserDefaults.standard.set(response.profile.longitude, forKey: "user_longitude")
                UserDefaults.standard.set(response.profile.gender, forKey: "user_gender")
                
            case .failure(let error):
                errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
            }
        }
    }
}
