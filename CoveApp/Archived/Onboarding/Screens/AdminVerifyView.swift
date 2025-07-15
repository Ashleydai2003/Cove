import SwiftUI

/// View shown when a user needs to verify their admin status
struct AdminVerifyView: View {
    @EnvironmentObject var appController: AppController
    
    // MARK: Data Shared with me
    private var adminCove: String = Onboarding.getAdminCove() ?? "create new cove!"
    
    var body: some View {
        ZStack {
            // Off-white background
            Colors.faf8f4
                .ignoresSafeArea()
            
            VStack {
                // Title and message
                Text("you're an admin \nfor...")
                    .font(.LibreBodoni(size: 40))
                    .foregroundColor(Colors.primaryDark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)
                
                // Large primary dark square with text
                ZStack {
                    Rectangle()
                        .fill(Colors.primaryDark)
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(10)
                    
                    VStack(spacing: 20) {
                        Text(adminCove)
                            .font(.LibreBodoni(size: 40))
                            .foregroundColor(.white)
                            .frame(maxWidth: 200, maxHeight: 150, alignment: .center)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            appController.path.append(.userDetails)
                        } label: {
                            Circle()
                                .fill(.white)
                                .frame(maxWidth: 50)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 30, weight: .bold))
                                        .foregroundColor(Colors.primaryDark)
                                )
                        }

                        Button {
                            appController.path = [.enterPhoneNumber]
                        } label: {
                            Text("not you?")
                                .font(.LeagueSpartan(size: 15))
                                .foregroundColor(.white)
                                .underline(true, color: .white)
                        }
                    }
                }
                .padding(.top, 30)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .safeAreaPadding()
            .padding(.top, 60)
            .navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    AdminVerifyView()
        .environmentObject(AppController.shared)
} 
