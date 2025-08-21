//
//  CalendarView.swift (new)
//  Cove
//

import SwiftUI
import FirebaseAuth

struct CalendarView: View {
    @EnvironmentObject private var appController: AppController
    @ObservedObject private var calendarFeed: CalendarFeed = AppController.shared.calendarFeed

    var body: some View {
        NavigationStack {
            ZStack {
                Colors.background.ignoresSafeArea()

                Group {
                    if calendarFeed.isLoading && calendarFeed.events.isEmpty {
                        CalendarLoadingStateView()
                    } else if let error = calendarFeed.errorMessage {
                        CalendarErrorStateView(message: error)
                    } else if rsvpdEvents.isEmpty {
                        CalendarEmptyStateView()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 5) {
                                CalendarEventsListView(events: rsvpdEvents)
                                Spacer(minLength: 20)
                            }
                        }
                        .refreshable {
                            await withCheckedContinuation { continuation in
                                calendarFeed.refreshCalendarEvents {
                                    continuation.resume()
                                }
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: String.self) { eventId in
                // Find the event to extract cover photo
                let coverPhoto = appController.calendarFeed.events.first(where: { $0.id == eventId })?.coveCoverPhoto
                EventPostView(eventId: eventId, coveCoverPhoto: coverPhoto)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            calendarFeed.fetchCalendarEventsIfStale()
        }
    }

    // Filter events to only show those where user has RSVP'd
    private var rsvpdEvents: [CalendarEvent] {
        calendarFeed.events.filter { event in
            event.rsvpStatus == "GOING" || event.rsvpStatus == "MAYBE" || isUserHosting(event)
        }
    }

    // Check if current user is hosting the event
    private func isUserHosting(_ event: CalendarEvent) -> Bool {
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        return event.hostId == currentUserId
    }
}

// MARK: - Events List
private struct CalendarEventsListView: View {
    let events: [CalendarEvent]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(sortedGroupedDates, id: \.self) { date in
                VStack(alignment: .leading, spacing: 0) {
                    // Date header with line
                    HStack(alignment: .center, spacing: 18) {
                        Text(dateLabel(for: date))
                            .font(.LibreBodoni(size: 15))
                            .foregroundColor(Colors.primaryDark)
                            .padding(.leading, 22)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Colors.primaryDark)
                            .opacity(0.4)
                            .padding(.trailing, 22)
                    }
                    .padding(.vertical, 15)

                    ForEach(sortedEvents(for: date), id: \.id) { event in
                        EventSummaryView(event: event, type: .calendar)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    // Group events by date
    private var groupedEvents: [Date: [CalendarEvent]] {
        Dictionary(grouping: events) { event in
            Calendar.current.startOfDay(for: event.eventDate)
        }
    }

    // Sorted array of unique event dates
    private var sortedGroupedDates: [Date] {
        groupedEvents.keys.sorted()
    }

    // For a given day, show upcoming events first (ascending), then past (descending)
    private func sortedEvents(for date: Date) -> [CalendarEvent] {
        let dayEvents = groupedEvents[date] ?? []
        let now = Date()
        var upcoming: [(Date, CalendarEvent)] = []
        var past: [(Date, CalendarEvent)] = []

        for ev in dayEvents {
            let d = ev.eventDate
            if d >= now {
                upcoming.append((d, ev))
            } else {
                past.append((d, ev))
            }
        }

        upcoming.sort { $0.0 < $1.0 }
        past.sort { $0.0 > $1.0 }
        return upcoming.map { $0.1 } + past.map { $0.1 }
    }

    // Returns the appropriate label for a date
    private func dateLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "today"
        } else if calendar.isDateInTomorrow(date) {
            return "tomorrow"
        } else {
            return AppController.shared.calendarFeed.formattedDateWithOrdinal(date).lowercased()
        }
    }
}

// MARK: - Loading State
private struct CalendarLoadingStateView: View {
    var body: some View {
        Spacer()
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .foregroundColor(Colors.primaryDark)
            Text("loading your calendar...")
                .font(.LibreBodoni(size: 16))
                .foregroundColor(.gray)
                .padding(.top, 16)
        }
        Spacer()
    }
}

// MARK: - Error State
private struct CalendarErrorStateView: View {
    let message: String

    var body: some View {
        Spacer()
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text(message)
                .font(.LibreBodoni(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        Spacer()
    }
}

// MARK: - Empty State
private struct CalendarEmptyStateView: View {
    var body: some View {
        Spacer()
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 40))
                .foregroundColor(Colors.primaryDark)

            Text("no upcoming events")
                .font(.LibreBodoniBold(size: 20))
                .foregroundColor(Colors.primaryDark)

            Text("when you rsvp to events, they'll appear here")
                .font(.LibreBodoni(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        Spacer()
    }
}

#Preview {
    CalendarView()
        .environmentObject(AppController.shared)
}


