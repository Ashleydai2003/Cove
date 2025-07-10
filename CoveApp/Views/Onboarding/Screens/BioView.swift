//
//  BioView.swift
//  Cove
//
//  Created by Sheng Moua on 4/21/25.
//

import SwiftUI

struct BioView: View {
    @EnvironmentObject var appController: AppController
    @State private var bio: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                OnboardingBackgroundView()

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

                    // Content
                    VStack(alignment: .leading, spacing: 10) {
                        Text("but first, personality")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 35))
                        
                        HStack(alignment: .center, spacing: 4) {
                            Text("write a brief bio to introduce yourself to the neighborhood")
                                .foregroundStyle(.black)
                                .font(.LeagueSpartan(size: 12))

                            Image("smiley")
                                .resizable()
                                .frame(width: 10, height: 10)
                        }

                        TextEditor(text: $bio)
                            .scrollContentBackground(.hidden)
                            .frame(height: 150)
                            .padding(8)
                            .background(OnboardingBackgroundView())
                            .cornerRadius(10)
                            .font(.LeagueSpartan(size: 14))
                            .foregroundStyle(.primary)
                            .focused($isFocused)
                            .onChange(of: bio) { oldValue, newValue in
                                bio = newValue.lowercaseIfNotEmpty
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .padding(.top, 40)

                    Spacer()
                    
                    HStack {
                        Spacer()
                        Images.smily
                            .resizable()
                            .frame(width: 52, height: 52)
                            .padding(.init(top: 0, leading: 0, bottom: 20, trailing: 20))
                            .onTapGesture {
                                // MARK: - Store bio
                                Onboarding.storeBio(bio: bio)
                                appController.path.append(.profilePics)
                            }
                    }
                }
                .padding(.horizontal, 20)
                .safeAreaPadding()
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    BioView()
        .environmentObject(AppController.shared)
}

