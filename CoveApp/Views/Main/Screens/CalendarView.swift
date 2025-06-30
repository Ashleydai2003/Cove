//
//  CalendarView.swift
//  Cove
//

import SwiftUI

// MARK: — The main CalendarView
struct CalendarView: View {
    
    @ObservedObject var viewModel: CalendarFeed
    @EnvironmentObject var appController: AppController

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

                    if viewModel.isLoading && viewModel.events.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(Colors.primaryDark)
                            Text("loading your events...")
                                .font(.LibreBodoni(size: 16))
                                .foregroundColor(Colors.primaryDark)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    } else if viewModel.events.isEmpty {
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
                            ForEach(Array(viewModel.events.enumerated()), id: \.element.id) { idx, event in
                                EventSummaryView(event: event)
                                    .padding(.horizontal, 20)
                                    .onAppear {
                                        // Load more events when reaching the end
                                        if idx == viewModel.events.count - 1 {
                                            viewModel.loadMoreEventsIfNeeded()
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
                    }

                    Spacer(minLength: 20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.fetchCalendarEventsIfStale()
        }
        .onDisappear {
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

// MARK: — Preview
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(viewModel: AppController.shared.calendarFeed)
            .environmentObject(AppController.shared)
    }
}

