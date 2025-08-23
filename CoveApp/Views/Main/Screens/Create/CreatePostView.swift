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
        ZStack(alignment: .topTrailing) {
            Colors.background.ignoresSafeArea()

            // Cancel button top-right
            Button(action: { if !viewModel.isSubmitting { dismiss() } }) {
                Text("cancel")
                    .font(.LibreBodoni(size: 16))
                    .foregroundColor(viewModel.isSubmitting ? .gray : Colors.primaryDark)
            }
            .padding(.trailing, 20)
            .padding(.top, 12)
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
            .padding(.top, 24)
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
            Text("post to \(target) ✏️")
                .font(.Lugrasimo(size: 28))
                .foregroundColor(Colors.primaryDark)
                .multilineTextAlignment(.center)
                .padding(.top, 32)

            Text("posting to \(target)")
                .font(.LibreBodoni(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Post Content Section
    private var postContentSection: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                if viewModel.content.isEmpty {
                    Text("share your thoughts...")
                        .foregroundColor(.gray)
                        .font(.LibreBodoniSemiBold(size: 16))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }

                TextEditor(text: $viewModel.content)
                    .foregroundColor(.black)
                    .font(.LibreBodoniSemiBold(size: 16))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 220)
                    .focused($isFocused)
            }
            .padding(16)
            
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
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black, lineWidth: 1)
        )
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
                        .tint(.black)
                        .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56, alignment: .center)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Colors.background)
                        )
                } else {
                    Text("post")
                        .foregroundStyle(!viewModel.isFormValid ? Color.gray : Color.black)
                        .font(.LibreBodoniBold(size: 16))
                        .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56, alignment: .center)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(!viewModel.isFormValid ? Color.gray.opacity(0.3) : Colors.background)
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