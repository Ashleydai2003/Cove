import SwiftUI
import Kingfisher

struct FriendProfileView: View {
    let userId: String
    let initialPhotoUrl: URL?
    @StateObject private var viewModel = FriendProfileModel()
    @Environment(\.dismiss) private var dismiss
    @State private var displayPhotoURL: URL?
    @State private var showDetails = false

    init(userId: String, initialPhotoUrl: URL? = nil) {
        self.userId = userId
        self.initialPhotoUrl = initialPhotoUrl
        _displayPhotoURL = State(initialValue: initialPhotoUrl)
    }

    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()

            if viewModel.isLoading || viewModel.profileData == nil {
                ProgressView().tint(Colors.primaryDark)
            } else if let profile = viewModel.profileData {

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // MARK: Header (back)
                        HStack {
                            Button { dismiss() } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Colors.primaryDark)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)

                        // MARK: Profile & Stats (match ProfileView layout)
                        HStack { Spacer()
                            let photoURL = displayPhotoURL ?? profile.photos.first(where: { $0.isProfilePic })?.url
                            if let url = photoURL {
                                KFImage(url)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 170, height: 170)
                                    .clipShape(Circle())
                            } else {
                                Image("default_user_pfp")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 170, height: 170)
                                    .clipShape(Circle())
                            }
                        Spacer() }

                        VStack(alignment: .center, spacing: 8) {
                            Text(profile.name)
                                .font(.LibreBodoniBold(size: 32))
                                .foregroundColor(Colors.primaryDark)
                                .frame(maxWidth: .infinity, alignment: .center)

                            // Location under name removed to match ProfileView; location will appear in combined row below

                            if let bio = profile.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.LibreBodoni(size: 16))
                                    .foregroundColor(Colors.k6F6F73)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .padding(.horizontal)

                        // Combined row: Age, Location, Alma Mater with carrot (placeholders where needed)
                        HStack(spacing: 16) {
                            // Age (placeholder)
                            Text("23")
                                .font(.LibreBodoni(size: 18))
                                .foregroundColor(Colors.primaryDark)

                            // Location (if available)
                            Group {
                                HStack(spacing: 6) {
                                    Image("locationIcon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(Colors.primaryDark)
                                    Text(viewModel.locationName.isEmpty ? "" : viewModel.locationName.lowercased())
                                        .font(.LibreBodoni(size: 14))
                                        .foregroundColor(Colors.primaryDark)
                                }
                            }

                            // Alma mater + carrot
                            HStack(spacing: 10) {
                                Image("gradIcon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                                    .foregroundStyle(Colors.k6B6B6B)
                                Text("stanford")
                                    .font(.LibreBodoni(size: 14))
                                    .foregroundColor(Colors.primaryDark)
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showDetails.toggle()
                                    }
                                }) {
                                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Colors.primaryDark)
                                        .frame(width: 16, height: 16)
                                        .contentShape(Rectangle())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 24)

                        // Collapsible details row (status + work) with placeholders
                        if showDetails {
                            HStack(spacing: 16) {
                                // Relationship Status
                                HStack(spacing: 6) {
                                    Image("relationshipIcon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 16, height: 16)
                                    Text("single")
                                        .font(.LibreBodoni(size: 14))
                                        .foregroundColor(Colors.primaryDark)
                                }

                                // Work (job @ location)
                                HStack(spacing: 6) {
                                    Image("workIcon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 16, height: 16)
                                        .foregroundStyle(Colors.k6B6B6B)
                                    Text("swe @ google")
                                        .font(.LibreBodoni(size: 15))
                                        .foregroundColor(Colors.primaryDark)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Stats strip (centered)
                        if let s = profile.stats {
                            HStack(spacing: 24) {
                                StatBlock(number: s.sharedFriendCount ?? 0, topLabel: "mutual", bottomLabel: "friends")
                                StatBlock(number: s.sharedCoveCount ?? 0,   topLabel: "shared", bottomLabel: "coves")
                                StatBlock(number: s.sharedEventCount ?? 0, topLabel: "shared", bottomLabel: "events")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                        }

                        // Removed extra photo for now (show only profile picture at top)

                        // MARK: Hobbies / Interests
                        if !profile.interests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("interests")
                                    .font(.LibreBodoni(size: 18))
                                    .foregroundColor(Colors.primaryDark)
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
                                    ForEach(profile.interests, id: \.self) { hobby in
                                        StaticHobbyPill(
                                            text: hobby, 
                                            emoji: HobbiesData.getEmoji(for: hobby),
                                            textColor: Colors.k6F6F73
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 12)
                        }

                        HStack {
                            Spacer()
                            headerActionButton
                            Spacer()
                        }
                        .padding(.horizontal)

                    }
                    .padding(.vertical, 20)
                }

            } else if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.red)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { viewModel.fetchProfile(userId: userId) }
    }

    private var headerActionButton: some View {
        switch viewModel.actionState {
        case .loading, .none:
            AnyView(EmptyView())
        case .message:
            AnyView(ActionButton.message { /* TODO open chat */ })
        case .pending:
            AnyView(ActionButton.pending())
        case .sendRequest:
            AnyView(ActionButton.request {
                AppController.shared.mutualsViewModel.sendFriendRequest(to: userId)
            })
        case .incomingRequest(let req):
            AnyView(
                HStack(spacing: 12) {
                    ActionButton(title: "accept", width: 120, height: 44, backgroundColor: Colors.primaryDark, textColor: .white, font: .LibreBodoni(size: 16), cornerRadius: 22) {
                        AppController.shared.requestsViewModel.accept(req)
                    }
                    ActionButton(title: "decline", width: 120, height: 44, backgroundColor: Color.gray.opacity(0.3), textColor: Colors.primaryDark, font: .LibreBodoni(size: 16), cornerRadius: 22) {
                        AppController.shared.requestsViewModel.reject(req)
                    }
                }
            )
        }
    }
}

private struct StatChip: View {
    let label: String
    let count: Int
    var body: some View {
        HStack(spacing: 6) {
            Text("\(count)")
            Text(label)
        }
        .font(.LibreBodoni(size: 12))
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Colors.primaryDark.opacity(0.1))
        )
        .foregroundColor(Colors.primaryDark)
    }
}

#Preview {
    FriendProfileView(userId: "demo")
}

// MARK: - Helper Sub-views

private struct StatBlock: View {
    let number: Int
    let topLabel: String
    let bottomLabel: String
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text("\(number)")
                .font(.LibreBodoniSemiBold(size: 18))
                .foregroundColor(Colors.primaryDark)
            VStack(spacing: 0) {
                Text(topLabel)
                Text(bottomLabel)
            }
            .font(.LibreBodoni(size: 13))
            .foregroundColor(Colors.k6F6F73)
            .multilineTextAlignment(.center)
        }
    }
}
