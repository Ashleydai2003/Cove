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
    @EnvironmentObject var appController: AppController
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewPostModel()

    @FocusState private var isFocused: Bool

    var onPostCreated: (() -> Void)? = nil

    // MARK: - Initializer
    init(coveId: String? = nil, onPostCreated: (() -> Void)? = nil) {
        self.coveId = coveId
        self.onPostCreated = onPostCreated
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()

            VStack {
                HStack {
                    Button("cancel") { dismiss() }
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(Colors.primaryDark)
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)

                headerView

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        postContentSection
                        createButtonView
                    }
                    .padding(.horizontal, 32)
                }

                Spacer(minLength: 24)
            }
            .padding(.top, 50)
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                keyboardAccessoryView
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            if let coveId = coveId {
                viewModel.coveId = coveId
            }
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
        VStack {
            HStack(alignment: .top) {
                Spacer()

                Image("post_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.leading, -10)

                Spacer()
            }
            .padding(.horizontal, 16)

            Text("create a post")
                .font(.Lugrasimo(size: 35))
                .foregroundColor(Colors.primaryDark)
        }
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
                    .frame(minHeight: 250)
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
        Button {
            viewModel.submitPost { success in
                if success {
                    // Refresh cove posts to show the new post
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
                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Colors.background)
                    )
            } else {
                Text("post")
                    .foregroundStyle(!viewModel.isFormValid ? Color.gray : Color.black)
                    .font(.LibreBodoniBold(size: 16))
                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(!viewModel.isFormValid ? Color.gray.opacity(0.3) : Colors.background)
                    )
            }
        }
        .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
        .padding(.top, 40)
    }

    // MARK: - Keyboard Accessory
    private var keyboardAccessoryView: some View {
        HStack {
            Spacer()
            Button("Done") {
                isFocused = false
            }
            .padding(.trailing, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6))
    }
}

#Preview {
    CreatePostView(coveId: nil)
} 