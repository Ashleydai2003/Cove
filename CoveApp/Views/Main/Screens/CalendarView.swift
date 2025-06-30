//
//  CalendarView.swift
//  Cove
//

import SwiftUI

// MARK: — The main CalendarView
struct CalendarView: View {
    
    @EnvironmentObject var appController: AppController
    @ObservedObject private var calendarFeed: CalendarFeed

    init() {
        // Initialize with the shared instance
        self._calendarFeed = ObservedObject(wrappedValue: AppController.shared.calendarFeed)
    }

    var body: some View {
        ZStack {
            Colors.faf8f4
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 5) {
                    // MARK: — Top Title
                    Text("upcoming events")
                        .font(.LibreBodoniBold(size: 32))
                        .foregroundColor(Colors.primaryDark)
                        .padding(.top, 20)
                        .padding(.bottom, 30)

                    if calendarFeed.isLoading && calendarFeed.events.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(Colors.primaryDark)
                            Text("loading your events...")
                                .font(.LibreBodoni(size: 16))
                                .foregroundColor(Colors.primaryDark)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = calendarFeed.errorMessage {
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
                    } else if calendarFeed.events.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("no upcoming events")
                                .font(.LibreBodoni(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(calendarFeed.events.enumerated()), id: \.element.id) { idx, event in
                                EventSummaryView(event: event)
                                    .padding(.horizontal, 20)
                                    .onAppear {
                                        // Load more events when reaching the end
                                        if idx == calendarFeed.events.count - 1 {
                                            calendarFeed.loadMoreEventsIfNeeded()
                                        }
                                    }
                            }
                            
                            if calendarFeed.isLoading && !calendarFeed.events.isEmpty {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(Colors.primaryDark)
                                    Spacer()
                                }
                                .padding(.vertical, 16)
                            }
                        }
                    }

                    Spacer(minLength: 20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            calendarFeed.fetchCalendarEventsIfStale()
        }
        .onDisappear {
            calendarFeed.cancelRequests()
        }
        .alert("error", isPresented: Binding(
            get: { calendarFeed.errorMessage != nil },
            set: { if !$0 { calendarFeed.errorMessage = nil } }
        )) {
            Button("ok") { calendarFeed.errorMessage = nil }
        } message: {
            Text(calendarFeed.errorMessage ?? "")
        }
    }
}

// MARK: — Preview
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .environmentObject(AppController.shared)
    }
}

