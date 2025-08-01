// EXAMPLE OF HOW TO USE INJECT
// DON'T DELETE THIS FILE FOR NOW :)

import SwiftUI
import Inject        // 1️⃣ make sure the Inject package is imported

struct TmpView: View {
    @State private var showingAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Crashlytics Test")
                .font(.title)
                .padding()
            
            Button("Test Crashlytics Logging") {
                // Test various Crashlytics features
                CrashlyticsHandler.log("Test log message from TmpView")
                CrashlyticsHandler.setCustomValue("test_value", forKey: "test_key")
                CrashlyticsHandler.recordCustomError(domain: "CoveApp.Test", code: 123, message: "Test error from TmpView")
                
                showingAlert = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("Test Network Error") {
                let error = NSError(domain: "Test", code: 404, userInfo: [NSLocalizedDescriptionKey: "Test network error"])
                CrashlyticsHandler.recordNetworkError(error, endpoint: "/test/endpoint", method: "GET")
                
                showingAlert = true
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("Test Onboarding Error") {
                let error = NSError(domain: "Test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Test onboarding error"])
                CrashlyticsHandler.recordOnboardingError(error, step: "name_input")
                
                showingAlert = true
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .alert("Test Complete", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Check the Firebase Console for the test logs and errors.")
        }
    }
}

#Preview {
    TmpView()
}
