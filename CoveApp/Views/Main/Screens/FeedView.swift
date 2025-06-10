//
//  FeedView.swift
//  Cove
//
//  Created by Ananya Agarwal
import SwiftUI

// MARK: - Main View
struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @EnvironmentObject var appController: AppController
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.events.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(Colors.primaryDark)
                    Text("loading your cove...")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(Colors.primaryDark)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let cove = viewModel.cove {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Cove header
                        HStack(alignment: .top) {
                            // Back button commented out as per request
                            /*
                            Button {
                                appController.path.removeLast()
                            } label: {
                                Images.backArrow
                            }
                            .padding(.top, 16)
                            */
                            
                            Spacer()
                            
                            CachedAsyncImage(
                                url: URL(string: cove.coverPhoto?.url ?? "")
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
                        }
                        .padding(.horizontal, 16)
                        
                        Text(cove.name.isEmpty ? "Untitled" : cove.name)
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoniBold(size: 26))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                        
                        Text("\(cove.stats.memberCount) members")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoniBold(size: 11))
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        if let description = cove.description {
                            Text(description)
                                .foregroundStyle(Colors.k292929)
                                .font(.LibreBodoni(size: 14))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        // Events section
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(viewModel.events) { event in
                                EventView(event: event)
                                    .onAppear {
                                        viewModel.loadMoreEventsIfNeeded(currentEvent: event)
                                    }
                            }
                            
                            if viewModel.isLoading && !viewModel.events.isEmpty {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(Colors.primaryDark)
                                    Spacer()
                                }
                                .padding(.vertical, 16)
                            }
                        }
                        
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
            viewModel.fetchCoveDetails()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Event View
struct EventView: View {
    let event: FeedEvent
    @EnvironmentObject private var appController: AppController
    
    var body: some View {
        Button {
            appController.path.append(.eventPost(eventId: event.id))
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    HStack(spacing: 5) {
                        Text("@\(event.hostName.lowercased())")
                            .foregroundStyle(Color.black)
                            .font(.LibreBodoniSemiBold(size: 12))
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(Color.black)
                            .font(.LibreBodoniSemiBold(size: 12))
                    }
                    
                    Spacer()
                    
                    Text(timeAgo(event.date))
                        .foregroundStyle(Color.black)
                        .font(.LibreBodoniSemiBold(size: 12))
                }
                
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
                
                Text(event.description ?? "")
                    .foregroundStyle(Color.black)
                    .font(.LibreBodoniSemiBold(size: 12))
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeAgo(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = formatter.date(from: dateString) else { return "" }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .day], from: date, to: now)
        
        if let hours = components.hour, hours < 24 {
            return "\(hours)hr"
        } else if let days = components.day, days < 7 {
            return "\(days)d"
        } else {
            return "1w"
        }
    }
}

#Preview {
    FeedView()
}
