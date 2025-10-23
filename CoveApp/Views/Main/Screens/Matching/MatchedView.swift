//
//  MatchedView.swift
//  Cove
//
//  AI Matching System - Group Match Card
//

import SwiftUI

struct MatchedView: View {
    let match: Match
    @State private var isConnecting = false
    @EnvironmentObject var appController: AppController
    
    // Get group size from match
    private var groupSize: Int {
        return match.groupSize ?? 2
    }
    
    // Calculate "you & X others"
    private var othersCount: Int {
        return groupSize - 1
    }
    
    var body: some View {
        ZStack {
            // Background
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Cove logo at top
                Text("cove")
                    .font(.LibreBodoniSemiBold(size: 48))
                    .foregroundColor(Colors.primaryDark)
                    .padding(.top, 60)
                
                Spacer()
                
                // Main group card
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Colors.primaryDark)
                        .overlay(
                            VStack(alignment: .leading, spacing: 24) {
                                // Globe icon with sparkles
                                HStack {
                                    Spacer()
                                    Image("matchIcon")
                                        .font(.system(size: 60, weight: .light))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.top, 8)
                                
                                // Match title (derived from intention)
                                Text(matchTitle)
                                    .font(.LibreBodoniSemiBold(size: 32))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                
                                // "group card" label with divider
                                HStack(spacing: 12) {
                                    Text("group card")
                                        .font(.LibreBodoniItalic(size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(height: 1)
                                }
                                
                                // Description text
                                Text(matchDescription)
                                    .font(Fonts.libreBodoni(size: 18))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(6)
                                
                                // Group info: "you & 6 others"
                                HStack(spacing: 12) {
                                    Image(systemName: "face.smiling")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                    
                                    Text("you & \(othersCount) other\(othersCount == 1 ? "" : "s")")
                                        .font(.LibreBodoniItalic(size: 18))
                                        .foregroundColor(.white)
                                }
                                .padding(.top, 8)
                                
                                // Connect me button
                                HStack {
                                    Spacer()
                                    
                                    Button(action: {
                                        isConnecting = true
                                        // Handle connect action
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            isConnecting = false
                                            Log.debug("user initiated connection!")
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Text("connect me")
                                                .font(.LibreBodoniSemiBold(size: 18))
                                                .foregroundColor(Colors.primaryDark)
                                            
                                            if isConnecting {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                    .foregroundColor(Colors.primaryDark)
                                            }
                                        }
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 14)
                                        .background(Color.white)
                                        .cornerRadius(25)
                                    }
                                    .disabled(isConnecting)
                                    
                                    Spacer()
                                }
                                .padding(.top, 16)
                            }
                            .padding(32)
                        )
                }
                .frame(maxWidth: 400)
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Computed Properties
    
    private var matchTitle: String {
        // Parse the intention to get the activity/vibe
        // For now, use a default title
        return "your match"
    }
    
    private var matchDescription: String {
        // Generic placeholder for now - will be AI-generated in the future
        return "you look so good together! now dont be shy... make it happen!"
    }
}

#Preview {
    MatchedView(match: Match(
        id: "preview",
        matchedUserId: "user123",
        score: 0.85,
        tierUsed: 0,
        matchedOn: ["interests", "vibe"],
        relaxedConstraints: [],
        createdAt: "2025-10-23T00:00:00Z",
        expiresAt: "2025-10-30T00:00:00Z",
        groupSize: 7,
        user: Match.MatchedUser(
            name: "alex",
            age: 25,
            almaMater: "stanford",
            bio: "love house music and dancing",
            gender: "non-binary",
            profilePhotoUrl: nil
        )
    ))
}
