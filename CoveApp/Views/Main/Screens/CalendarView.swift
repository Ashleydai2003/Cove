//
//  CalendarView.swift
//  Cove
//

import SwiftUI

// MARK: — The main CalendarView
struct CalendarView: View {
    
    @StateObject private var viewModel = UpcomingEventsViewModel()

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
                        ProgressView()
                            .padding()
                    } else {
                        ForEach(viewModel.events, id: \..id) { event in
                            EventSummaryView(event: event)
                                .padding(.horizontal, 20)
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        }
                    }

                    Spacer(minLength: 20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.fetchUpcomingEvents()
        }
    }
}

// MARK: — Preview
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}

