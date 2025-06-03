//
//  CreateEventView.swift
//  Cove
//
//  Created by Nesib Muhedin


import SwiftUI

struct CreateEventView: View {
    
    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController
    
    @State private var selectedEventStatus = "opened"
    let statusOptions = ["opened", "closed"]
    
    @State private var eventName: String = ""
    @State private var eventDate = Date()
    @State private var eventTime = Date()
    @State private var numberOfSpots: String = ""
    @State private var eventImage: UIImage?
    @State private var location: String?
    
    @State private var showImagePicker: Bool = false
    @State private var showLocationPicker: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
    
            VStack {
                // Back button
                HStack(alignment: .top) {
//                    Button {
//                        appController.path.removeLast()
//                    } label: {
//                        Images.backArrow
//                    }
//                    .padding(.top, 16)
                    
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
                    .foregroundStyle(Colors.primaryDark)
                    .font(.Lugrasimo(size: 30))
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        VStack {
                            ZStack(alignment: .leading) {
                                if eventName.isEmpty {
                                    Text("untitled event")
                                        .foregroundColor(.gray)
                                        .font(.LibreBodoniBold(size: 22))
                                        .padding(.leading, 4)
                                }
                                
                                TextField("", text: $eventName)
                                    .foregroundStyle(Color.white)
                                    .font(.LibreBodoniBold(size: 22))
                                    .padding(.horizontal, 10)
                                    .autocorrectionDisabled()
                                    .focused($isFocused)
                                    
                            }
                            .padding([.horizontal, .top], 16)
                            
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
                        .background(Colors.primaryDark)
                        
                        Button {
                            showImagePicker = true
                        } label: {
                            ZStack {
                                if eventImage == nil {
                                    Text("Image")
                                        .foregroundStyle(Colors.k070708)
                                        .font(.LeagueSpartan(size: 12))
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
                        
                        chooseDateView
                            .padding(.top, 16)
                        
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
                        
                        chooseTimeView
                        
                        numberOfSpotsView
                        
                        createButtonView
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer(minLength: 24)
            }
            
        }
        .sheet(isPresented: $showImagePicker, content: {
            ImagePicker(image: $eventImage)
        })
        .sheet(isPresented: $showLocationPicker, content: {
            LocationSearchView(completion: { location in
                self.location = location
            })
        })
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                keyboardAccessoryView
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    // Custom input accessory view for keyboard
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

extension CreateEventView {
    
    var chooseDateView: some View {
        Button {
            
        } label: {
            HStack {
                Text("set a date")
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 24)
                
                Spacer()
                
                DatePicker("", selection: $eventDate, in: Date()..., displayedComponents: [.date])
                    .labelsHidden()
                    .foregroundStyle(Color.white)
                    .colorInvert()
            }
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(Colors.primaryDark)
            )
        }
    }
    
    var chooseTimeView: some View {
        Button {
            
        } label: {
            HStack {
                Text("time")
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundStyle(Color.white)
                    .padding(.leading, 24)
                
                Spacer()
                
                DatePicker("", selection: $eventTime, in: Date()..., displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                    .foregroundStyle(Color.white)
                    .colorInvert()
            }
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(Colors.primaryDark)
            )
        }
    }
    
    var numberOfSpotsView: some View {
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
    
    var createButtonView: some View {
        Button {
            submitEvent()
        } label: {
            Text("create")
                .foregroundStyle(Color.black)
                .font(.LibreBodoniBold(size: 16))
                .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                )
        }
        .padding(.top, 24)
    }
    
}

#Preview {
    CreateEventView()
}

extension CreateEventView {
    
//    name: String (required)
//    description: String (optional)
//    date: ISO 8601 string (required)
//    location: String (required)
//    coverPhoto: String (optional, base64 encoded)
//    coveId: String (required)
    
    func submitEvent() {
        
        guard let image = eventImage,
              let coverPhoto = image.jpegData(compressionQuality: 0.8),
              let location = self.location else {
            return
        }
        
        // Format date to ISO 8601
        let finalDate: String = combine(date: eventDate, time: eventTime) ?? ""
        debugPrint(finalDate)
        
        //TODO: Need to pass addition fields such as scope, status, number of spots etc
        let params: [String: Any] = ["name": eventName,
                                     "description":"",
                                     "date": finalDate,
                                     "location": location,
                                     "coverPhoto": coverPhoto.base64EncodedString(),
                                     "coveId":"cmb776s5r000ajs0812w2ncmq"]
        
        NetworkManager.shared.post(endpoint: "/create-event", parameters: params) { (result: Result<CreateEventResponse, NetworkError>) in
            switch result {
            case .success(let response):
                debugPrint(response)
            case .failure(let error):
                debugPrint(error)
            }
        }
    }
    
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
        
        // Create new combined Date
        guard let combinedDate = calendar.date(from: combinedComponents) else { return nil }
        
        // Format as ISO 8601 string
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return formatter.string(from: combinedDate)
    }
    
//    {
//      "message": "Event created successfully",
//      "event": {
//        "id": "cmbde0y8v0001lc08dvew7sf4",
//        "name": "Riverfront carnival",
//        "description": null,
//        "date": "2025-06-07T00:00:00.000Z",
//        "location": "Gandhi Ashram, Ahmedabad, Gujarat",
//        "coveId": "cmb776s5r000ajs0812w2ncmq",
//        "createdAt": "2025-06-01T08:17:15.103Z"
//      }
//    }
    
}
