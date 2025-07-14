//
//  PersonalizeProfile.swift
//  Cove
//
//  Created by Nesib Muhedin


import SwiftUI

struct ProfilePicAndPhotosView: View {
    @EnvironmentObject var appController: AppController

    // MARK: – Image state
    @State private var mainImage: UIImage?
    @State private var extraImages: [UIImage?] = [nil, nil]
    @State private var processingImage: PickerType?
    @State private var uploadMessages: [PickerType: String] = [:]
    @State private var isProcessing = false

    // MARK: - Loading View Component
    private struct LoadingImageView: View {
        let isCircle: Bool
        let size: CGSize
        let message: String?
        
        var body: some View {
            ZStack {
                if isCircle {
                    Circle()
                        .fill(Colors.f3f3f3)
                        .frame(width: size.width, height: size.height)
                        .overlay(Circle().stroke(Color.black, lineWidth: 0.5))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Colors.f3f3f3)
                        .frame(width: size.width, height: size.height)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 0.5)
                        )
                }
                if let message = message {
                    Text(message)
                        .font(.LeagueSpartan(size: 12))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                } else {
                    ProgressView()
                }
            }
        }
    }

    // Which picker is active
    @State private var showingPickerFor: PickerType?
    enum PickerType: Identifiable, Hashable {
        case main, extra(Int)
        var id: Int {
            switch self {
            case .main: return -1
            case .extra(let idx): return idx
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .main:
                hasher.combine(-1)
            case .extra(let idx):
                hasher.combine(idx)
            }
        }
        
        static func == (lhs: PickerType, rhs: PickerType) -> Bool {
            switch (lhs, rhs) {
            case (.main, .main):
                return true
            case (.extra(let l), .extra(let r)):
                return l == r
            default:
                return false
            }
        }
    }

    // MARK: – Upload state
    @State private var isUploading = false
    @State private var uploadMessage: String?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Colors.faf8f4.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Back + Title block (leading)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Button { appController.path.removeLast() } label: {
                                Images.backArrow
                            }
                            Spacer()
                        }
                        .padding(.top, 10)

                        Text("personalize your")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 34))
                        Text("profile")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 34))

                        Text("add a profile pic and additional photos to show off your vibe")
                            .foregroundStyle(.black)
                            .font(.LeagueSpartan(size: 12))
                    }
                    .padding(.horizontal, 20)

                    // Centered image pickers
                    VStack(spacing: 20) {
                        // Main circle centered
                        Button {
                            showingPickerFor = .main
                        } label: {
                            if processingImage == .main {
                                LoadingImageView(isCircle: true, size: CGSize(width: 160, height: 160), message: nil)
                            } else if let message = uploadMessages[.main] {
                                LoadingImageView(isCircle: true, size: CGSize(width: 160, height: 160), message: message)
                            } else if let img = mainImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 160, height: 160)
                                    .clipShape(Circle())
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Colors.f3f3f3)
                                        .frame(width: 160, height: 160)
                                        .overlay(Circle().stroke(Color.black, lineWidth: 0.5))
                                    Text("+")
                                        .font(.system(size: 30))
                                        .foregroundColor(.black)
                                }
                            }
                        }

                        // Two extra slots
                        HStack(spacing: 20) {
                            ForEach(0..<2) { idx in
                                Button {
                                    showingPickerFor = .extra(idx)
                                } label: {
                                    if processingImage == .extra(idx) {
                                        LoadingImageView(isCircle: false, size: CGSize(width: 150, height: 250), message: nil)
                                    } else if let message = uploadMessages[.extra(idx)] {
                                        LoadingImageView(isCircle: false, size: CGSize(width: 150, height: 250), message: message)
                                    } else if let img = extraImages[idx] {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 150, height: 250)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } else {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Colors.f3f3f3)
                                                .frame(width: 150, height: 250)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.black, lineWidth: 0.5)
                                                )
                                            Text("+")
                                                .font(.system(size: 30))
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)

                    Spacer()

                    // Next (smiley)
                    HStack {
                        Spacer()
                        Images.smily
                            .resizable()
                            .frame(width: 52, height: 52)
                            .padding(.trailing, 20)
                            .onTapGesture {
                                appController.path.append(.pluggingIn)
                            }
                    }
                }
                .safeAreaPadding()
            }
            .sheet(item: $showingPickerFor) { picker in
                ImagePicker(image: binding(for: picker))
            }
            // iOS 17 two‐param onChange
            .onChange(of: mainImage) { old, new in
                if let img = new {
                    processingImage = .main
                    uploadMessages.removeValue(forKey: .main)
                    // Simulate a small delay to show loading state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        processingImage = nil
                        Onboarding.storeProfilePic(img)
                    }
                }
            }
            .onChange(of: extraImages) { old, new in
                for (idx, img) in new.enumerated() {
                    // only process newly set images
                    if img != old[idx], let ui = img {
                        processingImage = .extra(idx)
                        uploadMessages.removeValue(forKey: .extra(idx))
                        // Simulate a small delay to show loading state
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            processingImage = nil
                            Onboarding.storeExtraPic(ui, at: idx)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
    }

    // MARK: – Helpers

    private func binding(for picker: PickerType) -> Binding<UIImage?> {
        switch picker {
        case .main:       return $mainImage
        case .extra(let i): return $extraImages[i]
        }
    }

    /// Uploads an image to the server.
    /// - Note: Image processing and network upload are performed on a background thread to maintain UI responsiveness.
    /// UI updates are automatically dispatched back to the main thread.
    /// - Parameters:
    ///   - uiImage: The image to upload
    ///   - isProfile: Whether this is the main profile picture
    private func uploadImage(_ uiImage: UIImage, isProfile: Bool) {
        let pickerType: PickerType = isProfile ? .main : .extra(extraImages.firstIndex(where: { $0 == uiImage }) ?? 0)
        
        // Move image processing to background thread to prevent UI blocking
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = uiImage.jpegData(compressionQuality: 0.8) else { return }
            
            // Network upload also happens on background thread
            UserImage.upload(imageData: data, isProfilePic: isProfile) { result in
                // Update UI state on main thread to ensure thread safety
                DispatchQueue.main.async {
                    switch result {
                    case .success(let resp):
                        uploadMessages[pickerType] = resp.message
                    case .failure(let err):
                        uploadMessages[pickerType] = "Upload error: \(err.localizedDescription)"
                    }
                }
            }
        }
    }
}

// Preview
#Preview {
    ProfilePicView()
        .environmentObject(AppController.shared)
}
