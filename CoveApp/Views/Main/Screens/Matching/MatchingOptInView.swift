//
//  MatchingOptInView.swift
//  Cove
//
//  Opt-in screen before survey - explains the matching system
//

import SwiftUI

struct MatchingOptInView: View {
    let onNext: () -> Void
    
    var body: some View {
        ZStack {
            // Beige background
            Color(red: 0.96, green: 0.95, blue: 0.93)
                .ignoresSafeArea()
            
            // Full-screen card with small edge padding
            RoundedRectangle(cornerRadius: 32)
                .fill(Colors.primaryDark)
                .overlay(
                    VStack(spacing: 0) {
                        // Cove logo at top of card
                        Text("cove")
                            .font(.LibreBodoniSemiBold(size: 56))
                            .foregroundColor(.white)
                            .padding(.top, 80)
                        
                        Spacer()
                        
                        // Main message
                        Text("we match you based on who you really are—not what an algorithm thinks you want.")
                            .font(Fonts.libreBodoni(size: 20))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // Supporting message
                        Text("answer questions that resonate. the more questions answered, the better we can connect you with people who genuinely vibe with your energy and lifestyle.")
                            .font(Fonts.libreBodoni(size: 18))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                        
                        // Next button
                        Button(action: onNext) {
                            Text("next")
                                .font(.LibreBodoniSemiBold(size: 22))
                                .foregroundColor(Colors.primaryDark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(red: 0.96, green: 0.95, blue: 0.93))
                                )
                        }
                        .padding(.horizontal, 60)
                        .padding(.bottom, 80)
                    }
                )
                .padding(.horizontal, 32)
                .padding(.vertical, 40)
        }
    }
}

#Preview {
    MatchingOptInView(onNext: {})
}
