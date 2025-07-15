import SwiftUI
import Kingfisher
import FirebaseAuth

/// The context in which the event summary is shown (for styling/layout)
enum EventSummaryType {
    case cove
    case feed
    case calendar
}

/// EventSummaryView: Displays a single event in the feed, including cover photo and details.
struct EventSummaryView: View {
    let event: CalendarEvent
    var type: EventSummaryType = .feed // Default type
    @EnvironmentObject private var appController: AppController
    @State private var imageLoaded = false
    
    var body: some View {
        NavigationLink(value: event.id) {
            VStack(alignment: .leading, spacing: 0) {
                // Time-ago label above the photo (always render, but clear for calendar type)
                HStack {
                    Spacer()
                    Text(timeAgo(event.createdAt))
                        .font(.LibreBodoniBold(size: 14))
                        .foregroundColor(type == .calendar ? .clear : .black)
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
                                withAnimation(.easeIn(duration: 0.3)) {
                                    imageLoaded = true
                                }
                            }
                            .resizable()
                            .fade(duration: 0.2)
                            .cacheOriginalImage()
                            .loadDiskFileSynchronously()
                            .aspectRatio(16/10, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else {
                        // Default event image
                        Image("default_event2")
                            .resizable()
                            .aspectRatio(16/10, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .onAppear {
                                // For default images, set imageLoaded to true immediately
                                withAnimation(.easeIn(duration: 0.3)) {
                                    imageLoaded = true
                                }
                            }
                    }
                    // RSVP overlay if not calendar and user is going or hosting
                    if type != .calendar && imageLoaded {
                        // Use Firebase Auth current user ID for comparison
                        let currentUserId = Auth.auth().currentUser?.uid ?? ""
                        
                        if event.hostId == currentUserId {
                            // Show hosting overlay for event hosts
                            Rectangle()
                                .fill(Color.black.opacity(0.25))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            VStack {
                                Spacer()
                                Text("you're hosting!")
                                    .font(.LibreBodoniBold(size: 18))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                                Spacer()
                            }
                            .opacity(imageLoaded ? 1 : 0)
                            .animation(.easeIn(duration: 0.3), value: imageLoaded)
                        } else if event.rsvpStatus == "GOING" {
                            // Show going overlay for non-host attendees
                            Rectangle()
                                .fill(Color.black.opacity(0.25))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            VStack {
                                Spacer()
                                Text("you're going!")
                                    .font(.LibreBodoniBold(size: 18))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                                Spacer()
                            }
                            .opacity(imageLoaded ? 1 : 0)
                            .animation(.easeIn(duration: 0.3), value: imageLoaded)
                        }
                    }
                    // Date label overlay (top left, not for calendar type)
                    if type != .calendar {
                        HStack {
                            if let dateLabel = formattedDateLabel(event.date) {
                                Text(dateLabel)
                                    .font(.LibreBodoniBold(size: 14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 2)
                                    .background(Colors.primaryDark)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.top, 10)
                                    .padding(.leading, 8)
                            }
                            Spacer()
                        }
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
                    Text("hosted by")
                        .font(.LibreBodoniSemiBold(size: 13))
                        .foregroundColor(.black)
                    Text(event.hostName)
                        .font(.LibreBodoniSemiBold(size: 13))
                        .foregroundColor(Colors.primaryDark)
                    if type != .cove {
                        Text("@")
                            .font(.LibreBodoniSemiBold(size: 13))
                            .foregroundColor(.black)
                        Text(event.coveName)
                        .font(.LibreBodoniSemiBold(size: 13))
                        .foregroundColor(Colors.primaryDark)
                    }
                    // TODO: only checkmark if host is verified
                    // This may require backend changes
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(Colors.primaryDark)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 2)
                .padding(.top, 1)

                // Location and time for calendar type
                if type == .calendar {
                    HStack(spacing: 24) {
                        HStack(spacing: 6) {
                            Image("location-pin")
                                .foregroundColor(Colors.primaryDark)
                            Text(firstLocationPart(event.location))
                                .font(.LibreBodoniSemiBold(size: 13))
                                .foregroundColor(.black)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .foregroundColor(Colors.primaryDark)
                            Text(formattedTime(event.date))
                                .font(.LibreBodoniSemiBold(size: 13))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.top, 6)
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(.vertical, 5)

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
    /// Returns the first part of the location for display
    private func firstLocationPart(_ location: String?) -> String {
        guard let location = location else { return "" }
        let parts = location.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        // Heuristic: return the first segment that DOES NOT contain digits (avoids street numbers)
        // and is not empty. If none found, fallback to the first segment.
        for part in parts {
            if part.rangeOfCharacter(from: CharacterSet.decimalDigits) == nil && !part.isEmpty {
                return part
            }
        }
        return parts.first ?? ""
    }
    /// Returns the formatted time for display
    private func formattedTime(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: dateString) else { return "" }
        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "h:mm a"
        return labelFormatter.string(from: date)
    }
} 