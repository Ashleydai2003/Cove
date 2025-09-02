//
//  EventPostView.swift
//  Cove
//
//  Created by Ananya Agarwal
import SwiftUI
import Kingfisher
import FirebaseAuth

// MARK: - View Model
// TODO: insn't this the same as what is being down in feed?
class EventPostViewModel: ObservableObject {
    @Published var event: Event?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isDeleting = false
    @Published var isUpdatingRSVP = false

    func fetchEventDetails(eventId: String, completion: (() -> Void)? = nil) {
        isLoading = true

        NetworkManager.shared.get(endpoint: "/event", parameters: ["eventId": eventId]) { [weak self] (result: Result<EventResponse, NetworkError>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let response):
                    Log.debug("🔵 fetchEventDetails - Backend returned rsvpStatus: \(response.event.rsvpStatus ?? "nil")")
                    self.event = response.event
                    completion?()
                case .failure(let error):
                    Log.debug("🔵 fetchEventDetails Error: \(error)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func updateRSVP(eventId: String, status: String, completion: @escaping (Bool) -> Void) {
        isUpdatingRSVP = true
        Log.debug("🔵 updateRSVP called with status: \(status)")

        // Use delete endpoint for NOT_GOING status
        let endpoint = status == "NOT_GOING" ? "/remove-event-rsvp" : "/update-event-rsvp"
        let parameters: [String: Any] = status == "NOT_GOING" ? ["eventId": eventId] : ["eventId": eventId, "status": status]

        // Use generic response type that can handle both cases
        NetworkManager.shared.post(endpoint: endpoint, parameters: parameters) { [weak self] (result: Result<GenericRSVPResponse, NetworkError>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isUpdatingRSVP = false

                switch result {
                case .success(let response):
                    Log.debug("🔵 Backend RSVP Response: \(response)")
                    
                    if status == "NOT_GOING" {
                        Log.debug("🔵 RSVP removed successfully: \(response.message)")
                        // Update local state immediately for better UX
                        self.updateLocalRSVPStatus(status: "NOT_GOING")
                    } else {
                        if let rsvpData = response.rsvp {
                            Log.debug("🔵 Backend returned status: \(rsvpData.status)")
                        } else {
                            Log.debug("🔵 No RSVP data in response")
                        }
                    }
                    
                    completion(true)
                case .failure(let error):
                    Log.debug("🔵 RSVP Error: \(error)")
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }

    func deleteEvent(eventId: String, completion: @escaping (Bool) -> Void) {
        isDeleting = true

        NetworkManager.shared.post(endpoint: "/delete-event", parameters: ["eventId": eventId]) { [weak self] (result: Result<DeleteEventResponse, NetworkError>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isDeleting = false

                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }

    /// Updates the local event state to reflect RSVP changes without fetching from server
    func updateLocalRSVPStatus(status: String) {
        guard let currentEvent = event else { return }

        // Update the current user's RSVP status in the local event
        if let currentUserId = Auth.auth().currentUser?.uid {
            // Create a new RSVPs array with the updated status
            var updatedRsvps: [EventRSVP] = currentEvent.rsvps ?? []

            // Find and update existing RSVP or add new one
            if let index = updatedRsvps.firstIndex(where: { $0.userId == currentUserId }) {
                if status == "NOT_GOING" {
                    // Remove RSVP entirely for NOT_GOING
                    updatedRsvps.remove(at: index)
                } else {
                    // Create a new RSVP with updated status
                    let updatedRSVP = EventRSVP(
                        id: updatedRsvps[index].id,
                        status: status,
                        userId: currentUserId,
                        userName: updatedRsvps[index].userName,
                        profilePhotoUrl: updatedRsvps[index].profilePhotoUrl,
                        createdAt: updatedRsvps[index].createdAt
                    )
                    updatedRsvps[index] = updatedRSVP
                }
            } else {
                if status != "NOT_GOING" {
                    // Add new RSVP for current user
                    let newRSVP = EventRSVP(
                        id: UUID().uuidString, // Temporary ID
                        status: status,
                        userId: currentUserId,
                        userName: "You", // Placeholder name
                        profilePhotoUrl: nil,
                        createdAt: ISO8601DateFormatter().string(from: Date())
                    )
                    updatedRsvps.append(newRSVP)
                }
            }

            // Create a new Event instance with updated RSVPs
            let updatedEvent = Event(
                id: currentEvent.id,
                name: currentEvent.name,
                description: currentEvent.description,
                date: currentEvent.date,
                location: currentEvent.location,
                memberCap: currentEvent.memberCap,
                ticketPrice: currentEvent.ticketPrice,
                paymentHandle: currentEvent.paymentHandle,
                coveId: currentEvent.coveId,
                host: currentEvent.host,
                cove: currentEvent.cove,
                rsvpStatus: status == "NOT_GOING" ? nil : status,
                goingCount: currentEvent.goingCount,
                pendingCount: currentEvent.pendingCount,
                rsvps: updatedRsvps,
                coverPhoto: currentEvent.coverPhoto,
                isHost: currentEvent.isHost
            )

            // Update the published event
            event = updatedEvent
        }
    }
    
    // MARK: - New Event Member Management Methods
    
    @Published var eventMembers: [EventMember] = []
    @Published var pendingMembers: [PendingMember] = []
    @Published var isLoadingMembers = false
    @Published var isLoadingPending = false
    @Published var hasMoreMembers = false
    @Published var hasMorePending = false
    @Published var membersCursor: String?
    @Published var pendingCursor: String?
    
    /// Fetch approved event members (GOING status)
    func fetchEventMembers(eventId: String, refresh: Bool = false, completion: (() -> Void)? = nil) {
        if refresh {
            eventMembers.removeAll()
            membersCursor = nil
            hasMoreMembers = false
        }
        
        guard !isLoadingMembers else { return }
        isLoadingMembers = true
        
        var parameters: [String: Any] = ["eventId": eventId]
        if let cursor = membersCursor {
            parameters["cursor"] = cursor
        }
        
        NetworkManager.shared.get(endpoint: "/event-members", parameters: parameters) { [weak self] (result: Result<EventMembersResponse, NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingMembers = false
                
                switch result {
                case .success(let response):
                    if refresh {
                        self.eventMembers = response.members
                    } else {
                        self.eventMembers.append(contentsOf: response.members)
                    }
                    self.hasMoreMembers = response.hasMore
                    self.membersCursor = response.nextCursor
                    completion?()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion?()
                }
            }
        }
    }
    
    /// Fetch pending event members (host only)
    func fetchPendingMembers(eventId: String, refresh: Bool = false, completion: (() -> Void)? = nil) {
        if refresh {
            pendingMembers.removeAll()
            pendingCursor = nil
            hasMorePending = false
        }
        
        guard !isLoadingPending else { return }
        isLoadingPending = true
        
        var parameters: [String: Any] = ["eventId": eventId]
        if let cursor = pendingCursor {
            parameters["cursor"] = cursor
        }
        
        NetworkManager.shared.get(endpoint: "/pending-members", parameters: parameters) { [weak self] (result: Result<PendingMembersResponse, NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingPending = false
                
                switch result {
                case .success(let response):
                    if refresh {
                        self.pendingMembers = response.pendingMembers
                    } else {
                        self.pendingMembers.append(contentsOf: response.pendingMembers)
                    }
                    self.hasMorePending = response.hasMore
                    self.pendingCursor = response.nextCursor
                    completion?()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion?()
                }
            }
        }
    }
    
    /// Approve or decline an RSVP (host only)
    func approveDeclineRSVP(rsvpId: String, action: String, completion: @escaping (Bool) -> Void) {
        NetworkManager.shared.post(endpoint: "/approve-decline-rsvp", parameters: ["rsvpId": rsvpId, "action": action]) { [weak self] (result: Result<ApproveDeclineResponse, NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Remove the member from pending list if declined, or refresh if approved
                    if action == "decline" {
                        self.pendingMembers.removeAll { $0.id == rsvpId }
                    }
                    completion(true)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
}

// Add EventResponse struct to match the API response
struct EventResponse: Decodable {
    let event: Event
}

struct DeleteEventResponse: Decodable {
    let message: String
}

struct UpdateRSVPResponse: Decodable {
    let message: String
    let rsvp: RSVPData

    struct RSVPData: Decodable {
        let id: String
        let status: String
        let eventId: String
        let userId: String
        let createdAt: String
    }
}

struct DeleteRSVPResponse: Decodable {
    let message: String
}

// Generic response type that can handle both update and delete responses
struct GenericRSVPResponse: Decodable {
    let message: String
    let rsvp: RSVPData?
    
    struct RSVPData: Decodable {
        let id: String
        let status: String
        let eventId: String
        let userId: String
        let createdAt: String
    }
}

// MARK: - Event Member Management Models

struct EventMember: Decodable, Identifiable {
    let id: String
    let userId: String
    let userName: String
    let profilePhotoUrl: URL?
    let joinedAt: String
}

struct PendingMember: Decodable, Identifiable {
    let id: String
    let userId: String
    let userName: String
    let profilePhotoUrl: URL?
    let requestedAt: String
}

struct EventMembersResponse: Decodable {
    let members: [EventMember]
    let hasMore: Bool
    let nextCursor: String?
}

struct PendingMembersResponse: Decodable {
    let pendingMembers: [PendingMember]
    let hasMore: Bool
    let nextCursor: String?
}

struct ApproveDeclineResponse: Decodable {
    let message: String
    let action: String
    let rsvpId: String
}

// MARK: - Main View
struct EventPostView: View {
    let eventId: String
    let coveCoverPhoto: CoverPhoto?
    @StateObject private var viewModel = EventPostViewModel()
    @EnvironmentObject var appController: AppController
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingGuestList = false
    @State private var showingTicketConfirmation = false
    @State private var showingShareSheet = false
    @State private var showSettingsMenu = false

    init(eventId: String, coveCoverPhoto: CoverPhoto? = nil) {
        self.eventId = eventId
        self.coveCoverPhoto = coveCoverPhoto
    }

    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            } else if let event = viewModel.event {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        TopIconBar(
                            showBackArrow: true,
                            showGear: true,
                            onBackTapped: { dismiss() },
                            onGearTapped: {
                                withAnimation(.easeInOut(duration: 0.18)) { showSettingsMenu.toggle() }
                            }
                        )
                    }

                    VStack(alignment: .leading, spacing: 24) {

                        Text(event.name.isEmpty ? "Untitled" : event.name)
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoniBold(size: 26))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)

                        if let urlString = event.coverPhoto?.url, let url = URL(string: urlString) {
                            KFImage(url)
                                .placeholder {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 192)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .onSuccess { result in
                                }
                                .resizable()
                                .fade(duration: 0.2)
                                .cacheOriginalImage()
                                .cancelOnDisappear(true)
                                .aspectRatio(contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .frame(height: 192)
                                .clipped()
                        } else {
                            // Default event image
                            Image("default_event2")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 192)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .clipped()
                        }

                        VStack(alignment: .leading, spacing: 20) {
                            // Date and Time
                            HStack {
                                Text(event.formattedDate)
                                    .foregroundStyle(Color.black)
                                    .font(.LibreBodoni(size: 18))
                                Spacer()
                                Text(event.formattedTime)
                                    .foregroundStyle(Colors.primaryDark)
                                    .font(.LibreBodoni(size: 18))
                            }

                            // Location
                            HStack {
                                Image("locationIcon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15, height: 20)

                                Text(event.location ?? "RSVP to see location")
                                    .foregroundStyle(Colors.primaryDark)
                                    .font(.LibreBodoniBold(size: 16))
                            }

                            // Host information
                            HStack {
                                Text("hosted by")
                                    .font(.LibreBodoni(size: 18))
                                    .foregroundColor(Color.black)
                                Text(event.host.name)
                                .font(.LibreBodoni(size: 18))
                                .foregroundColor(Colors.primaryDark)
                            }
                            
                            // Event details section (price, capacity, going count)
                            VStack(alignment: .leading, spacing: 12) {
                                // Ticket price display
                                if let ticketPrice = event.ticketPrice {
                                    HStack {
                                        Image(systemName: "dollarsign.circle")
                                            .foregroundColor(Colors.primaryDark)
                                            .font(.system(size: 16))
                                        Text("$\(String(format: "%.2f", ticketPrice))")
                                            .font(.LibreBodoni(size: 16))
                                            .foregroundColor(Colors.primaryDark)
                                    }
                                }
                                
                                // Payment handle display
                                if let paymentHandle = event.paymentHandle, !paymentHandle.isEmpty {
                                    HStack {
                                        Spacer()
                                            .frame(width: 24) // Indent to align with other content
                                        Text("venmo @\(paymentHandle)")
                                            .font(.LibreBodoni(size: 16))
                                            .foregroundColor(Colors.primaryDark)
                                        Spacer()
                                    }
                                }
                                
                                // Member cap and spots left display
                                if let memberCap = event.memberCap, let goingCount = event.goingCount {
                                    HStack {
                                        Image(systemName: "person.2")
                                            .foregroundColor(Colors.primaryDark)
                                            .font(.system(size: 16))
                                        let spotsLeft = max(0, memberCap - goingCount)
                                        Text("\(goingCount)/\(memberCap) going • \(spotsLeft) spots left")
                                            .font(.LibreBodoni(size: 16))
                                            .foregroundColor(Colors.primaryDark)
                                    }
                                } else if let goingCount = event.goingCount {
                                    HStack {
                                        Image(systemName: "person.2")
                                            .foregroundColor(Colors.primaryDark)
                                            .font(.system(size: 16))
                                        Text("\(goingCount) going")
                                            .font(.LibreBodoni(size: 16))
                                            .foregroundColor(Colors.primaryDark)
                                    }
                                }
                            }
                        }

                        if let description = event.description {
                            Text(description)
                                .foregroundStyle(Colors.k292929)
                                .font(.LibreBodoni(size: 18))
                                .multilineTextAlignment(.leading)
                                .padding(.top, 8)
                        }

                        // Subtle divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("guest list")
                                    .font(.LibreBodoni(size: 18))
                                    .foregroundColor(Colors.primaryDark)
                                
                                Spacer()
                                
                                // Show pending count for hosts
                                if event.isHost == true, let pendingCount = event.pendingCount, pendingCount > 0 {
                                    Text("\(pendingCount) pending")
                                        .font(.LibreBodoni(size: 14))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.orange.opacity(0.1))
                                        )
                                }
                            }

                            if let rsvps = event.rsvps {
                                // Filter RSVPs to only show "GOING" status
                                let goingRsvps = rsvps.filter { $0.status == "GOING" }

                                if goingRsvps.isEmpty {
                                    Text("no guests yet! send your invites!")
                                        .font(.LibreBodoni(size: 14))
                                        .foregroundColor(Colors.primaryDark)
                                        .padding(.leading, 4)
                                } else {
                                    Button(action: {
                                        showingGuestList = true
                                        // Load the full member list when opening
                                        viewModel.fetchEventMembers(eventId: eventId, refresh: true)
                                        // Load pending members if user is the host
                                        if event.isHost == true {
                                            viewModel.fetchPendingMembers(eventId: eventId, refresh: true)
                                        }
                                    }) {
                                        HStack(spacing: 12) {
                                            // Show up to 4 profile photos
                                            ForEach(Array(goingRsvps.prefix(4).enumerated()), id: \.element.id) { index, rsvp in
                                                if let profilePhotoUrl = rsvp.profilePhotoUrl {
                                                    KFImage(profilePhotoUrl)
                                                        .placeholder {
                                                            Circle()
                                                                .fill(Color.gray.opacity(0.2))
                                                                .frame(width: 62, height: 62)
                                                        }
                                                        .onFailure { error in
                                                            Log.debug("❌ Failed to load profile photo: \(error)")
                                                        }
                                                        .resizable()
                                                        .scaleFactor(UIScreen.main.scale)
                                                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 62 * UIScreen.main.scale, height: 62 * UIScreen.main.scale)))
                                                        .fade(duration: 0.2)
                                                        .cacheOriginalImage()
                                                        .cancelOnDisappear(true)
                                                        .scaledToFill()
                                                        .frame(width: 62, height: 62)
                                                        .clipShape(Circle())
                                                } else {
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.2))
                                                        .frame(width: 62, height: 62)
                                                        .overlay(
                                                            Image(systemName: "person.fill")
                                                                .foregroundColor(.gray)
                                                                .font(.system(size: 25))
                                                        )
                                                }
                                            }

                                            // Show "+X" if there are more than 4 people
                                            if goingRsvps.count > 4 {
                                                Text("+\(goingRsvps.count - 4)")
                                                    .foregroundStyle(Colors.primaryDark)
                                                    .font(.LibreBodoniBold(size: 10))
                                                    .padding(.all, 8)
                                                    .overlay {
                                                        Circle()
                                                            .stroke(Colors.primaryDark, lineWidth: 1.0)
                                                    }
                                            }
                                            
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            } else {
                                Text("RSVP to see guest list")
                                    .font(.LibreBodoni(size: 14))
                                    .foregroundColor(Colors.primaryDark)
                                    .padding(.leading, 4)
                            }
                        }
                        .padding(.top, 16)

                        // Single RSVP button with three states
                        Button {
                            let currentStatus = event.rsvpStatus
                            Log.debug("🔵 RSVP Button Clicked - Current Status: \(currentStatus ?? "nil")")
                            
                            if currentStatus == "GOING" {
                                // User is going, change to not going
                                Log.debug("🔵 Sending NOT_GOING to backend...")
                                viewModel.updateRSVP(eventId: eventId, status: "NOT_GOING") { success in
                                    Log.debug("🔵 NOT_GOING response - Success: \(success)")
                                    if success {
                                        // Update local state immediately
                                        viewModel.updateLocalRSVPStatus(status: "NOT_GOING")
                                        // Refresh event details to get updated status
                                        viewModel.fetchEventDetails(eventId: eventId)
                                    }
                                }
                            } else if currentStatus == "PENDING" {
                                // User is pending - do nothing (button is static)
                                Log.debug("🔵 PENDING button clicked - no action needed")
                                           } else {
                   // Check if this is a ticketed event and user is not the host
                   if event.ticketPrice != nil, event.isHost != true {
                       // Show ticket confirmation popup for non-hosts
                       showingTicketConfirmation = true
                   } else {
                                    // No ticket price or user is host, proceed with RSVP
                                    Log.debug("🔵 Sending PENDING to backend...")
                                    viewModel.updateRSVP(eventId: eventId, status: "PENDING") { success in
                                        Log.debug("🔵 PENDING response - Success: \(success)")
                                        if success {
                                            // Refresh event details to get updated status
                                            viewModel.fetchEventDetails(eventId: eventId)
                                        }
                                    }
                                }
                            }
                            } label: {
                            let currentStatus = event.rsvpStatus
                            let isGoing = currentStatus == "GOING"
                            let isPending = currentStatus == "PENDING"
                            
                            let buttonText = isGoing ? "can't make it..." : (isPending ? "pending approval..." : "rsvp")

                            Text(buttonText)
                                .foregroundStyle(isGoing ? Colors.primaryDark : (isPending ? .gray : .white))
                                .font(.LibreBodoni(size: 25))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                    .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(isGoing ? Color.white : (isPending ? Color.gray.opacity(0.3) : Colors.primaryDark))
                                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 8)
                                    )
                            }
                            .onAppear {
                                let currentStatus = event.rsvpStatus
                                let buttonText = currentStatus == "GOING" ? "can't make it..." : (currentStatus == "PENDING" ? "pending approval..." : "rsvp")
                                Log.debug("🔵 Button Text: \(buttonText) (Status: \(currentStatus ?? "nil"))")
                            }
                            .disabled(viewModel.isUpdatingRSVP || event.rsvpStatus == "PENDING")
                            .padding(.top, 24)

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Text(error)
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.fetchEventDetails(eventId: eventId)
        }
        .overlay(alignment: .topTrailing) {
            if showSettingsMenu {
                EventSettingsDropdownMenu(
                    isHost: viewModel.event?.isHost == true,
                    onShare: {
                        withAnimation(.easeInOut(duration: 0.18)) { showSettingsMenu = false }
                        showingShareSheet = true
                    },
                    onEdit: {
                        withAnimation(.easeInOut(duration: 0.18)) { showSettingsMenu = false }
                        // Edit not implemented yet
                    },
                    dismiss: {
                        withAnimation(.easeInOut(duration: 0.18)) { showSettingsMenu = false }
                    }
                )
                .frame(width: UIScreen.main.bounds.width * 0.65)
                .padding(.trailing, 8)
                .offset(y: 40)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .zIndex(100000)
            }
        }
        .navigationDestination(isPresented: $showingGuestList) {
            EventGuestListView(
                eventId: eventId,
                viewModel: viewModel,
                event: viewModel.event
            )
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Delete Event", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteEvent(eventId: eventId) { success in
                    if success {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .sheet(isPresented: $showingTicketConfirmation) {
            TicketConfirmationView(
                ticketPrice: Float(viewModel.event?.ticketPrice ?? 0),
                paymentHandle: viewModel.event?.paymentHandle,
                onConfirm: {
                    // User confirmed they've paid, proceed with RSVP
                    Log.debug("🔵 User confirmed payment, sending PENDING to backend...")
                    viewModel.updateRSVP(eventId: eventId, status: "PENDING") { success in
                        Log.debug("🔵 PENDING response - Success: \(success)")
                        if success {
                            // Refresh event details to get updated status
                            viewModel.fetchEventDetails(eventId: eventId)
                        }
                    }
                    showingTicketConfirmation = false
                },
                onDismiss: {
                    showingTicketConfirmation = false
                }
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: ["https://www.coveapp.co/events/\(eventId)"])
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Settings Dropdown (matches CoveView style)
private struct EventSettingsDropdownMenu: View {
    let isHost: Bool
    let onShare: () -> Void
    let onEdit: () -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isHost {
                MenuRow(title: "edit", systemImage: "pencil") { onEdit() }
            }
            MenuRow(title: "share", systemImage: "square.and.arrow.up") { onShare() }
        }
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Colors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .onTapGesture {} // absorb taps inside menu
    }

    private struct MenuRow: View {
        let title: String
        var textColor: Color = Colors.primaryDark
        var systemImage: String? = nil
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: 10) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(textColor)
                    }
                    Text(title)
                        .font(.LibreBodoni(size: 16))
                        .foregroundStyle(textColor)
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressHighlightStyle())
        }
    }
}

// Press highlight style (copied to match CoveView)
private struct PressHighlightStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.black.opacity(0.06) : Color.clear)
    }
}

// Icon tint on press (matches CoveInfoHeaderView)
private struct TintOnPressIconStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(Colors.primaryDark.opacity(configuration.isPressed ? 0.5 : 1.0))
    }
}

#Preview {
    EventPostView(eventId: "cmb77a64d000ijs086d8sifig", coveCoverPhoto: nil)
}

