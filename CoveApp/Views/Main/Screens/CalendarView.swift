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
                VStack(spacing: 20) {
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
                        ForEach(viewModel.events, id: \.id) { event in
                            EventCardView(event: event)
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

fileprivate struct EventCardView: View {
    let event: CalendarEvent
    @EnvironmentObject var appController: AppController

    var body: some View {
        Button {
            appController.navigateToEvent(eventId: event.id)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(1.0), lineWidth: 1)
                    )

                VStack(spacing: 4) {
                    HStack {
                        Text(formattedDateTime(event.date))
                            .font(.LibreBodoniItalic(size: 14))
                            .foregroundColor(Colors.primaryDark.opacity(0.8))
                        Spacer()
                        // TODO: Get actual RSVP count
                        Text("\(event.goingCount) going")
                            .font(.LeagueSpartan(size: 13))
                            .foregroundColor(Colors.primaryDark.opacity(0.9))
                    }

                    HStack {
                        Spacer()
                        Text(event.name)
                            .font(.LibreBodoniBold(size: 20))
                            .foregroundColor(Colors.primaryDark)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.top, 15)
                        Spacer()
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .frame(height: 100)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    func formattedDateTime(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return "TBD"
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "EEEE, MMMM d @ h:mm a"
        // Use user's local timezone (default behavior)
        return outputFormatter.string(from: date).lowercased()
    }
}

// MARK: — Preview
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}

