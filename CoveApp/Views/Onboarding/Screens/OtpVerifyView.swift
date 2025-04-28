//
//  OtpVerifyView.swift
//  Cove
//

import SwiftUI

struct OtpVerifyView: View {
    
    @EnvironmentObject var appController: AppController
    
    @State private var otp: [String] = Array(repeating: "", count: 5)
    @FocusState private var focusedIndex: Int?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                OnboardingBackgroundView(imageName: "otp_background")
                    .opacity(0.4)
                
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
                    
                    VStack(alignment: .leading) {
                        Text("enter your \nverification code")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 40))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 0) {
                            Text("sent to +1 (344) 343-3434 | ")
                                .foregroundStyle(Colors.k6F6F73)
                                .font(.LeagueSpartan(size: 15))
                            
                            Button {
                                appController.path.removeLast()
                            } label: {
                                Text("edit number")
                                    .foregroundStyle(Colors.k171719)
                                    .font(.LeagueSpartan(size: 15))
                            }
                        }
                    }
                    .padding(.top, 40)
                    
                    HStack(spacing: 10) {
                        ForEach(0..<otp.count, id: \.self) { index in
                            VStack {
                                TextField("", text: $otp[index])
                                    .keyboardType(.numberPad)
                                    .foregroundStyle(Color.black)
                                    .multilineTextAlignment(.center)
                                    .font(.LibreCaslon(size: 40))
                                    .focused($focusedIndex, equals: index)
                                    .onChange(of: otp[index]) { oldValue, newValue in
                                        if newValue.count > 1 {
                                            otp[index] = String(newValue.prefix(1))
                                        }
                                        if !newValue.isEmpty && index < 5 {
                                            focusedIndex = index + 1
                                        } else if newValue.isEmpty && index > 0 {
                                            focusedIndex = index - 1
                                        }
                                        
                                        let enteredAllCode = otp.allSatisfy { !$0.isEmpty }
                                        if enteredAllCode {
                                            appController.path.append(.userDetails)
                                        }
                                    }
                                
                                Divider()
                                    .frame(height: 2)
                                    .background(Color.black.opacity(0.58))
                            }
                            
                        }
                    }
                    .padding(.top, 50)
                    
                    HStack {
                        Spacer()
                        Button {
                            
                        } label: {
                            Text("resend code")
                                .foregroundStyle(Colors.k262627)
                                .font(.LeagueSpartan(size: 15))
                        }
                    }
                    .padding(.top, 5)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .safeAreaPadding()
            }
        }
        .navigationBarBackButtonHidden()
    }
    
}

#Preview {
    OtpVerifyView()
        .environmentObject(AppController.shared)
}
