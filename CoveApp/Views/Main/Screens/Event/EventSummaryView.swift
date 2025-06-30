import SwiftUI
import Kingfisher

/// EventSummaryView: Displays a single event in the feed, including cover photo and details.
struct EventSummaryView: View {
    let event: CalendarEvent
    @EnvironmentObject private var appController: AppController
    
    var body: some View {
        Button {
            appController.navigateToEvent(eventId: event.id)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Time-ago label above the photo
                HStack {
                    Spacer()
                    Text(timeAgo(event.createdAt))
                        .font(.LibreBodoniBold(size: 14))
                        .foregroundColor(.black)
                        .padding(.bottom, 2)
                }
                ZStack(alignment: .top) {
                    // Event cover photo using Kingfisher
                    if let urlString = event.coverPhoto?.url, let url = URL(string: urlString) {
                        KFImage(url)
                            .placeholder {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .aspectRatio(16/10, contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .overlay(ProgressView().tint(.gray))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                            .onSuccess { result in
                                print("📸 Event cover loaded from: \(result.cacheType)")
                            }
                            .resizable()
                            .cancelOnDisappear(true)
                            .fade(duration: 0.2)
                            .cacheOriginalImage()
                            .loadDiskFileSynchronously()
                            .aspectRatio(16/10, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    // Date label overlay (top left)
                    HStack {
                        if let dateLabel = formattedDateLabel(event.date) {
                            Text(dateLabel)
                                .font(.LibreBodoniBold(size: 14))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.38, green: 0.09, blue: 0.09))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.top, 10)
                                .padding(.leading, 8)
                        }
                        Spacer()
                    }
                }
                .padding(.bottom, 4)
                // Event name
                Text(event.name)
                    .font(.LibreBodoniBold(size: 18))
                    .foregroundColor(.black)
                    .padding(.top, 4)
                    .padding(.horizontal, 2)
                // Host info
                HStack(spacing: 4) {
                    Text("Hosted by")
                        .font(.LibreBodoniSemiBold(size: 13))
                        .foregroundColor(.black)
                    Text(event.hostName)
                        .font(.LibreBodoniSemiBold(size: 13))
                        .foregroundColor(Color(red: 0.56, green: 0.09, blue: 0.09))
                    // TODO: only checkmark if host is verified
                    // This may require backend changes
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(Color(red: 0.56, green: 0.09, blue: 0.09))
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 2)
                .padding(.top, 1)
                // Optionally, event description or location can be added here
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    /// Returns a human-readable time-ago string for the event date.
    private func timeAgo(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: dateString) else { return "" }
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        let weeks = Int(interval / 604800)
        let months = Int(interval / 2592000)
        if minutes < 1 {
            return "just now"
        } else if hours < 1 {
            return "\(minutes)m"
        } else if days < 1 {
            return "\(hours)h"
        } else if weeks < 1 {
            return "\(days)d"
        } else if months < 1 {
            return "\(weeks)w"
        } else {
            return "\(months)mo"
        }
    }
    /// Returns a formatted date label for the overlay (e.g., "Saturday July 18th")
    private func formattedDateLabel(_ dateString: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: dateString) else { return nil }
        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "EEEE MMMM d"
        return labelFormatter.string(from: date)
    }
} 