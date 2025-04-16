//
//  NamePage.swift
//  Cove
//
//  Created by Ashley Dai on 4/15/25.
//

import SwiftUI

struct NamePage: View {
    // private vars for users' names
    @State private var firstName: String = ""
    @State private var lastName: String = ""

    var body: some View {
        ZStack() {
            // backgroun image
            Image("name_background")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity)
                .overlay(Color.white.opacity(0.6))
                .ignoresSafeArea()
            // main content container view
            VStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("what's your name?")
                            .font(.LibreBodoni(size: 40))
                            .foregroundColor(Color(hex: "#5E1C1D"))
                            .frame(width: UIScreen.main.bounds.width / 1.5, alignment: .leading)
                        Spacer()
                    }
                    Text("only your first name will be displayed.")
                        .font(.LeagueSpartan(size: 15))
                        .foregroundColor(Color(hex: "#6F6F73"))
                }
                
                // input boxes for name
                // TODO: Change font
                VStack {
                    TextField("first name", text: $firstName)
                        .font(.LibreCaslon(size: 25))
                    
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(.black)
                    
                    TextField("last name", text: $lastName)
                        .font(.LibreCaslon(size: 25))
                        .padding(.top)
                    
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(.black)
                }
                    .padding(.top, 40)
                    .padding(.horizontal, 15)
                
                // empty space
                Spacer()
            }
            .padding()
            .padding(.horizontal, 20)
        }
    }
}


#Preview {
    NamePage()
}
