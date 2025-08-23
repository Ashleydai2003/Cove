//
//  CoveHeaderView.swift
//  Cove
//
//  Created by Ashley Dai on 7/1/25.
//

import SwiftUI
import Kingfisher

/// CoveHeaderView: Reusable component for displaying cove header information
/// - Shows back button, cove cover photo, name, member count, and description
/// - Long press to refresh cove details
struct CoveHeaderView: View {
    let cove: FeedCoveDetails
    let onBackTapped: () -> Void
    let isRefreshing: Bool
    let onRefresh: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Cove header with back button and cover photo
            HStack(alignment: .top) {
                Button {
                    onBackTapped()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Colors.primaryDark)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .padding(.top, 8)
                .padding(.leading, 8)

                Spacer()

                // Show loading indicator when refreshing cove details
                if isRefreshing {
                    ProgressView()
                        .tint(Colors.primaryDark)
                        .frame(maxWidth: 100, maxHeight: 100)
                } else {
                    // Cove cover photo using Kingfisher
                    if let urlString = cove.coverPhoto?.url, let url = URL(string: urlString) {
                        KFImage(url)
                            .placeholder {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 100, height: 100)
                            }
                            .onSuccess { result in }
                            .resizable()
                            .scaleFactor(UIScreen.main.scale)
                            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 100 * UIScreen.main.scale, height: 100 * UIScreen.main.scale)))
                            .fade(duration: 0.2)
                            .cacheOriginalImage()
                            .cancelOnDisappear(true)
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image("default_cove_pfp")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, -8)

            Text(cove.name.isEmpty ? "untitled" : cove.name)
                .foregroundStyle(Colors.primaryDark)
                .font(.LibreBodoniBold(size: 26))
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            if let description = cove.description {
                Text(description)
                    .foregroundStyle(Colors.k292929)
                    .font(.LibreBodoni(size: 14))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            // Long press to refresh cove details
            Task {
                await onRefresh()
            }
        }
    }
}

#Preview {
    CoveHeaderView(
        cove: FeedCoveDetails(
            id: "1",
            name: "Sample Cove",
            description: "This is a sample cove description",
            location: "New York",
            creator: FeedCoveDetails.Creator(id: "1", name: "John Doe"),
            coverPhoto: nil,
            stats: FeedCoveDetails.Stats(memberCount: 42, eventCount: 5)
        ),
        onBackTapped: {},
        isRefreshing: false,
        onRefresh: {}
    )
}
