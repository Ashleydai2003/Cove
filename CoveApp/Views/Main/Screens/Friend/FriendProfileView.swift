import SwiftUI
import Kingfisher

struct FriendProfileView: View {
    let userId: String
    let initialPhotoUrl: URL?
    @StateObject private var viewModel = FriendProfileModel()
    @Environment(\.dismiss) private var dismiss
    @State private var displayPhotoURL: URL?

    init(userId: String, initialPhotoUrl: URL? = nil) {
        self.userId = userId
        self.initialPhotoUrl = initialPhotoUrl
        _displayPhotoURL = State(initialValue: initialPhotoUrl)
    }

    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()

            if viewModel.isLoading || viewModel.profileData == nil {
                ProgressView().tint(Colors.primaryDark)
            } else if let profile = viewModel.profileData {

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // MARK: Header (back & chat)
                        HStack {
                            Button { dismiss() } label: { Images.backArrow }
                            Spacer()
                        }
                        .padding(.horizontal)

                        // MARK: Profile & Stats
                        HStack(alignment: .top, spacing: 20) {
                            // Profile image (120x120)
                            let photoURL = displayPhotoURL ?? profile.photos.first(where: { $0.isProfilePic })?.url
                            if let url = photoURL {
                                KFImage(url)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                Image("default_user_pfp")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(profile.name)
                                    .font(.LibreBodoniBold(size: 32))
                                    .foregroundColor(Colors.primaryDark)

                                // Location
                                if !viewModel.locationName.isEmpty {
                                    HStack(spacing: 6) {
                                        Image(systemName: "mappin.and.ellipse")
                                            .foregroundColor(Colors.k6F6F73)
                                        Text(viewModel.locationName)
                                            .font(.LeagueSpartan(size: 14))
                                            .foregroundColor(Colors.k6F6F73)
                                    }
                                }

                                // Bio
                                if let bio = profile.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(.LibreBodoni(size: 15))
                                        .foregroundColor(Colors.k6F6F73)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                // Stats strip
                                if let s = profile.stats {
                                    HStack(spacing: 24) {
                                        StatBlock(number: s.sharedFriendCount ?? 0, label: "mutuals")
                                        StatBlock(number: s.sharedCoveCount ?? 0,   label: "coves")
                                        StatBlock(number: s.sharedEventCount ?? 0, label: "events together")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // TODO: Mutual Events carousel can be inserted here when data is available

                        // MARK: Hobbies / Interests
                        if !profile.interests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("past times")
                                    .font(.LibreBodoni(size: 18))
                                    .foregroundColor(Colors.primaryDark)
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
                                    ForEach(profile.interests, id: \.self) { hobby in
                                        StaticHobbyPill(text: hobby, textColor: Colors.k6F6F73)
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
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(number)")
                .font(.LibreBodoniBold(size: 20))
                .foregroundColor(.black)
            Text(label)
                .font(.LibreBodoni(size: 14))
                .foregroundColor(Colors.k6F6F73)
        }
    }
}
