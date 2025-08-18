//
//  CalendarView.swift
//  Cove
//
//  Created by Ananya Agarwal
import SwiftUI

// MARK: - CalendarView
struct CalendarView: View {

    @EnvironmentObject var appController: AppController
    @ObservedObject private var calendarFeed: CalendarFeed
    @State private var navigationPath = NavigationPath()

    init() {
        self._calendarFeed = ObservedObject(wrappedValue: AppController.shared.calendarFeed)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
        ZStack {
            Colors.faf8f4
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    CoveBannerView()

                    // Main content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 5) {
                                contentView
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationDestination(for: String.self) { eventId in
                // Find the event in our calendar data to get the cover photo
                let event = calendarFeed.events.first { $0.id == eventId }
                EventPostView(eventId: eventId, coveCoverPhoto: event?.coveCoverPhoto)
                        }
                    }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            calendarFeed.fetchCalendarEventsIfStale()
        }
        .onChange(of: calendarFeed.navigateToEventId) { _, newValue in
            guard let eventId = newValue else { return }
            DispatchQueue.main.async {
                navigationPath.append(eventId)
                calendarFeed.navigateToEventId = nil
            }
        }
        .alert("error", isPresented: errorBinding) {
            Button("ok") { calendarFeed.errorMessage = nil }
        } message: {
            Text(calendarFeed.errorMessage ?? "")
        }
    }

    // MARK: - Computed Properties

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { calendarFeed.errorMessage != nil },
            set: { if !$0 { calendarFeed.errorMessage = nil } }
        )
    }

    @ViewBuilder
    private var contentView: some View {
        if calendarFeed.isLoading && calendarFeed.events.isEmpty {
            LoadingStateView()
        } else if let error = calendarFeed.errorMessage {
            ErrorStateView(message: error)
        } else if calendarFeed.events.isEmpty {
            EmptyStateView()
        } else {
            EventsListView()
        }
    }
}

// MARK: - Loading State
private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Colors.primaryDark)
            Text("loading your calendar...")
                .font(.LibreBodoni(size: 16))
                .foregroundColor(Colors.primaryDark)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height - 200)
    }
}

// MARK: - Error State
private struct ErrorStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text(message)
                .font(.LibreBodoni(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height - 200)
    }
}

// MARK: - Empty State
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 40))
                .foregroundColor(Colors.primaryDark)

            Text("no events on your calendar – plan something fun!")
                .font(.LibreBodoni(size: 16))
                .foregroundColor(Colors.primaryDark)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height - 200)
    }
}

// MARK: - Events List
private struct EventsListView: View {
    @ObservedObject private var calendarFeed: CalendarFeed

    init() {
        self._calendarFeed = ObservedObject(wrappedValue: AppController.shared.calendarFeed)
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(sortedGroupedDates, id: \ .self) { date in
                VStack(alignment: .leading, spacing: 0) {
                    // Header with line
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

                    ForEach(sortedEvents(for: date), id: \ .id) { event in
                        EventSummaryView(event: event, type: .calendar)
                            .padding(.horizontal, 20)
                            .onAppear {
                                loadMoreIfNeeded(for: event)
                            }
                    }
                }
            }

            if calendarFeed.isLoading && !calendarFeed.events.isEmpty {
                LoadingIndicatorView()
            }
        }
    }

    // Sorted array of unique event dates
    private var sortedGroupedDates: [Date] {
        calendarFeed.groupedEvents.keys.sorted()
    }

    // For a given day, show upcoming events first (ascending), then past (descending)
    private func sortedEvents(for date: Date) -> [CalendarEvent] {
        let dayEvents = calendarFeed.groupedEvents[date] ?? []
        let now = Date()
        var upcoming: [(Date, CalendarEvent)] = []
        var past: [(Date, CalendarEvent)] = []
        for ev in dayEvents {
            let d = ev.eventDate
            if d >= now { upcoming.append((d, ev)) } else { past.append((d, ev)) }
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
            return calendarFeed.formattedDateWithOrdinal(date).lowercased()
        }
    }

    // Load more events if we've reached the last event
    private func loadMoreIfNeeded(for event: CalendarEvent) {
        if let lastEvent = calendarFeed.events.last, lastEvent.id == event.id {
            calendarFeed.loadMoreEventsIfNeeded()
        }
    }
}

// MARK: - Loading Indicator
private struct LoadingIndicatorView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(Colors.primaryDark)
            Spacer()
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Preview
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .environmentObject(AppController.shared)
    }
}
