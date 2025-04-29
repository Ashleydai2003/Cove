//
//  HobbiesPersonality.swift
//  Cove
//
//  Created by Sheng Moua on 4/21/25.
//

import SwiftUI

struct HobbiesPersonality: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var bio: String = ""

    var body: some View {
        ZStack {
            Colors.bgColor
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                Text("but first, personality")
                    .foregroundColor(Colors.primaryDark)
                    .font(Fonts.libreBodoni(size: 35))
                
                HStack(alignment: .center, spacing: 4) {
                    Text("write a brief bio to introduce yourself to the neighborhood")
                        .foregroundColor(.black)
                        .font(Fonts.leagueSpartan(size: 12))

                    Image("smiley")
                        .resizable()
                        .frame(width: 10, height: 10)
                }

                TextEditor(text: $bio)
                    .scrollContentBackground(.hidden)
                    .frame(height: 150)
                    .padding(8)
                    .background(Colors.textInputBg)
                    .cornerRadius(10)
                    .font(Fonts.leagueSpartan(size: 14))
                    .foregroundColor(.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.5), lineWidth: 1)
                    )

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 40)
            .padding(.top)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.path.append(.profilePic)
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

struct HobbiesPersonality_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HobbiesPersonality(viewModel: OnboardingViewModel())
        }
    }
}

