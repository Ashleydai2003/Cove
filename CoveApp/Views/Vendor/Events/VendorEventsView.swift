//
//  VendorEventsView.swift
//  Cove
//
//  Vendor events list view matching UpcomingView design
//

import SwiftUI

struct VendorEventsView: View {
    @EnvironmentObject var vendorController: VendorController
    @Binding var navigationPath: NavigationPath
    @State private var events: [VendorEvent] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Colors.background.ignoresSafeArea()
                
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(Colors.primaryDark)
                        Text("Loading events...")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(Colors.primaryDark.opacity(0.7))
                            .padding(.top, 8)
                        Spacer()
                    }
                } else if events.isEmpty {
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(Colors.primaryDark.opacity(0.3))
                        
                        VStack(spacing: 8) {
                            Text("No Events Yet")
                                .font(.LibreBodoniBold(size: 24))
                                .foregroundColor(Colors.primaryDark)
                            
                            Text("Create your first event to get started")
                                .font(.LeagueSpartan(size: 16))
                                .foregroundColor(Colors.primaryDark.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            navigationPath.append("createEvent")
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Create Event")
                                    .font(.LibreBodoniBold(size: 16))
                            }
                            .foregroundColor(Colors.background)
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Colors.primaryDark)
                            )
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                    }
                } else {
                    ZStack {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(events, id: \.id) { event in
                                    VendorEventSummaryView(event: event)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 100) // Space for floating button
                        }
                        .refreshable {
                            await refreshEvents()
                        }
                        
                        // Floating Create Event Button
                        VStack {
                            Spacer()
                            
                            Button(action: {
                                navigationPath.append("createEvent")
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Create Event")
                                        .font(.LibreBodoniBold(size: 16))
                                }
                                .foregroundColor(Colors.background)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Colors.primaryDark)
                                        .shadow(color: Colors.primaryDark.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: VendorEvent.self) { event in
                VendorEventPostView(event: event) { deletedEventId in
                    // Handle event deletion - refresh the feed
                    loadEvents()
                }
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "createEvent" {
                    VendorCreateEventView()
                }
            }
        }
        .onAppear {
            loadEvents()
        }
    }
    
    private func loadEvents() {
        isLoading = true
        
        VendorNetworkManager.shared.getVendorEvents { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let vendorEvents):
                    self.events = vendorEvents.events
                case .failure(let error):
                    print("Error loading events: \(error.localizedDescription)")
                    self.events = []
                }
            }
        }
    }
    
    private func refreshEvents() async {
        await withCheckedContinuation { continuation in
            VendorNetworkManager.shared.getVendorEvents { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let vendorEvents):
                        self.events = vendorEvents.events
                    case .failure(let error):
                        print("Error refreshing events: \(error.localizedDescription)")
                    }
                    continuation.resume()
                }
            }
        }
    }
}

#Preview {
    VendorEventsView(navigationPath: .constant(NavigationPath()))
        .environmentObject(VendorController.shared)
}
