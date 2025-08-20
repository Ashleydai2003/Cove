//
//  CalendarPopupView.swift
//  Cove
//
//  Created by AI Assistant
//

import SwiftUI
import FirebaseAuth

struct CalendarPopupView: View {
    @EnvironmentObject private var appController: AppController
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var calendarFeed: CalendarFeed
    
    init() {
        self._calendarFeed = ObservedObject(wrappedValue: AppController.shared.calendarFeed)
    }
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            VStack {
                // Header with dismiss button (same style as InboxView)
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Colors.primaryDark)
                    }
                    
                    Spacer()
                    
                    Text("your calendar")
                        .font(.LibreBodoniBold(size: 20))
                        .foregroundColor(Colors.primaryDark)
                    
                    Spacer()
                    
                    // Invisible spacer to center the title
                    Button(action: {}) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.clear)
                    }
                    .disabled(true)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Main content
                if calendarFeed.isLoading && calendarFeed.events.isEmpty {
                    LoadingStateView()
                } else if let error = calendarFeed.errorMessage {
                    ErrorStateView(message: error)
                } else if rsvpdEvents.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 5) {
                            CalendarPopupEventsListView(events: rsvpdEvents)
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
        // Use Firebase Auth current user ID for comparison (same as EventSummaryView)
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        return event.hostId == currentUserId
    }
}

// MARK: - Calendar Popup Events List
private struct CalendarPopupEventsListView: View {
    let events: [CalendarEvent]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(sortedGroupedDates, id: \.self) { date in
                VStack(alignment: .leading, spacing: 0) {
                    // Date header with line (same style as CalendarView)
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
    
    // Returns the appropriate label for a date (same logic as CalendarView)
    private func dateLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "today"
        } else if calendar.isDateInTomorrow(date) {
            return "tomorrow"
        } else {
            // Use the same date formatter as CalendarFeed
            return AppController.shared.calendarFeed.formattedDateWithOrdinal(date).lowercased()
        }
    }
}

// MARK: - Loading State
private struct LoadingStateView: View {
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
private struct ErrorStateView: View {
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
private struct EmptyStateView: View {
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
    CalendarPopupView()
        .environmentObject(AppController.shared)
}
