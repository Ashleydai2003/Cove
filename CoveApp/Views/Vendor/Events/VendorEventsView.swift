//
//  VendorEventsView.swift
//  Cove
//
//  Vendor events list view
//

import SwiftUI

struct VendorEventsView: View {
    @EnvironmentObject var vendorController: VendorController
    @Binding var navigationPath: NavigationPath
    @State private var events: [VendorEvent] = []
    @State private var isLoading: Bool = true
    
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
                            .font(.LeagueSpartan(size: 16))
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
                                    VendorEventCard(event: event)
                                }
                            }
                            .padding(.horizontal, 20)
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
            .navigationDestination(for: String.self) { destination in
                if destination == "createEvent" {
                    VendorCreateEventView()
                }
            }
        }
        .onAppear {
            loadEvents()
        }
        .onChange(of: vendorController.shouldRefreshEvents) { _, _ in
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

// MARK: - Vendor Event Card
struct VendorEventCard: View {
    let event: VendorEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            eventHeader
            eventDescription
            eventStats
        }
        .padding(16)
        .background(cardBackground)
    }
    
    private var eventHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.LibreBodoniBold(size: 18))
                    .foregroundColor(Colors.primaryDark)
                    .lineLimit(2)
                
                Text(event.location)
                    .font(.LeagueSpartan(size: 14))
                    .foregroundColor(Colors.primaryDark.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            eventDateBadge
        }
    }
    
    private var eventDateBadge: some View {
        Text(event.eventDate.formatted(date: .abbreviated, time: .omitted))
            .font(.LeagueSpartan(size: 12))
            .foregroundColor(Colors.primaryDark.opacity(0.6))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Colors.primaryDark.opacity(0.1))
            )
    }
    
    @ViewBuilder
    private var eventDescription: some View {
        if let description = event.description, !description.isEmpty {
            Text(description)
                .font(.LeagueSpartan(size: 14))
                .foregroundColor(Colors.primaryDark.opacity(0.8))
                .lineLimit(3)
        }
    }
    
    private var eventStats: some View {
        HStack(spacing: 16) {
            rsvpCountView
            
            if let price = event.ticketPrice, price > 0 {
                priceView(price: price)
            }
            
            Spacer()
        }
    }
    
    private var rsvpCountView: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.2")
                .font(.system(size: 12))
                .foregroundColor(Colors.primaryDark.opacity(0.6))
            Text("\(event.rsvpCounts.going) RSVPs")
                .font(.LeagueSpartan(size: 12))
                .foregroundColor(Colors.primaryDark.opacity(0.6))
        }
    }
    
    private func priceView(price: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 12))
                .foregroundColor(Colors.primaryDark.opacity(0.6))
            Text("$\(String(format: "%.0f", price))")
                .font(.LeagueSpartan(size: 12))
                .foregroundColor(Colors.primaryDark.opacity(0.6))
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
    }
}

#Preview {
    VendorEventsView(navigationPath: .constant(NavigationPath()))
        .environmentObject(VendorController.shared)
}
