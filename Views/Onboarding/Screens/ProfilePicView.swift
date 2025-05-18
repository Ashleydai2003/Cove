//
//  PersonalizeProfile.swift
//  Cove
//
//  Created by Sheng Moua on 4/22/25.
//

import SwiftUI

struct ProfilePicView: View {
    @EnvironmentObject var appController: AppController
    @State private var bio: String = ""

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Colors.faf8f4
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Button {
                            appController.path.removeLast()
                        } label: {
                            Images.backArrow
                        }
                        Spacer()
                    }
                    .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("personalize your")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 34))
                        Text("profile")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 34))
                    }

                    Text("add a profile pic and additional photos to show off your vibe")
                        .foregroundStyle(.black)
                        .font(.LeagueSpartan(size: 12))
                        .padding(.bottom, 30)

                    // Upload Buttons
                    VStack(alignment: .center, spacing: 20) {
                        Button(action: {
                            print("TODO")
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Colors.f3f3f3)
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
                                    print("TODO")
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Colors.f3f3f3)
                                            .frame(width: 150, height: 250)
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
                        .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer()

                    HStack {
                        Spacer()
                        Images.smily
                            .resizable()
                            .frame(width: 52, height: 52)
                            .padding(.init(top: 0, leading: 0, bottom: 0, trailing: 20))
                            .onTapGesture {
                                appController.path.append(.mutuals)
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
    ProfilePicView()
        .environmentObject(AppController.shared)
}
