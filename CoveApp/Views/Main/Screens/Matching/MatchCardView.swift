//
//  MatchCardView.swift
//  Cove
//
//  Match card view - shown when a match is found
//

import SwiftUI
import Kingfisher

struct MatchCardView: View {
    @ObservedObject var model: MatchModel
    @ObservedObject var intentionModel: IntentionModel
    @State private var showingThreadView = false
    @State private var threadId: String?
    @State private var showingError = false
    
    private var match: Match? {
        model.currentMatch
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Celebration header
                VStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                    
                    Text("🎉 We found your match!")
                        .font(.LibreBodoniSemiBold(size: 24))
                        .foregroundColor(Colors.primaryDark)
                }
                .padding(.top, 40)
                
                // Profile card
                if let match = match {
                    VStack(spacing: 16) {
                        // Photo
                        if let photoUrl = match.user.profilePhotoUrl, !photoUrl.isEmpty {
                            KFImage(URL(string: photoUrl))
                                .placeholder {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 200, height: 200)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 60))
                                                .foregroundColor(.gray)
                                        )
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 200, height: 200)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        // Name + basics
                        VStack(spacing: 4) {
                            Text(match.user.name ?? "your match")
                                .font(.LibreBodoniSemiBold(size: 28))
                                .foregroundColor(Colors.primaryDark)
                            
                            if let age = match.user.age, let almaMater = match.user.almaMater {
                                Text("\(age) • \(almaMater)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Bio
                        if let bio = match.user.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    
                    // Compatibility score
                    VStack(spacing: 8) {
                        HStack {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(match.score * 5) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                        }
                        Text("\(Int(match.score * 100))% compatible")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    // Matched on
                    VStack(alignment: .leading, spacing: 12) {
                        Text("you matched on:")
                            .font(.LibreBodoniSemiBold(size: 18))
                            .foregroundColor(Colors.primaryDark)
                        
                        ForEach(match.matchedOn, id: \.self) { reason in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(reason)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Relaxed constraints (if any)
                    if !match.relaxedConstraints.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("we relaxed:")
                                .font(.LibreBodoniSemiBold(size: 18))
                                .foregroundColor(Colors.primaryDark)
                            
                            ForEach(match.relaxedConstraints, id: \.self) { constraint in
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.orange)
                                    Text(constraint)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                // Actions
                HStack(spacing: 16) {
                    Button(action: declineMatch) {
                        HStack {
                            if model.isLoading {
                                ProgressView()
                                    .tint(Colors.primaryDark)
                            } else {
                                Image(systemName: "xmark")
                                Text("pass")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Colors.primaryDark)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(model.isLoading)
                    
                    Button(action: acceptMatch) {
                        HStack {
                            if model.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "heart.fill")
                                Text("start chatting")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Colors.primaryDark)
                        .cornerRadius(12)
                    }
                    .disabled(model.isLoading)
                }
            }
            .padding()
        }
        .alert("error", isPresented: $showingError) {
            Button("ok") {}
        } message: {
            Text(model.errorMessage ?? "an error occurred")
        }
    }
    
    private func acceptMatch() {
        model.acceptMatch { threadId in
            if let threadId = threadId {
                self.threadId = threadId
                
                // TODO: Navigate to messaging thread
                // For now, just show a success message
                Log.debug("match accepted! thread id: \(threadId)")
                
                // Refresh intention model to clear the matched intention
                intentionModel.refresh()
            } else {
                showingError = true
            }
        }
    }
    
    private func declineMatch() {
        model.declineMatch { success in
            if success {
                // Refresh intention model to stay in pool
                intentionModel.refresh()
            } else {
                showingError = true
            }
        }
    }
}

#Preview {
    MatchCardView(model: MatchModel(), intentionModel: IntentionModel())
}

