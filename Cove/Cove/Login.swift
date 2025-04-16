//
//  ContentView.swift
//  Cove
//
//  Created by Ashley Dai on 4/14/25.
//

import SwiftUI

struct Login: View {
    var body: some View {
        ZStack {
            // For background
            Image("login_background")
                .resizable()
                .scaledToFill()
                .scaledToFill()
                .overlay(Color.white.opacity(0.4))
                .frame(minWidth: 0, maxWidth: .infinity)
                .ignoresSafeArea()
                
            
            VStack {
                Text("cove")
                    // to offset build in padding of custom font
                    .frame(height: 70)
                    .clipped()
                    .font(.LibreBodoni(size: 100))
                    .foregroundColor(Color(hex: "#8E413A"))
                    .padding(.top, 70.0)
                Text("plug back into community.")
                    .font(.LibreBodoni(size: 18))
                
                // to create space in middle
                Spacer()
                
                SignOnButton(text: "let's go")
                     
                Text("By signing up you agree to our Terms and Conditions. See how we use your data in our Privacy Policy.")
                    .multilineTextAlignment(.center)
                    .padding()
                    .padding(.horizontal)
                    .font(.LeagueSpartan(size:15)
                    )
            }
        }
    }
}

struct SignOnButton: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.LibreBodoni(size: 25))
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .padding()
            .background(Color(.white))
            .cornerRadius(16.99)
            .padding(.horizontal)
    }
}

#Preview {
    Login()
}
