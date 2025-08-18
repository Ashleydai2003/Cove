//
//  CoveEventsView.swift
//  Cove
//
//  Created by Ashley Dai on 7/1/25.
//

import SwiftUI
import Kingfisher

/// CoveEventsView: Reusable component for displaying cove events list
/// - Shows scrollable list of events with pull-to-refresh
/// - Handles pagination and loading states
struct CoveEventsView: View {
    @ObservedObject var viewModel: CoveModel
    let onRefresh: () async -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(sortedEvents, id: \.id) { event in
                    EventSummaryView(event: event, type: .cove)
                        .onAppear {
                            DispatchQueue.main.async {
                                viewModel.loadMoreEventsIfNeeded(currentEvent: event)
                            }
                        }
                }

                // Cute empty state
                if viewModel.events.isEmpty && !viewModel.isLoading && !viewModel.isRefreshingEvents {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(Colors.primaryDark)
                        Text("no events yet – be the first to host!")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(Colors.primaryDark)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                }

                // Show loading indicator only for events
                if viewModel.isRefreshingEvents || (viewModel.isLoading && !viewModel.events.isEmpty) {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Colors.primaryDark)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .refreshable {
            await onRefresh()
        }
    }

    // Upcoming first (ascending), past last (descending)
    private var sortedEvents: [CalendarEvent] {
        let now = Date()
        var upcoming: [(Date, CalendarEvent)] = []
        var past: [(Date, CalendarEvent)] = []
        for ev in viewModel.events {
            let d = ev.eventDate
            if d >= now { upcoming.append((d, ev)) } else { past.append((d, ev)) }
        }
        upcoming.sort { $0.0 < $1.0 }
        past.sort { $0.0 > $1.0 }
        return upcoming.map { $0.1 } + past.map { $0.1 }
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
    CoveEventsView(
        viewModel: CoveModel(),
        onRefresh: {}
    )
}
