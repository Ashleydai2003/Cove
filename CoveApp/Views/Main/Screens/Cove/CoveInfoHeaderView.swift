//
//  CoveInfoHeaderView.swift
//  Cove
//
//  A compact cove info header with a smaller square photo, centered name and description,
//  and a simple back button. Long press anywhere on the header to refresh cove details.
//

import SwiftUI
import Kingfisher

struct CoveInfoHeaderView: View {
    let cove: FeedCoveDetails
    let onBackTapped: () -> Void
    let isRefreshing: Bool
    let onRefresh: () async -> Void
    var onSettingsTapped: () -> Void = {}

    var body: some View {
        VStack(spacing: 6) {
            TopIconBar(showBackArrow: true, showGear: true, onBackTapped: onBackTapped, onGearTapped: onSettingsTapped)

            // Image or spinner
            Group {
                if isRefreshing {
                    ProgressView()
                        .tint(Colors.primaryDark)
                        .frame(width: 80, height: 80)
                } else {
                    if let urlString = cove.coverPhoto?.url, let url = URL(string: urlString) {
                        KFImage(url)
                            .placeholder {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .onSuccess { _ in }
                            .resizable()
                            .scaleFactor(UIScreen.main.scale)
                            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 80 * UIScreen.main.scale, height: 80 * UIScreen.main.scale)))
                            .fade(duration: 0.2)
                            .cacheOriginalImage()
                            .cancelOnDisappear(true)
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image("default_cove_pfp")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            // reduce extra top padding to bring image closer to the back arrow

            // Name
            Text(cove.name.isEmpty ? "untitled" : cove.name)
                .foregroundStyle(Colors.primaryDark)
                .font(.LibreBodoniBold(size: 24))
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            // Description
            if let description = cove.description, !description.isEmpty {
                Text(description)
                    .foregroundStyle(Colors.k292929)
                    .font(.LibreBodoni(size: 14))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.top, -4)
        .padding(.bottom, 4)
        .background(Colors.background)
        .onLongPressGesture(minimumDuration: 1.0) {
            Task { await onRefresh() }
        }
    }
}

// MARK: - Press Tint Style
private struct TintOnPressIconStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(Colors.primaryDark.opacity(configuration.isPressed ? 0.5 : 1.0))
    }
}

#Preview {
    CoveInfoHeaderView(
        cove: FeedCoveDetails(
            id: "1",
            name: "Sample Cove",
            description: "A short description about this cove appears here.",
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


