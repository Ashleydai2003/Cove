//
//  EventPostView.swift
//  Cove
//
//  Created by Ananya Agarwal
import SwiftUI
import Kingfisher

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
                    self.event = response.event
                    completion?()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func updateRSVP(eventId: String, status: String, completion: @escaping (Bool) -> Void) {
        isUpdatingRSVP = true
        
        NetworkManager.shared.post(endpoint: "/update-event-rsvp", parameters: ["eventId": eventId, "status": status]) { [weak self] (result: Result<UpdateRSVPResponse, NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isUpdatingRSVP = false
                
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

// MARK: - Main View
struct EventPostView: View {
    let eventId: String
    let coveCoverPhoto: CoverPhoto?
    @StateObject private var viewModel = EventPostViewModel()
    @EnvironmentObject var appController: AppController
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var currentRSVPStatus: String?
    
    init(eventId: String, coveCoverPhoto: CoverPhoto? = nil) {
        self.eventId = eventId
        self.coveCoverPhoto = coveCoverPhoto
    }
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
            } else if let event = viewModel.event {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Back button, cove photo and delete button
                        HStack(alignment: .top) {
                            Button {
                                dismiss()
                            } label: {
                                Images.backArrow
                            }
                            .padding(.top, 16)
                            
                            Spacer()
                            
                            // Use provided cover photo first, fallback to fetched event data
                            CachedAsyncImage(
                                url: URL(string: coveCoverPhoto?.url ?? event.cove.coverPhoto?.url ?? "")
                            ) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(
                                        ProgressView()
                                            .tint(.gray)
                                    )
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            
                            Spacer()
                            
                            // Add delete button if user is the host
                            if event.isHost {
                                Button {
                                    showingDeleteAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(Colors.primaryDark)
                                        .font(.system(size: 20))
                                }
                                .padding(.top, 16)
                            }
                        }
                        .padding(.horizontal, 16)
                        
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
                                        .overlay(
                                            ProgressView()
                                                .tint(Colors.primaryDark)
                                        )
                                }
                                .onSuccess { result in
                                    print("📸 EventPostView event cover loaded from: \(result.cacheType)")
                                }
                                .resizable()
                                .fade(duration: 0.2)
                                .cacheOriginalImage()
                                .loadDiskFileSynchronously()
                                .aspectRatio(contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .frame(height: 192)
                                .clipped()
                        } else {
                            // fallback placeholder
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 192)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text(event.formattedDate)
                                    .foregroundStyle(Color.black)
                                    .font(.LibreBodoni(size: 18))
                                Spacer()
                                Text(event.formattedTime)
                                    .foregroundStyle(Colors.primaryDark)
                                    .font(.LibreBodoni(size: 18))
                            }
                            
                            HStack {
                                Image("location-pin")
                                    .frame(width: 15, height: 20)
                                
                                Text(event.location.isEmpty ? "TBD" : event.location)
                                    .foregroundStyle(Colors.primaryDark)
                                    .font(.LibreBodoniBold(size: 16))
                            }
                            
                            HStack {
                                Text("hosted by")
                                    .font(.LibreBodoni(size: 18))
                                    .foregroundColor(Color.black)
                                Text(event.host.name)
                                .font(.LibreBodoni(size: 18))
                                .foregroundColor(Colors.primaryDark)
                            }
                        }
                        
                        if let description = event.description {
                            Text(description)
                                .foregroundStyle(Colors.k292929)
                                .font(.LibreBodoni(size: 18))
                                .multilineTextAlignment(.leading)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("guest list")
                                .font(.LibreBodoni(size: 18))
                                .foregroundColor(Colors.primaryDark)
                            
                            // Filter RSVPs to only show "GOING" status
                            let goingRsvps = event.rsvps.filter { $0.status == "GOING" }
                            
                            if goingRsvps.isEmpty {
                                Text("no guests yet! send your invites!")
                                    .font(.LibreBodoni(size: 14))
                                    .foregroundColor(Colors.primaryDark)
                            } else {
                                HStack {
                                    // Show up to 4 profile photos
                                    ForEach(Array(goingRsvps.prefix(4).enumerated()), id: \.element.id) { index, rsvp in
                                        if let profilePhotoID = rsvp.profilePhotoID {
                                            // TODO: Replace with actual profile photo URL when available
                                            Images.profilePlaceholder
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 62, height: 62)
                                                .clipShape(Circle())
                                        } else {
                                            Images.profilePlaceholder
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 62, height: 62)
                                                .clipShape(Circle())
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
                                }
                            }
                        }
                        
                        // Single RSVP button with two states
                            Button {
                            let currentStatus = currentRSVPStatus ?? event.rsvpStatus
                            if currentStatus == "GOING" {
                                // User is going, change to not going
                                currentRSVPStatus = "NOT_GOING"
                                viewModel.updateRSVP(eventId: eventId, status: "NOT_GOING") { _ in }
                            } else {
                                // User is not going or maybe, change to going
                                currentRSVPStatus = "GOING"
                                viewModel.updateRSVP(eventId: eventId, status: "GOING") { _ in }
                            }
                            } label: {
                            let currentStatus = currentRSVPStatus ?? event.rsvpStatus
                            let isGoing = currentStatus == "GOING"
                            
                            Text(isGoing ? "can't make it..." : "rsvp")
                                .foregroundStyle(isGoing ? Colors.primaryDark : .white)
                                .font(.LibreBodoni(size: 25))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                    .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(isGoing ? Color.white : Colors.primaryDark)
                                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 8)
                                    )
                            }
                            .disabled(viewModel.isUpdatingRSVP)
                        
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 50)
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
            viewModel.fetchEventDetails(eventId: eventId) {
                if let event = viewModel.event {
                    currentRSVPStatus = event.rsvpStatus
                }
            }
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
    }
}

#Preview {
    EventPostView(eventId: "cmb77a64d000ijs086d8sifig", coveCoverPhoto: nil)
}
