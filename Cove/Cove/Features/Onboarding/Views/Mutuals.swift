//
//  Mutuals.swift
//  Cove
//
//  Created by Sheng Moua on 4/22/25.
//

import SwiftUI

struct Mutuals: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var bio: String = ""

    var body: some View {
        ZStack {
            Colors.bgColor
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                // Title
                Text("add friends")
                    .foregroundColor(Colors.primaryDark)
                    .font(Fonts.libreBodoni(size: 35))
                
                // Description
                VStack(alignment: .leading, spacing: 10) {
                    Text("cove is a secure, curated network. let us help you find your friends of friends.")
                        .foregroundColor(.black)
                        .font(Fonts.leagueSpartan(size: 12))
                    
                    Text("we never share phone numbers.")
                        .foregroundColor(.black)
                        .font(Fonts.leagueSpartan(size: 12))
                    
                    Text("add at least 5 friends. the more genuine friends you add, the better cove will work for you. we ONLY see the contacts you choose.")
                        .foregroundColor(.black)
                        .font(Fonts.leagueSpartan(size: 12))
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 40)
            .padding(.top)

            VStack {
                Spacer()

                Button(action: {
                    print("Choose friends tapped")
                }) {
                    Text("choose friends from contacts")
                        .font(Fonts.libreBodoni(size: 16))
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct Mutuals_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Mutuals(viewModel: OnboardingViewModel())
        }
    }
}
