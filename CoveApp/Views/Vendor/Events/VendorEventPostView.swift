//
//  VendorEventPostView.swift
//  Cove
//
//  Vendor event detail view
//

import SwiftUI
import Kingfisher

struct VendorEventPostView: View {
    let event: VendorEvent
    var onEventDeleted: ((String) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Top Navigation Bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Colors.primaryDark)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Colors.primaryDark)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)

                    VStack(alignment: .leading, spacing: 24) {
                        // Event Title
                        Text(event.name.isEmpty ? "Untitled" : event.name)
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoniBold(size: 26))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)

                        // Event Cover Photo
                        if let urlString = event.coverPhotoUrl, let url = URL(string: urlString) {
                            KFImage(url)
                                .placeholder {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 192)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .resizable()
                                .fade(duration: 0.2)
                                .cacheOriginalImage()
                                .cancelOnDisappear(true)
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 192)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            // Default event image
                            Image("default_event2")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 192)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        VStack(alignment: .leading, spacing: 20) {
                            // Date and Time
                            HStack {
                                Text(event.eventDate.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundStyle(Color.black)
                                    .font(.LibreBodoni(size: 18))
                                Spacer()
                                Text(event.eventDate.formatted(date: .omitted, time: .shortened))
                                    .foregroundStyle(Colors.primaryDark)
                                    .font(.LibreBodoni(size: 18))
                            }

                            // Location
                            HStack {
                                Image("locationIcon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15, height: 20)

                                Text(event.location)
                                    .foregroundStyle(Colors.primaryDark)
                                    .font(.LibreBodoniBold(size: 16))
                            }

                            // Host information
                            HStack {
                                Text("hosted by")
                                    .font(.LibreBodoni(size: 18))
                                    .foregroundColor(Color.black)
                                Text(event.vendorName ?? "Your Organization")
                                    .font(.LibreBodoni(size: 18))
                                    .foregroundColor(Colors.primaryDark)
                            }
                            
                            // Event details section (price, capacity, going count)
                            VStack(alignment: .leading, spacing: 12) {
                                // Pricing display - tiered or single
                                if event.useTieredPricing == true, !event.pricingTiers.isEmpty {
                                    tieredPricingDisplaySection(tiers: event.pricingTiers, goingCount: event.rsvpCounts.going)
                                } else if let ticketPrice = event.ticketPrice {
                                    singlePricingDisplaySection(price: ticketPrice)
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
                                if let memberCap = event.memberCap {
                                    HStack {
                                        Image(systemName: "person.2")
                                            .foregroundColor(Colors.primaryDark)
                                            .font(.system(size: 16))
                                        let goingCount = event.rsvpCounts.going
                                        let spotsLeft = max(0, memberCap - goingCount)
                                        Text("\(goingCount)/\(memberCap) going • \(spotsLeft) spots left")
                                            .font(.LibreBodoni(size: 16))
                                            .foregroundColor(Colors.primaryDark)
                                    }
                                } else {
                                    HStack {
                                        Image(systemName: "person.2")
                                            .foregroundColor(Colors.primaryDark)
                                            .font(.system(size: 16))
                                        let goingCount = event.rsvpCounts.going
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
                                
                                Text("\(event.rsvpCounts.going) going")
                                    .font(.LibreBodoni(size: 14))
                                    .foregroundColor(Colors.primaryDark)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Colors.primaryDark.opacity(0.1))
                                    )
                            }

                            Text("\(event.rsvpCounts.going) people are going to this event")
                                .font(.LibreBodoni(size: 14))
                                .foregroundColor(Colors.primaryDark)
                                .padding(.leading, 4)
                        }
                        .padding(.top, 16)

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Pricing Display Helpers
    
    @ViewBuilder
    private func tieredPricingDisplaySection(tiers: [VendorEvent.PricingTier], goingCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(Colors.primaryDark)
                    .font(.system(size: 16))
                Text("Tiered Pricing")
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundColor(Colors.primaryDark)
            }
            
            ForEach(tiers.sorted { $0.sortOrder < $1.sortOrder }, id: \.tierType) { tier in
                let isSoldOut = tier.maxSpots != nil && goingCount >= tier.maxSpots!
                
                HStack(spacing: 12) {
                    // Tier icon based on type
                    Image(systemName: tierIcon(for: tier.tierType))
                        .foregroundColor(isSoldOut ? .gray : tierColor(for: tier.tierType))
                        .font(.system(size: 14, weight: .medium))
                    
                    // Tier name and price
                    Text(tier.tierType)
                        .font(.LibreBodoni(size: 14))
                        .foregroundColor(isSoldOut ? .gray : Colors.primaryDark)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(String(format: "%.2f", tier.price))")
                            .font(.LibreBodoniBold(size: 14))
                            .foregroundColor(isSoldOut ? .gray : Colors.primaryDark)
                        
                        if let maxSpots = tier.maxSpots {
                            let spotsLeft = max(0, maxSpots - goingCount)
                            Text(spotsLeft > 0 ? "\(spotsLeft) left" : "sold out")
                                .font(.LibreBodoni(size: 12))
                                .foregroundColor(spotsLeft > 0 ? .green : .red)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSoldOut ? Color.gray.opacity(0.1) : Color.white.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSoldOut ? Color.gray.opacity(0.3) : Color.black.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    @ViewBuilder
    private func singlePricingDisplaySection(price: Double) -> some View {
        HStack {
            Image(systemName: "dollarsign.circle")
                .foregroundColor(Colors.primaryDark)
                .font(.system(size: 16))
            Text("$\(String(format: "%.2f", price))")
                .font(.LibreBodoni(size: 16))
                .foregroundColor(Colors.primaryDark)
        }
    }
    
    // Helper functions for tier display
    private func tierIcon(for tierType: String) -> String {
        switch tierType.lowercased() {
        case "early bird":
            return "clock.fill"
        case "regular":
            return "person.fill"
        case "last minute":
            return "exclamationmark.triangle.fill"
        default:
            return "tag.fill"
        }
    }
    
    private func tierColor(for tierType: String) -> Color {
        switch tierType.lowercased() {
        case "early bird":
            return Colors.primaryDark.opacity(0.8)
        case "regular":
            return Colors.primaryDark
        case "last minute":
            return Colors.primaryDark.opacity(0.9)
        default:
            return Colors.primaryDark
        }
    }
}

#Preview {
    let sampleEvent = VendorEvent(
        id: "test-event-id",
        name: "Sample Event",
        description: "This is a sample event for preview",
        date: "2024-12-25T18:00:00.000Z",
        location: "San Francisco, CA",
        memberCap: 50,
        ticketPrice: 25.0,
        paymentHandle: "sample-venmo",
        isPublic: true,
        vendorId: "vendor-123",
        vendorName: "Sample Vendor",
        coverPhotoUrl: nil,
        useTieredPricing: false,
        pricingTiers: [],
        rsvpCounts: VendorEvent.RSVPCounts(going: 15, maybe: 3, cantGo: 2),
        createdAt: "2024-12-01T10:00:00.000Z"
    )
    
    VendorEventPostView(event: sampleEvent)
}
