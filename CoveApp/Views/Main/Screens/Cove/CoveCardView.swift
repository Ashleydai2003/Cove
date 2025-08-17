import SwiftUI
import Kingfisher

struct CoveCardView: View {
    let cove: Cove
    @EnvironmentObject var appController: AppController

    var body: some View {
        NavigationLink(value: cove.id) {
            HStack(alignment: .center, spacing: 16) {
                // Cove cover photo using Kingfisher for caching and smooth loading
                if let urlString = cove.coverPhoto?.url, let url = URL(string: urlString) {
                    KFImage(url)
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .onSuccess { result in
                        }
                        .resizable()
                        .scaleFactor(UIScreen.main.scale)
                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 80 * UIScreen.main.scale, height: 80 * UIScreen.main.scale)))
                        .fade(duration: 0.2)
                        .cacheOriginalImage()
                        .loadDiskFileSynchronously()
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(cove.name)
                        .font(.LibreBodoniBold(size: 16))
                        .foregroundColor(Colors.primaryDark)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                    // Optionally add subtitle/description here if available
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(Color.clear)
        }
        .onAppear {
            appController.coveFeed.preloadCoveDetails(for: cove.id)
        }
    }
}
