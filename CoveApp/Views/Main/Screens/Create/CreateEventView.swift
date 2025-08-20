//
//  CreateEventView.swift
//  Cove
//
//  Created by Nesib Muhedin

import SwiftUI

struct CustomDatePickerStyle: DatePickerStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.white)
            .font(.LibreBodoniBold(size: 16))
            .padding(.trailing, 24)
    }
}

extension DatePickerStyle where Self == CustomDatePickerStyle {
    static var custom: CustomDatePickerStyle { .init() }
}

// MARK: - Main View
struct CreateEventView: View {
    // MARK: - Properties
    let coveId: String?
    @EnvironmentObject var appController: AppController
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewEventModel()

    @FocusState private var isFocused: Bool

    var onEventCreated: (() -> Void)? = nil

    // MARK: - Initializer
    init(coveId: String? = nil, onEventCreated: (() -> Void)? = nil) {
        self.coveId = coveId
        self.onEventCreated = onEventCreated
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()

            VStack {
                // In-content Cancel aligned with other sections
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
                        eventNameSection
                        imagePickerSection
                        dateTimeSection
                        locationSection
                        spotsSection
                        // TODO: in the future we also want to have a privacy section
                        createButtonView
                    }
                    .padding(.horizontal, 32)
                }

                Spacer(minLength: 24)
            }
            .padding(.top, 50)
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(image: $viewModel.eventImage)
        }
        .sheet(isPresented: $viewModel.showLocationPicker) {
            LocationSearchView(completion: { location in
                viewModel.location = location
            })
        }
        .sheet(isPresented: $viewModel.showDatePicker) {
            DatePicker("", selection: $viewModel.eventDate, in: Date()..., displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .presentationDetents([.height(400)])
        }
        .sheet(isPresented: $viewModel.showTimePicker) {
            DatePicker("", selection: $viewModel.eventTime, displayedComponents: [.hourAndMinute])
                .datePickerStyle(.wheel)
                .presentationDetents([.height(200)])
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
extension CreateEventView {
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

            Text("host an event")
                .font(.Lugrasimo(size: 35))
                .foregroundColor(Colors.primaryDark)
        }
    }

    // MARK: - Event Name Section
    private var eventNameSection: some View {
        VStack {
            ZStack(alignment: .center) {
                if viewModel.eventName.isEmpty {
                    Text("untitled event")
                        .foregroundColor(.white)
                        .font(.LibreBodoniBold(size: 22))
                }

                TextField("untitled event", text: $viewModel.eventName)
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

// MARK: - Image Picker Section
    private var imagePickerSection: some View {
        Button {
            viewModel.showImagePicker = true
        } label: {
            ZStack {
                if viewModel.eventImage == nil {
                    Text("image")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(Colors.primaryDark)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Image(uiImage: viewModel.eventImage ?? UIImage())
                    .resizable()
                    .scaledToFill()
                    .frame(width: AppConstants.SystemSize.width-64, height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .frame(height: 250)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 1)
            )
        }
        .padding(.top, 16)
    }

    // MARK: - Date & Time Section
    private var dateTimeSection: some View {
        VStack(spacing: 8) {
            chooseDateView
            chooseTimeView
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
    }

    // MARK: - Number of Spots Section
    private var spotsSection: some View {
        numberOfSpotsView
    }

    // MARK: - Create Button
    private var createButtonView: some View {
        Button {
            viewModel.submitEvent { success in
                if success {
                    // Refresh calendar and upcoming feeds to show the new event
                    appController.refreshFeedsAfterEventCreation()
                    // If event was created in a specific cove, refresh that cove's data too
                    if !viewModel.coveId.isEmpty {
                        appController.refreshCoveAfterEventCreation(coveId: viewModel.coveId)
                    }
                    onEventCreated?()
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

    // MARK: - Date Picker
    private var chooseDateView: some View {
        Button {
            viewModel.showDatePicker = true
        } label: {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 24)

                Text("set a date")
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 16)

                Spacer()

                Text(viewModel.eventDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundStyle(Color.white)
                    .padding(.trailing, 24)
            }
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Colors.primaryDark)
            )
        }
    }

    // MARK: - Time Picker
    private var chooseTimeView: some View {
        Button {
            viewModel.showTimePicker = true
        } label: {
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 24)

                Text("time")
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 16)

                Spacer()

                Text(viewModel.eventTime.formatted(date: .omitted, time: .shortened))
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundStyle(Color.white)
                    .padding(.trailing, 24)
            }
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Colors.primaryDark)
            )
        }
    }

    // MARK: - Number of Spots Input
    private var numberOfSpotsView: some View {
        HStack {
            Image(systemName: "person.3")
                .font(.system(size: 20))
                .foregroundStyle(Color.white)
                .padding(.leading, 15)

            ZStack(alignment: .leading) {
                if viewModel.numberOfSpots.isEmpty {
                    Text("number of spots")
                        .foregroundColor(.gray)
                        .font(.LibreBodoniBold(size: 16))
                        .padding(.leading, 6)
                }

                TextField("", text: $viewModel.numberOfSpots)
                    .foregroundStyle(Color.white)
                    .font(.LibreBodoniBold(size: 16))
                    .padding(.leading, 6)
                    .padding(.trailing, 24)
                    .autocorrectionDisabled()
                    .keyboardType(.numberPad)
                    .focused($isFocused)
            }
        }
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Colors.primaryDark)
        )
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
    CreateEventView(coveId: nil)
}
