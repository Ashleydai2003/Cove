//
//  WelcomeScreen.swift
//  Cove
//
//  Created by Sheng Moua on 4/21/25.
//

import SwiftUI

struct WelcomeScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Cove!")
                .foregroundColor(Colors.primary)
                .font(Fonts.libreBodoni(size: 28))

            Button("Get Started") {
                viewModel.path.append(.personality)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// example of how to preview UI without using simulator
struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen(viewModel: OnboardingViewModel())
    }
}
