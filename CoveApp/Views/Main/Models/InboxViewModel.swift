import Foundation
import Combine
import SwiftUI
import UIKit // For haptic feedback

@MainActor
class InboxViewModel: ObservableObject {
    @Published var invites: [InviteModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Computed property to get only unopened invites
    var unopenedInvites: [InviteModel] {
        return invites.filter { !$0.isOpened }
    }

    /// Whether there are unopened invites that should trigger showing the inbox
    var hasUnopenedInvites: Bool {
        return !unopenedInvites.isEmpty
    }

    /// Initializes the inbox model - called on login/after onboarding
    func initialize() {
        fetchInvites()
    }

    /// Fetches pending invites for the current user
    func fetchInvites() {
        isLoading = true
        errorMessage = nil

        NetworkManager.shared.get(
            endpoint: "/invites",
            parameters: nil
        ) { [weak self] (result: Result<InboxResponse, NetworkError>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let response):
                    self.invites = response.invites

                    // Prefetch cover photos for already-opened invites
                    let coverUrls = response.invites.compactMap { $0.cove.coverPhotoUrl }
                    ImagePrefetcherUtil.prefetch(urlStrings: coverUrls)

                    // Notify AppController to check for auto-show
                    AppController.shared.checkForAutoShowInbox()

                case .failure(let error):
                    Log.error("Failed to fetch invites: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load invites: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Loads invites - convenience method for InboxView
    func loadInvites() {
        fetchInvites()
    }

    /// Opens an invite by marking it as opened on the server (only for unopened invites)
    func openInvite(_ invite: InviteModel) {
        Log.debug("openInvite called for invite: \(invite.id)")

        guard !invite.isOpened else {
            Log.debug("Invite \(invite.id) already opened – no-op")
            return
        }

        // Optimistically mark as opened and replace the whole array (new reference)
        if let idx = invites.firstIndex(where: { $0.id == invite.id }) {
            let updated = InviteModel(
                id: invite.id,
                message: invite.message,
                isOpened: true,
                createdAt: invite.createdAt,
                cove: invite.cove,
                sentBy: invite.sentBy
            )
            var newInvites = invites
            newInvites[idx] = updated
            withAnimation {
                invites = newInvites      // animated UI refresh
            }
        }

        // Call API in background
        NetworkManager.shared.put(
            endpoint: "/open-invite",
            parameters: ["inviteId": invite.id]
        ) { [weak self] (result: Result<OpenInviteResponse, NetworkError>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if let urlStr = response.invite.cove.coverPhotoUrl {
                        ImagePrefetcherUtil.prefetch(urlStrings: [urlStr]) { [weak self] in
                            guard let self = self else { return }
                            if let i = self.invites.firstIndex(where: { $0.id == invite.id }) {
                                var arr = self.invites
                                arr[i] = response.invite
                                withAnimation { self.invites = arr }
                            }
                        }
                    } else {
                        if let i = self.invites.firstIndex(where: { $0.id == invite.id }) {
                            var arr = self.invites
                            arr[i] = response.invite
                            withAnimation { self.invites = arr }
                        }
                    }
                case .failure(let error):
                    Log.error("openInvite failed: \(error.localizedDescription)")
                    // Revert optimistic update
                    if let i = self.invites.firstIndex(where: { $0.id == invite.id }) {
                        var reverted = self.invites
                        reverted[i] = invite
                        withAnimation {
                            self.invites = reverted
                        }
                    }
                    self.errorMessage = "Failed to open invite: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Accepts an invite and joins the cove
    func acceptInvite(_ invite: InviteModel) {
        Log.debug("Accept invite \(invite.id)")
        let impact = UIImpactFeedbackGenerator(style: .medium); impact.impactOccurred()

        // Remove optimistically by reassigning a NEW array
        withAnimation {
            invites = invites.filter { $0.id != invite.id }
        }

        NetworkManager.shared.post(
            endpoint: "/join-cove",
            parameters: ["coveId": invite.cove.id]
        ) { [weak self] (result: Result<JoinCoveResponse, NetworkError>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    Log.debug("✅ Successfully joined cove \(invite.cove.id), refreshing all feeds...")
                    // Refresh all feeds to show the newly joined cove and its events
                    self.refreshAllFeeds()
                case .failure(let error):
                    // Re-add on failure (new reference again)
                    var arr = self.invites
                    arr.append(invite)
                    withAnimation {
                        self.invites = arr
                    }
                    self.errorMessage = "Failed to join cove: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Refreshes all feeds after joining a new cove
    private func refreshAllFeeds() {
        Log.debug("Refreshing feeds after joining cove…")

        // Refresh CoveFeed (user's coves list)
        AppController.shared.coveFeed.refreshUserCoves()

        // Refresh CalendarFeed (user's committed events)
        AppController.shared.calendarFeed.refreshCalendarEvents()

        // Refresh UpcomingFeed (upcoming events from all coves)
        AppController.shared.upcomingFeed.refreshUpcomingEvents()
    }

    /// Declines an invite
    func declineInvite(_ invite: InviteModel) {
        Log.debug("Decline invite \(invite.id)")
        let impact = UIImpactFeedbackGenerator(style: .light); impact.impactOccurred()

        withAnimation {
            invites = invites.filter { $0.id != invite.id }
        }

        NetworkManager.shared.delete(
            endpoint: "/reject-invite",
            parameters: ["inviteId": invite.id]
        ) { [weak self] (result: Result<RejectInviteResponse, NetworkError>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    ()
                case .failure(let error):
                    var arr = self.invites
                    arr.append(invite)
                    withAnimation {
                        self.invites = arr
                    }
                    self.errorMessage = "Failed to reject invite: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Clears all data when user logs out
    func clear() {
        invites = []
        isLoading = false
        errorMessage = nil
    }
}

// MARK: - Response Models

/// Response from /invites API
struct InboxResponse: Decodable {
    let invites: [InviteModel]
}

/// Response from /open-invite API
struct OpenInviteResponse: Decodable {
    let message: String
    let invite: InviteModel
}

/// Response from /join-cove API
struct JoinCoveResponse: Decodable {
    let message: String
    let member: JoinedMember

    struct JoinedMember: Decodable {
        let id: String
        let coveId: String
        let userId: String
        let role: String
        let joinedAt: String
    }
}

/// Response from /reject-invite API
struct RejectInviteResponse: Decodable {
    let message: String
}

/// Individual invite model
struct InviteModel: Decodable, Identifiable {
    let id: String
    let message: String?
    let isOpened: Bool
    let createdAt: String
    let cove: InviteCove
    let sentBy: InviteSender

    // Computed property for backward compatibility
    var sender: InviteSender {
        return sentBy
    }

    struct InviteCove: Decodable {
        let id: String
        let name: String
        let description: String?
        let location: String
        let coverPhotoId: String?
        let coverPhotoUrl: String?
    }

    struct InviteSender: Decodable {
        let id: String
        let name: String?
        let profilePhotoId: String?
    }
}
