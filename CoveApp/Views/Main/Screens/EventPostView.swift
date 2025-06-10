//
//  EventPostView.swift
//  Cove
//
//  Created by Ananya Agarwal
import SwiftUI

// MARK: - View Model
class EventPostViewModel: ObservableObject {
    @Published var event: Event?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isDeleting = false
    
    func fetchEventDetails(eventId: String) {
        isLoading = true
        
        NetworkManager.shared.get(endpoint: "/event", parameters: ["eventId": eventId]) { [weak self] (result: Result<EventResponse, NetworkError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    self.event = response.event
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
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

// MARK: - Main View
struct EventPostView: View {
    let eventId: String
    @StateObject private var viewModel = EventPostViewModel()
    @EnvironmentObject var appController: AppController
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
            } else if let event = viewModel.event {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Back button and cove photo
                        HStack(alignment: .top) {
                            Button {
                                // Always go back to the previous view
                                appController.path.removeLast()
                            } label: {
                                Images.backArrow
                            }
                            .padding(.top, 16)
                            
                            Spacer()
                            
                            CachedAsyncImage(
                                url: URL(string: event.cove.coverPhoto?.url ?? "")
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
                        
                        if let coverPhoto = event.coverPhoto {
                            CachedAsyncImage(
                                url: URL(string: coverPhoto.url)
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
                            .frame(height: 192)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .clipped()
                        }
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text(event.formattedDate)
                                    .foregroundStyle(Colors.primaryDark)
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
                            
                            Text("Hosted by \(event.host.name)")
                                .foregroundStyle(Colors.primaryDark)
                                .font(.LibreBodoni(size: 16))
                        }
                        
                        if let description = event.description {
                            Text(description)
                                .foregroundStyle(Colors.k292929)
                                .font(.LibreBodoni(size: 18))
                                .multilineTextAlignment(.leading)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("guest list")
                                .foregroundStyle(Colors.primaryDark)
                                .font(.LibreBodoniBold(size: 18))
                            
                            HStack {
                                ForEach((1...4), id: \.self) { index in
                                    Images.profilePlaceholder
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 62, height: 62)
                                        .clipShape(Circle())
                                }
                                
                                Text("+80")
                                    .foregroundStyle(Colors.primaryDark)
                                    .font(.LibreBodoniBold(size: 10))
                                    .padding(.all, 8)
                                    .overlay {
                                        Circle()
                                            .stroke(Colors.primaryDark, lineWidth: 1.0)
                                    }
                            }
                        }
                        
                        HStack(spacing: 24) {
                            Spacer()
                            
                            Button {
                                // TODO: Implement RSVP action
                            } label: {
                                Text("yes")
                                    .foregroundStyle(Colors.k070708)
                                    .font(.LeagueSpartan(size: 12))
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Colors.kE8DFCB)
                                    )
                            }
                            
                            Button {
                                // TODO: Implement RSVP action
                            } label: {
                                Text("maybe")
                                    .foregroundStyle(Colors.k070708)
                                    .font(.LeagueSpartan(size: 12))
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.white)
                                    )
                            }
                            
                            Button {
                                // TODO: Implement RSVP action
                            } label: {
                                Text("no")
                                    .foregroundStyle(Colors.k070708)
                                    .font(.LeagueSpartan(size: 12))
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.white)
                                    )
                            }
                            
                            Spacer()
                        }
                        .padding([.horizontal, .vertical], 16)
                        .background(Colors.primaryDark)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        
                        Spacer(minLength: 24)
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
        .navigationBarBackButtonHidden()
        .onAppear {
            viewModel.fetchEventDetails(eventId: eventId)
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
                        appController.path.removeLast()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
    }
}

#Preview {
    EventPostView(eventId: "cmb77a64d000ijs086d8sifig")
}
