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
    @FocusState private var isAddressFocused: Bool
    @StateObject private var addressVM = LocationSearchViewModel()
    @State private var showAddressInput = false
    @State private var showAddressDropdown = false
    @State private var searchAddress: String = ""
    private enum VisibilityOption: String, CaseIterable { case membersOnly, discoverable }
    @State private var visibility: VisibilityOption = .membersOnly

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
                headerView

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            eventNameSection
                            descriptionSection
                            imagePickerSection
                            dateTimeSection
                            locationSection
                                .id("locationSection")
                            spotsSection
                            visibilitySection
                            advancedOptionsSection
                            // TODO: in the future we also want to have a privacy section
                            createButtonView
                        }
                        .padding(.horizontal, 32)
                    }
                    .onChange(of: showAddressInput) { _, newValue in
                        if newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    proxy.scrollTo("locationSection", anchor: .center)
                                }
                            }
                        }
                    }
                    .onChange(of: isAddressFocused) { _, focused in
                        if focused {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    proxy.scrollTo("locationSection", anchor: .center)
                                }
                            }
                        }
                    }
                }

            }
            .padding(.top, 0)
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
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
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
        ZStack {
            // Center title (CreateCove style)
            Text("create an event 🎉")
                .font(.LibreBodoni(size: 18))
                .foregroundColor(Colors.primaryDark)

            // Leading action
            HStack {
                Button("cancel") { dismiss() }
                    .font(.LibreBodoni(size: 16))
                    .foregroundColor(Colors.primaryDark)
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Payment Handle Section
    private var paymentHandleSection: some View {
        HStack(spacing: 0) {
            Image(systemName: "at")
                .font(.system(size: 20))
                .foregroundStyle(Color.white)
                .padding(.leading, 24)

            ZStack(alignment: .leading) {
                if viewModel.paymentHandle.isEmpty {
                    Text("venmo handle")
                        .foregroundColor(Color.white)
                        .font(.LibreBodoniBold(size: 16))
                }

                TextField("", text: $viewModel.paymentHandle)
                    .keyboardType(.default)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundColor(Color.white)
                    .padding(.leading, 0)
                    .onChange(of: viewModel.paymentHandle) { _, newValue in
                        // Normalize: strip whitespace and leading '@'
                        var trimmed = newValue.replacingOccurrences(of: " ", with: "")
                        if trimmed.hasPrefix("@") {
                            trimmed.removeFirst()
                        }
                        viewModel.paymentHandle = trimmed
                    }
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)

            Spacer()
        }
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Colors.primaryDark)
        )
    }

    // MARK: - Event Name Section
    private var eventNameSection: some View {
        ZStack(alignment: .leading) {
            // Match CreateCoveView styling
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )

            ZStack(alignment: .leading) {
                if viewModel.eventName.isEmpty {
                    Text("name your event")
                        .foregroundColor(Color.black.opacity(0.35))
                        .font(.LibreBodoniBold(size: 20))
                        .padding(.horizontal, 14)
                }

                TextField("name your event", text: $viewModel.eventName)
                    .foregroundStyle(Colors.primaryDark)
                    .font(.LibreBodoniBold(size: 20))
                    .multilineTextAlignment(.leading)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Description Section
    private var descriptionSection: some View {
        ZStack(alignment: .topLeading) {
            // Match CreateCoveView description styling
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )

            ZStack(alignment: .topLeading) {
                if viewModel.descriptionText.isEmpty {
                    Text("describe your event...")
                        .foregroundColor(Color.black.opacity(0.35))
                        .font(.LibreBodoni(size: 16))
                        .padding(.top, 12)
                        .padding(.leading, 14)
                }
                TextEditor(text: $viewModel.descriptionText)
                    .foregroundStyle(Colors.primaryDark)
                    .font(.LibreBodoni(size: 16))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 96, maxHeight: 140)
                    .focused($isFocused)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
        }
        .padding(.top, 8)
    }

// MARK: - Image Picker Section
    private var imagePickerSection: some View {
        Button {
            viewModel.showImagePicker = true
        } label: {
            ZStack {
                // Background like CreateCoveView
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )

                if viewModel.eventImage == nil {
                    Text("choose a photo")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(Colors.primaryDark)
                } else {
                    Image(uiImage: viewModel.eventImage ?? UIImage())
                        .resizable()
                        .scaledToFill()
                        .frame(width: AppConstants.SystemSize.width-64, height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.12), lineWidth: 1)
                        )
                }
            }
            .frame(height: 250)
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
        VStack(spacing: 8) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Colors.primaryDark)
                    .frame(maxWidth: .infinity, minHeight: 46, maxHeight: .infinity, alignment: .leading)

                HStack(spacing: 0) {
                    Image(systemName: "location")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white)
                        .padding(.leading, 24)

                    if showAddressInput {
                        ZStack(alignment: .leading) {
                            if searchAddress.isEmpty {
                                Text("address")
                                    .foregroundColor(Color.white)
                                    .font(.LibreBodoniBold(size: 16))
                            }
                            TextField("", text: $searchAddress)
                                .font(.LibreBodoniBold(size: 16))
                                .foregroundColor(Color.white)
                                .keyboardType(.alphabet)
                                .focused($isAddressFocused)
                                .onChange(of: searchAddress) { oldValue, newValue in
                                    // Only trim leading and trailing whitespace, preserve internal spaces
                                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                    searchAddress = newValue // Keep the original input with spaces
                                    addressVM.searchQuery = trimmed
                                    showAddressDropdown = !trimmed.isEmpty
                                }
                        }
                        .padding(.leading, 16)
                        .padding(.trailing, 16)
                    } else {
                        HStack {
                            Text(viewModel.location?.isEmpty == false ? (viewModel.location ?? "") : "address")
                                .foregroundStyle(Color.white)
                                .font(.LibreBodoniBold(size: 16))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.leading, 16)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                showAddressInput = true
                                searchAddress = viewModel.location ?? ""
                            }
                            isAddressFocused = true
                            showAddressDropdown = !searchAddress.isEmpty
                        }
                        .padding(.trailing, 16)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if showAddressDropdown {
                let resultsCount = min(addressVM.searchResults.count, 5)
                VStack(spacing: 0) {
                    ForEach(0..<resultsCount, id: \.self) { idx in
                        let result = addressVM.searchResults[idx]
                        Button {
                            addressVM.selectLocation(completion: result) { location in
                                viewModel.location = location
                                searchAddress = ""
                                showAddressDropdown = false
                                showAddressInput = false
                                isAddressFocused = false
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.title)
                                        .font(.LibreBodoni(size: 16))
                                        .foregroundColor(Colors.background)
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle)
                                            .font(.LeagueSpartan(size: 14))
                                            .foregroundColor(Colors.background.opacity(0.8))
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        .background(Colors.primaryDark)

                        if idx < resultsCount - 1 {
                            Divider().background(Colors.background.opacity(0.15))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
        }
    }

    // MARK: - Ticket Price Section
    private var ticketPriceSection: some View {
        HStack(spacing: 0) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 20))
                .foregroundStyle(Color.white)
                .padding(.leading, 24)

            ZStack(alignment: .leading) {
                if viewModel.ticketPriceString.isEmpty {
                    Text("ticket price")
                        .foregroundColor(Color.white)
                        .font(.LibreBodoniBold(size: 16))
                }

                TextField("", text: $viewModel.ticketPriceString)
                    .keyboardType(.decimalPad)
                    .autocorrectionDisabled()
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundColor(Color.white)
                    .padding(.leading, 0)
                    .onChange(of: viewModel.ticketPriceString) { _, newValue in
                        viewModel.ticketPriceString = viewModel.validateTicketPriceInput(newValue)
                    }
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)

            Spacer()
        }
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Colors.primaryDark)
        )
    }

    // MARK: - Number of Spots Section
    private var spotsSection: some View {
        numberOfSpotsView
    }

    // MARK: - Visibility Section
    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                Button(action: { 
                    visibility = .membersOnly
                    viewModel.isPublic = false
                }) {
                    Text("Members only")
                        .font(.LibreBodoniBold(size: 16))
                        .foregroundStyle(visibility == .membersOnly ? Colors.background : Colors.primaryDark)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(visibility == .membersOnly ? Colors.primaryDark : Colors.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
                            )
                    )
                }

                Button(action: { 
                    visibility = .discoverable
                    viewModel.isPublic = true
                }) {
                    Text("Discoverable")
                        .font(.LibreBodoniBold(size: 16))
                        .foregroundStyle(visibility == .discoverable ? Colors.background : Colors.primaryDark)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(visibility == .discoverable ? Colors.primaryDark : Colors.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
                            )
                    )
                }
            }
            // Description below segmented buttons
            Text(visibility == .membersOnly ? "Only members of this Cove can RSVP." : "Visible in Discover, all Cove users can RSVP.")
                .font(.LibreBodoni(size: 12))
                .foregroundColor(.gray)
                .padding(.top, 6)
        }
    }

    // MARK: - Advanced Options Section
    private var advancedOptionsSection: some View {
        VStack(spacing: 12) {
            // Advanced Options Toggle
            Button(action: {
                viewModel.showAdvancedOptions.toggle()
            }) {
                HStack {
                    Text("Advanced Options")
                        .font(.LibreBodoniBold(size: 16))
                        .foregroundColor(Colors.primaryDark)
                    
                    Spacer()
                    
                    Image(systemName: viewModel.showAdvancedOptions ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Colors.primaryDark)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.12), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            
            // Advanced Options Content
            Group {
                if viewModel.showAdvancedOptions {
                    VStack(spacing: 16) {
                        // Payment Settings Section
                        paymentSettingsSection
                        
                        // Tiered Pricing Toggle
                        tieredPricingToggleSection
                        
                        // Tiered Pricing Options
                        Group {
                            if viewModel.useTieredPricing {
                                tieredPricingSection
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: viewModel.useTieredPricing)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.showAdvancedOptions)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Payment Settings Section
    private var paymentSettingsSection: some View {
        VStack(spacing: 12) {
            Text("Payment Settings")
                .font(.LibreBodoniBold(size: 16))
                .foregroundColor(Colors.primaryDark)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Payment Handle (always show)
                paymentHandleSection
                
                // Ticket Price (only show when not using tiered pricing)
                Group {
                    if !viewModel.useTieredPricing {
                        ticketPriceSection
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.useTieredPricing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Tiered Pricing Toggle Section
    private var tieredPricingToggleSection: some View {
        Button(action: {
            viewModel.useTieredPricing.toggle()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tiered Pricing")
                        .font(.LibreBodoniBold(size: 16))
                        .foregroundColor(Colors.primaryDark)
                    
                    Text("Set different prices for different ticket tiers")
                        .font(.LibreBodoni(size: 12))
                        .foregroundColor(Colors.primaryDark.opacity(0.7))
                }
                
                Spacer()
                
                Toggle("", isOn: $viewModel.useTieredPricing)
                    .toggleStyle(SwitchToggleStyle(tint: Colors.primaryDark))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Tiered Pricing Section
    private var tieredPricingSection: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Pricing Tiers")
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundColor(Colors.primaryDark)
                
                Spacer()
                
                Text("Configure different pricing levels")
                    .font(.LibreBodoni(size: 12))
                    .foregroundColor(Colors.primaryDark.opacity(0.7))
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 12) {
                // Early Bird Tier
                tieredPricingRow(
                    title: "Early Bird",
                    price: $viewModel.earlyBirdPrice,
                    spots: $viewModel.earlyBirdSpots,
                    icon: "clock.fill",
                    color: Colors.primaryDark
                )
                
                // Regular Tier
                tieredPricingRow(
                    title: "Regular",
                    price: $viewModel.regularPrice,
                    spots: $viewModel.regularSpots,
                    icon: "person.fill",
                    color: Colors.primaryDark
                )
                
                // Last Minute Tier
                tieredPricingRow(
                    title: "Last Minute",
                    price: $viewModel.lastMinutePrice,
                    spots: $viewModel.lastMinuteSpots,
                    icon: "exclamationmark.triangle.fill",
                    color: Colors.primaryDark
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Tiered Pricing Row
    private func tieredPricingRow(title: String, price: Binding<String>, spots: Binding<String>, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundColor(Colors.primaryDark)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Price Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Price")
                        .font(.LibreBodoni(size: 12))
                        .foregroundColor(Colors.primaryDark.opacity(0.7))
                    
                    HStack {
                        Text("$")
                            .font(.LibreBodoniBold(size: 16))
                            .foregroundColor(Colors.primaryDark)
                        
                        TextField("0.00", text: price)
                            .font(.LibreBodoniBold(size: 16))
                            .foregroundColor(Colors.primaryDark)
                            .keyboardType(.decimalPad)
                            .onChange(of: price.wrappedValue) { _, newValue in
                                price.wrappedValue = viewModel.validateTieredPriceInput(newValue)
                            }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Colors.primaryDark.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                // Spots Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Spots")
                        .font(.LibreBodoni(size: 12))
                        .foregroundColor(Colors.primaryDark.opacity(0.7))
                    
                        TextField("0", text: spots)
                            .font(.LibreBodoniBold(size: 16))
                            .foregroundColor(Colors.primaryDark)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .onChange(of: spots.wrappedValue) { _, newValue in
                                spots.wrappedValue = viewModel.validateTieredSpotsInput(newValue)
                            }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Colors.primaryDark.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                .frame(maxWidth: 80)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
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
                    .tint(Colors.background)
                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Colors.primaryDark)
                    )
            } else {
                Text("create")
                    .foregroundStyle(!viewModel.isFormValid ? Color.gray : Colors.background)
                    .font(.LibreBodoniBold(size: 16))
                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(!viewModel.isFormValid ? Color.gray.opacity(0.3) : Colors.primaryDark)
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

                Text(viewModel.eventDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 16)

                Spacer()
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

                Text(viewModel.eventTime.formatted(date: .omitted, time: .shortened))
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 16)

                Spacer()
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
                        .foregroundColor(.white)
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
                    .onChange(of: viewModel.numberOfSpots) { _, newValue in
                        // Allow only digits; keep blank allowed
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            viewModel.numberOfSpots = filtered
                        }
                    }
            }
        }
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Colors.primaryDark)
        )
    }

    // Keyboard accessory removed for cleaner UI
}

#Preview {
    CreateEventView(coveId: nil)
}
