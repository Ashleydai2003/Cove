//
//  CreateCoveView.swift
//  Cove
//
//  Created by Assistant


import SwiftUI

// MARK: - Main View
struct CreateCoveView: View {
    // MARK: - Properties
    @EnvironmentObject var appController: AppController
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewCoveModel()
    
    @FocusState private var isFocused: Bool
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
    
            VStack {
                headerView
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        coveNameSection
                        descriptionSection
                        imagePickerSection
                        locationSection
                        createButtonView
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer(minLength: 24)
            }
            .padding(.top, 50)
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(image: $viewModel.coverPhoto)
        }
        .sheet(isPresented: $viewModel.showLocationPicker) {
            LocationSearchView(completion: { location in
                viewModel.location = location
            })
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                keyboardAccessoryView
            }
        }
        .navigationBarBackButtonHidden()
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
extension CreateCoveView {
    // MARK: - Header
    private var headerView: some View {
        VStack {
            HStack(alignment: .top) {
                Spacer()
                
                Image("confetti-dark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.leading, -10)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            Text("create a cove")
                .font(.Lugrasimo(size: 35))
                .foregroundColor(Colors.primaryDark)
        }
    }
    
    // MARK: - Cove Name Section
    private var coveNameSection: some View {
        VStack {
            ZStack(alignment: .center) {
                if viewModel.name.isEmpty {
                    Text("untitled cove")
                        .foregroundColor(.white)
                        .font(.LibreBodoniBold(size: 22))
                }
                
                TextField("untitled cove", text: $viewModel.name)
                    .foregroundStyle(Color.white)
                    .font(.LibreBodoniBold(size: 22))
                    .multilineTextAlignment(.center)
                    .autocorrectionDisabled()
                    .focused($isFocused)
            }
            .padding(16)
        }
        .background(Colors.primaryDark)
        .cornerRadius(10)
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                if viewModel.description.isEmpty {
                    Text("describe your cove...")
                        .foregroundColor(.gray)
                        .font(.LibreBodoni(size: 16))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                
                TextEditor(text: $viewModel.description)
                    .foregroundStyle(Color.black)
                    .font(.LibreBodoni(size: 16))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80, maxHeight: 120)
                    .focused($isFocused)
            }
            .padding(12)
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black, lineWidth: 1)
        )
        .padding(.top, 8)
    }
    
    // MARK: - Image Picker Section
    private var imagePickerSection: some View {
        Button {
            viewModel.showImagePicker = true
        } label: {
            ZStack {
                if viewModel.coverPhoto == nil {
                    Text("cover photo (optional)")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(Colors.primaryDark)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Image(uiImage: viewModel.coverPhoto ?? UIImage())
                    .resizable()
                    .scaledToFill()
                    .frame(width: AppConstants.SystemSize.width-64, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .frame(height: 200)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 1)
            )
        }
        .padding(.top, 16)
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        Button {
            viewModel.showLocationPicker = true
        } label: {
            HStack {
                Image(systemName: "location")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 24)
                
                Text("location")
                    .foregroundStyle(Color.white)
                    .font(.LibreBodoniBold(size: 16))
                    .padding(.leading, 16)
                
                Spacer()
                
                Text(viewModel.location ?? "")
                    .foregroundStyle(Color.white)
                    .font(.LibreBodoniBold(size: 16))
                    .lineLimit(2)
                    .padding(.trailing, 24)
            }
            .frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Colors.primaryDark)
            )
        }
        .padding(.top, 16)
    }
    
    // MARK: - Create Button
    private var createButtonView: some View {
        Button {
            viewModel.submitCove { success in
                if success {
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
                            .fill(Color.white)
                    )
            } else {
                Text("create")
                    .foregroundStyle(!viewModel.isFormValid ? Color.gray : Color.black)
                    .font(.LibreBodoniBold(size: 16))
                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(!viewModel.isFormValid ? Color.gray.opacity(0.3) : Color.white)
                    )
            }
        }
        .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
        .padding(.top, 24)
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
    CreateCoveView()
        .environmentObject(AppController.shared)
} 