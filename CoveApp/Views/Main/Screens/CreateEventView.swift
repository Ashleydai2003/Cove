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
    @EnvironmentObject var appController: AppController
    
    // Event Details
    @State private var eventName: String = ""
    @State private var eventDate = Date()
    @State private var eventTime = Date()
    @State private var numberOfSpots: String = ""
    @State private var eventImage: UIImage?
    @State private var location: String?
    @State private var isSubmitting = false
    
    // Event Settings
    @State private var selectedEventStatus = "opened"
    let statusOptions = ["opened", "closed"]
    
    // Sheet States
    @State private var showImagePicker: Bool = false
    @State private var showLocationPicker: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showTimePicker: Bool = false
    
    @FocusState private var isFocused: Bool
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
    
            VStack {
                headerView
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        eventNameSection
                        imagePickerSection
                        dateTimeSection
                        locationSection
                        spotsSection
                        createButtonView
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer(minLength: 24)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $eventImage)
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationSearchView(completion: { location in
                self.location = location
            })
        }
        .sheet(isPresented: $showDatePicker) {
            DatePicker("", selection: $eventDate, in: Date()..., displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .presentationDetents([.height(400)])
        }
        .sheet(isPresented: $showTimePicker) {
            DatePicker("", selection: $eventTime, in: Date()..., displayedComponents: [.hourAndMinute])
                .datePickerStyle(.wheel)
                .presentationDetents([.height(200)])
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                keyboardAccessoryView
            }
        }
        .navigationBarBackButtonHidden()
    }
}

// MARK: - View Components
extension CreateEventView {
    // MARK: - Header
    private var headerView: some View {
        VStack {
            HStack(alignment: .top) {
                Spacer()
                
                Image("add-event-icn")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.leading, -10)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            Text("host an event")
                .font(.LibreBodoni(size: 35))
                .foregroundColor(Colors.primaryDark)
        }
    }
    
    // MARK: - Event Name Section
    private var eventNameSection: some View {
        VStack {
            ZStack(alignment: .center) {
                if eventName.isEmpty {
                    Text("untitled event")
                        .foregroundColor(.white)
                        .font(.LibreBodoniBold(size: 22))
                }
                
                TextField("untitled event", text: $eventName)
                    .foregroundStyle(Color.white)
                    .font(.LibreBodoniBold(size: 22))
                    .multilineTextAlignment(.center)
                    .autocorrectionDisabled()
                    .focused($isFocused)
            }
            .padding([.horizontal, .top], 16)
            
            privacySettingsView
        }
        .background(Colors.primaryDark)
    }
    
    // MARK: - Privacy Settings
    private var privacySettingsView: some View {
        HStack {
            Button {
                
            } label: {
                Text("public")
                    .foregroundStyle(Colors.k070708)
                    .font(.LibreBodoniSemiBold(size: 14))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                    )
            }
            
            Menu {
                Picker(selection: $selectedEventStatus) {
                    ForEach(statusOptions, id: \.self) { option in
                        Text(option)
                            .foregroundStyle(Colors.k070708)
                            .font(.LibreBodoniSemiBold(size: 14))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 4)
                    }
                } label: {}
            } label: {
                HStack(spacing: 10) {
                    Text(selectedEventStatus)
                        .foregroundStyle(Colors.k070708)
                        .font(.LibreBodoniSemiBold(size: 14))
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Colors.k070708)
                        .font(.LibreBodoniSemiBold(size: 14))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
            )
            
            Button {
                
            } label: {
                Text("private")
                    .foregroundStyle(Colors.k070708)
                    .font(.LibreBodoniSemiBold(size: 14))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                    )
            }
        }
        .padding([.horizontal, .bottom], 16)
    }
    
    // MARK: - Image Picker Section
    private var imagePickerSection: some View {
        Button {
            showImagePicker = true
        } label: {
            ZStack {
                if eventImage == nil {
                    Text("image")
                        .font(.LibreBodoni(size: 16))
                        .foregroundColor(Colors.primaryDark)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Image(uiImage: eventImage ?? UIImage())
                    .resizable()
                    .scaledToFill()
                    .frame(width: AppConstants.SystemSize.width-64, height: 250)
                    .clipped()
            }
            .frame(height: 250)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.black, lineWidth: 1)
            )
        }
        .padding(.top, 16)
    }
    
    // MARK: - Date & Time Section
    private var dateTimeSection: some View {
        VStack(spacing: 16) {
            chooseDateView
            chooseTimeView
        }
        .padding(.top, 16)
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        Button {
            showLocationPicker = true
        } label: {
            HStack {
                Text("location")
                    .foregroundStyle(Color.white)
                    .font(.LibreBodoniBold(size: 16))
                
                Spacer()
                
                Text(self.location ?? "")
                    .foregroundStyle(Color.white.opacity(0.8))
                    .font(.LibreBodoniBold(size: 16))
                    .lineLimit(2)
            }
            .padding(.leading, 24)
            .frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 0)
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
            submitEvent()
        } label: {
            if isSubmitting {
                ProgressView()
                    .tint(.black)
                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                    )
            } else {
                Text("create")
                    .foregroundStyle(eventName.isEmpty ? Color.gray : Color.black)
                    .font(.LibreBodoniBold(size: 16))
                    .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(eventName.isEmpty ? Color.gray.opacity(0.3) : Color.white)
                    )
            }
        }
        .disabled(eventName.isEmpty || isSubmitting)
        .padding(.top, 24)
    }
    
    // MARK: - Date Picker
    private var chooseDateView: some View {
        Button {
            showDatePicker = true
        } label: {
            HStack {
                Text("set a date")
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 24)
                
                Spacer()
                
                Text(eventDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundStyle(Color.white)
                    .padding(.trailing, 24)
            }
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(Colors.primaryDark)
            )
        }
    }
    
    // MARK: - Time Picker
    private var chooseTimeView: some View {
        Button {
            showTimePicker = true
        } label: {
            HStack {
                Text("time")
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 24)
                
                Spacer()
                
                Text(eventTime.formatted(date: .omitted, time: .shortened))
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundStyle(Color.white)
                    .padding(.trailing, 24)
            }
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(Colors.primaryDark)
            )
        }
    }
    
    // MARK: - Number of Spots Input
    private var numberOfSpotsView: some View {
        ZStack(alignment: .leading) {
            if numberOfSpots.isEmpty {
                Text("number of spots")
                    .foregroundColor(.gray)
                    .font(.LibreBodoniBold(size: 16))
                    .padding(.leading, 24)
            }
            
            TextField("", text: $numberOfSpots)
                .foregroundStyle(Color.white)
                .font(.LibreBodoniBold(size: 16))
                .padding(.horizontal, 24)
                .autocorrectionDisabled()
                .keyboardType(.numberPad)
                .focused($isFocused)
        }
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 0)
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

// MARK: - API Integration
extension CreateEventView {
    /// Submits the event to the backend
    func submitEvent() {
        guard let image = eventImage,
              let coverPhoto = image.jpegData(compressionQuality: 0.8),
              let location = self.location else {
            return
        }
        
        isSubmitting = true
        
        // Format date to ISO 8601
        let finalDate: String = combine(date: eventDate, time: eventTime) ?? ""
        debugPrint(finalDate)
        
        // TODO: we need a way to actually retrieve the coveIds from the user
        let params: [String: Any] = [
            "name": eventName,
            "description": "",
            "date": finalDate,
            "location": location,
            "coverPhoto": coverPhoto.base64EncodedString(),
            "coveId": "cmb776s5r000ajs0812w2ncmq"
        ]
        
        NetworkManager.shared.post(endpoint: "/create-event", parameters: params) { (result: Result<CreateEventResponse, NetworkError>) in
            DispatchQueue.main.async {
                self.isSubmitting = false
                
                switch result {
                case .success(let response):
                    debugPrint(response)
                    // Navigate to EventPostView with the created event ID
                    appController.navigateToEvent(eventId: response.event.id)
                case .failure(let error):
                    debugPrint(error)
                    // TODO: Show error alert to user
                }
            }
        }
    }
    
    /// Combines date and time into an ISO 8601 string
    func combine(date: Date, time: Date, calendar: Calendar = Calendar.current) -> String? {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second
        
        guard let combinedDate = calendar.date(from: combinedComponents) else { return nil }
        
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return formatter.string(from: combinedDate)
    }
}

#Preview {
    CreateEventView()
}
