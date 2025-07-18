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
                    Images.backArrow
                }
                .padding(.top, 16)

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
                                    .frame(maxWidth: 100, maxHeight: 100)
                                    .overlay(ProgressView().tint(.gray))
                            }
                            .onSuccess { result in
                            }
                            .resizable()
                            .fade(duration: 0.2)
                            .cacheOriginalImage()
                            .loadDiskFileSynchronously()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(maxWidth: 100, maxHeight: 100)
                            .clipShape(Circle())
                    } else {
                        Image("default_cove_pfp")
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(maxWidth: 100, maxHeight: 100)
                            .clipShape(Circle())
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)

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
