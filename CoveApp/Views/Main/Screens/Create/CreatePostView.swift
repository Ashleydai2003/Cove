//
//  CreatePostView.swift
//  Cove
//
//  Created by Assistant

import SwiftUI

// MARK: - Main View
struct CreatePostView: View {
    // MARK: - Properties
    let coveId: String?
    let coveName: String?
    @EnvironmentObject var appController: AppController
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewPostModel()

    @FocusState private var isFocused: Bool

    var onPostCreated: (() -> Void)? = nil

    // MARK: - Initializer
    init(coveId: String? = nil, coveName: String? = nil, onPostCreated: (() -> Void)? = nil) {
        self.coveId = coveId
        self.coveName = coveName
        self.onPostCreated = onPostCreated
    }

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .topLeading) {
            Colors.background.ignoresSafeArea()

            // Close button (SF Symbols x)
            Button(action: { if !viewModel.isSubmitting { dismiss() } }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(viewModel.isSubmitting ? .gray : Colors.primaryDark)
            }
            .padding(.leading, 20)
            .padding(.top, 18)
            .disabled(viewModel.isSubmitting)

            VStack(spacing: 16) {
                headerView

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        postContentSection
                    }
                    .padding(.horizontal, 32)
                }
            }
            .padding(.top, 28)
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            if let coveId = coveId {
                viewModel.coveId = coveId
            }
        }
        .safeAreaInset(edge: .bottom) {
            createButtonView
                .background(Colors.background)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - View Components
extension CreatePostView {
    // MARK: - Header
    private var headerView: some View {
        let target = (coveName ?? coveId) ?? "this cove"
        return VStack(spacing: 8) {
            HStack(spacing: 4) {
                Spacer()
                Text("posting to")
                    .font(.LibreBodoni(size: 18))
                    .foregroundColor(.gray)
                Text("\(target) ✏️")
                    .font(.LibreBodoni(size: 18))
                    .foregroundColor(Colors.primaryDark)
                Spacer()
            }
            .padding(.top, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Post Content Section
    private var postContentSection: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )

                ZStack(alignment: .topLeading) {
                    if viewModel.content.isEmpty {
                        Text("share your thoughts...")
                            .foregroundColor(Color.black.opacity(0.35))
                            .font(.LibreBodoni(size: 16))
                            .padding(.top, 12)
                            .padding(.leading, 14)
                    }

                    TextEditor(text: $viewModel.content)
                        .foregroundStyle(Colors.primaryDark)
                        .font(.LibreBodoni(size: 16))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 160, maxHeight: 220)
                        .focused($isFocused)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 230)
            .padding(.top, 12)
            
            // Character counter
            HStack {
                Spacer()
                Text("\(viewModel.content.count)/1000")
                    .font(.LibreBodoniSemiBold(size: 12))
                    .foregroundColor(viewModel.content.count > 1000 ? .red : .gray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .background(Colors.background)
    }

    // MARK: - Create Button
    private var createButtonView: some View {
        VStack {
            Button {
                isFocused = false
                viewModel.submitPost { success in
                    if success {
                        if !viewModel.coveId.isEmpty {
                            appController.refreshCoveAfterPostCreation(coveId: viewModel.coveId)
                        }
                        onPostCreated?()
                        dismiss()
                    }
                }
            } label: {
                if viewModel.isSubmitting {
                    ProgressView()
                        .tint(Colors.background)
                        .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56, alignment: .center)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Colors.primaryDark)
                        )
                } else {
                    Text("post")
                        .foregroundStyle(!viewModel.isFormValid ? Color.gray : Colors.background)
                        .font(.LibreBodoniBold(size: 16))
                        .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56, alignment: .center)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(!viewModel.isFormValid ? Color.gray.opacity(0.3) : Colors.primaryDark)
                        )
                }
            }
            .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
    }
}

#Preview {
    CreatePostView(coveId: nil, coveName: nil)
} 