//
//  PersonalizeProfile.swift
//  Cove
//
//  Created by Sheng Moua on 4/22/25.
//

import SwiftUI

struct PersonalizeProfile: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var bio: String = ""

    var body: some View {
        ZStack {
            Colors.bgColor
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                // Header text
                VStack(alignment: .leading, spacing: 0) {
                    Text("personalize your")
                        .foregroundColor(Colors.primaryDark)
                        .font(Fonts.libreBodoni(size: 34))
                    Text("profile")
                        .foregroundColor(Colors.primaryDark)
                        .font(Fonts.libreBodoni(size: 34))
                }

                // Subtitle text
                Text("add a profile pic and additional photos to show off your vibe")
                    .foregroundColor(.black)
                    .font(Fonts.leagueSpartan(size: 12))
                    .padding(.bottom, 20)

                // upload picture buttons
                VStack(alignment: .center, spacing: 20) {
                    Button(action: {
                        print("Upload profile picture tapped!")
                    }) {
                        ZStack {
                            Circle()
                                .fill(Colors.textInputBg)
                                .frame(width: 160, height: 160)
                                .overlay(Circle().stroke(Color.black, lineWidth: 0.5))
                            
                            Text("+")
                                .font(.system(size: 30))
                                .foregroundColor(.black)
                        }
                    }
                    HStack(spacing: 20) {
                        ForEach(0..<2) { index in
                            Button(action: {
                                print("Upload additional photo \(index + 1) tapped!")
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Colors.textInputBg)
                                        .frame(width: 150, height: 300)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.black, lineWidth: 0.5)
                                        )
                                    
                                    Text("+")
                                        .font(.system(size: 30))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                    .padding(.top, 30)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 40)
            .padding(.top)

            // Smiley Button (Bottom Right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.path.append(.mutuals)
                    }) {
                        Image("smiley")
                            .resizable()
                            .frame(width: 50, height: 50)
                    }
                    .padding(.trailing, 40)
                    .padding(.bottom, 10)
                }
            }
        }
    }
}

struct PersonalizeProfile_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PersonalizeProfile(viewModel: OnboardingViewModel())
        }
    }
}
