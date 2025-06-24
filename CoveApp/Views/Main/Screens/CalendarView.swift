//
//  CalendarView.swift
//  Cove
//

import SwiftUI

struct PlaceholderEvent: Identifiable {
    let id = UUID()
    let dateString: String
    let title: String
    let goingCount: Int
}

// MARK: — The main CalendarView
struct CalendarView: View {

    /// (1) Hard‐coded array of five placeholder events
    private let events: [PlaceholderEvent] = [
        PlaceholderEvent(
            dateString: "saturday, june 21  @ 9pm",
            title: "stanford x harvard happy hour",
            goingCount: 34
        ),
        PlaceholderEvent(
            dateString: "sunday, june 22  @ 9pm",
            title: "stanford sf club dinner",
            goingCount: 34
        ),
        PlaceholderEvent(
            dateString: "wednesday, june 25  @ 9pm",
            title: "yale founders dinner",
            goingCount: 34
        ),
        PlaceholderEvent(
            dateString: "friday, june 27  @ 9pm",
            title: "usc x cal mixer",
            goingCount: 34
        ),
        PlaceholderEvent(
            dateString: "saturday, june 28  @ 9pm",
            title: "stanford sf club opera",
            goingCount: 34
        )
    ]

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

                    ForEach(events) { event in
                        EventCardView(event: event)
                            .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

fileprivate struct EventCardView: View {
    let event: PlaceholderEvent

    var body: some View {
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
                    Text(event.dateString)
                        .font(.LibreBodoniItalic(size: 14))
                        .foregroundColor(Colors.primaryDark.opacity(0.8))
                    Spacer()
                    Text("\(event.goingCount) going")
                        .font(.LeagueSpartan(size: 13))
                        .foregroundColor(Colors.primaryDark.opacity(0.9))
                }

                HStack {
                    Spacer()
                    Text(event.title)
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
}


// MARK: — Preview
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .previewDevice("iPhone 13")
    }
}

