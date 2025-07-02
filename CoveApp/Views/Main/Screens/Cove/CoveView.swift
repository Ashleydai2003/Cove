//
//  CoveView.swift (formerly FeedView.swift)
//  Cove
//
//  Created by Ananya Agarwal
//  Refactored and documented by AI for maintainability and best practices

import SwiftUI
import Kingfisher

/// CoveView: Displays the feed for a specific cove, including cove details and events.
struct CoveView: View {
    @ObservedObject var viewModel: CoveModel
    let coveId: String
    @EnvironmentObject var appController: AppController
    @Environment(\.dismiss) private var dismiss
    
    // TODO: admin can update cove cover photo 
    
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
                        // Cove header with back button and cover photo
                        HStack(alignment: .top) {
                            Button {
                                dismiss()
                            } label: {
                                Images.backArrow
                            }
                            .padding(.top, 16)
                            
                            Spacer()
                            
                            // Cove cover photo using Kingfisher
                            if let urlString = cove.coverPhoto?.url, let url = URL(string: urlString) {
                                KFImage(url)
                                    .placeholder {
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(maxWidth: 100, maxHeight: 100)
                                            .overlay(ProgressView().tint(.gray))
                                    }
                                    .onSuccess { result in
                                        print("📸 CoveView cove cover loaded from: \(result.cacheType)")
                                    }
                                    .resizable()
                                    .fade(duration: 0.2)
                                    .cacheOriginalImage()
                                    .loadDiskFileSynchronously()
                                    .aspectRatio(1, contentMode: .fill)
                                    .frame(maxWidth: 100, maxHeight: 100)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(maxWidth: 100, maxHeight: 100)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        
                        Text(cove.name.isEmpty ? "untitled" : cove.name)
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
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(viewModel.events, id: \.id) { event in
                                EventSummaryView(event: event, type: .cove)
                                    .onAppear {
                                        DispatchQueue.main.async {
                                            viewModel.loadMoreEventsIfNeeded(currentEvent: event)
                                        }
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
                .refreshable {
                    await withCheckedContinuation { continuation in
                        viewModel.refreshCoveData()
                        // Give it a moment to complete the refresh
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            continuation.resume()
                        }
                    }
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
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionView(coveId: coveId)
                        .padding(.trailing, 24)
                        .padding(.bottom, 30) 
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.fetchCoveDetailsIfStale(coveId: coveId)
        }
        .onDisappear {
            // Cancel any ongoing requests when view disappears
            viewModel.cancelRequests()
        }
        .alert("error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("ok") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

/// EventView: Displays a single event in the feed, including cover photo and details.
struct EventView: View {
    let event: CalendarEvent
    
    var body: some View {
        NavigationLink(value: event.id) {
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
                
                // Event cover photo using Kingfisher
                if let urlString = event.coverPhoto?.url, let url = URL(string: urlString) {
                    KFImage(url)
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .aspectRatio(16/9, contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: 192)
                                .overlay(ProgressView().tint(.gray))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .onSuccess { result in
                            print("📸 Event cover loaded from: \(result.cacheType)")
                        }
                        .resizable()
                        .fade(duration: 0.2)
                        .cacheOriginalImage()
                        .loadDiskFileSynchronously()
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 192)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Text(event.description ?? "")
                    .foregroundStyle(Color.black)
                    .font(.LibreBodoniSemiBold(size: 12))
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 10)
        }
    }
    
    /// Returns a human-readable time-ago string for the event date.
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
    CoveView(viewModel: CoveModel(), coveId: "1")
}
