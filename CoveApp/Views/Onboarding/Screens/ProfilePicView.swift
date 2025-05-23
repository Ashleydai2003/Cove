//
//  PersonalizeProfile.swift
//  Cove
//

import SwiftUI

struct ProfilePicView: View {
    @EnvironmentObject var appController: AppController

    // MARK: – Image state
    @State private var mainImage: UIImage?
    @State private var extraImages: [UIImage?] = [nil, nil]

    // Which picker is active
    @State private var showingPickerFor: PickerType?
    enum PickerType: Identifiable {
        case main, extra(Int)
        var id: Int {
            switch self {
            case .main: return -1
            case .extra(let idx): return idx
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
                            if let img = mainImage {
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
                                    if let img = extraImages[idx] {
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
                                // MARK: - Upload profile pics
                                // TODO: make upload profile pics request api
                                appController.path.append(.mutuals)
                            }
                    }

                    // Upload status
                    if isUploading {
                        HStack {
                            ProgressView()
                            Text("Uploading…")
                                .font(.LeagueSpartan(size: 12))
                                .foregroundStyle(.black)
                        }
                        .padding(.top, 10)
                    } else if let msg = uploadMessage {
                        Text(msg)
                            .font(.LeagueSpartan(size: 12))
                            .foregroundStyle(.black)
                            .padding(.top, 10)
                    }
                }
                .safeAreaPadding()
            }
            .sheet(item: $showingPickerFor) { picker in
                ImagePicker(image: binding(for: picker))
            }
            // iOS 17 two‐param onChange
            .onChange(of: mainImage) { old, new in
                if let img = new { uploadImage(img, isProfile: true) }
            }
            .onChange(of: extraImages) { old, new in
                for (idx, img) in new.enumerated() {
                    // only upload newly set images
                    if img != old[idx], let ui = img {
                        let isProfile = false
                        uploadImage(ui, isProfile: isProfile)
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

    private func uploadImage(_ uiImage: UIImage, isProfile: Bool) {
        guard let data = uiImage.jpegData(compressionQuality: 0.8) else { return }
        isUploading = true
        uploadMessage = nil

        UserImage.upload(imageData: data, isProfilePic: isProfile) { result in
            isUploading = false
            switch result {
            case .success(let resp):
                uploadMessage = resp.message
            case .failure(let err):
                uploadMessage = "Upload error: \(err.localizedDescription)"
            }
        }
    }
}

// Preview
#Preview {
    ProfilePicView()
        .environmentObject(AppController.shared)
}
