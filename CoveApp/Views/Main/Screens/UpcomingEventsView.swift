//
//  UpcomingEventsView.swift
//  Cove
//
//  Created by Ananya Agarwal
import SwiftUI
import CoreLocation


// TODO: maybe don't make this scrollable, instead the down arrow expands to the calendar page 
// TODO: get rid of stub data
// also where are these cute little icons coming from?
struct UpcomingEventsView: View {
    
    @StateObject private var viewModel = UpcomingEventsViewModel()
    @EnvironmentObject var appController: AppController
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    Text("cove")
                        .font(.LibreBodoni(size: 70))
                        .foregroundColor(Colors.primaryDark)
                        .frame(height: 70)
                    
                    HStack {
                        Image("location-pin")
                            .frame(width: 15, height: 20)
                        
                        Text(appController.profileModel.address.isEmpty ? "add your location" : appController.profileModel.address)
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 15))
                    }
                    
                    VStack {
                        Image("landing")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .clipped()
                        
                        HStack(spacing: 4) {
                            Button {
                                appController.path.append(.exploreFriends)
                            } label: {
                                Text("\(appController.profileModel.stats?.friendCount ?? 0) friends")
                                    .foregroundStyle(Colors.primaryDark)
                                    .font(.LibreBodoniBold(size: 11))
                            }
                            
                            Text("|")
                                .foregroundStyle(Colors.primaryDark)
                                .font(.LibreBodoniBold(size: 11))
                            
                            Button {
                                appController.path.append(.friendRequests)
                            } label: {
                                Text("\(appController.profileModel.stats?.requestCount ?? 0) requests")
                                    .foregroundStyle(Colors.primaryDark)
                                    .font(.LibreBodoniBold(size: 11))
                            }
                        }
                    }
                    .background(
                        VStack {
                            Image("landing-icon-bg")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 240)
                                .clipped()
                                .padding(.trailing, 32)
                                .padding(.top, 50)
                        }
                    )
                    
                    Spacer(minLength: 60)
                    
                    VStack {
                        Text("upcoming events")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.Lugrasimo(size: 25))
                        
                        ScrollView {
                            VStack(spacing: 16) {
                                // Grouped events by date
                                ForEach(viewModel.groupedEvent?.keys.sorted() ?? [], id: \.self) { date in
                                    VStack(spacing: 8) {
                                        HStack {
                                            Text(viewModel.formattedDateWithOrdinal(date))
                                                .foregroundStyle(Color.black)
                                                .font(.Lugrasimo(size: 12))
                                            Spacer()
                                            Image("person-fill")
                                        }
                                        .padding(.horizontal, 16)
                                        
                                        ForEach(viewModel.groupedEvent?[date] ?? [], id: \.id) { event in
                                            UpcomingEventCellView(event: event)
                                        }
                                        
                                        Divider()
                                            .frame(height: 1)
                                            .background(Color.black.opacity(0.58))
                                            .padding(.horizontal, 16)
                                    }
                                }
                                
                                if viewModel.groupedEvent?.isEmpty ?? true {
                                    if viewModel.isLoading {
                                        Text("Loading...")
                                            .foregroundStyle(Colors.primaryDark)
                                            .font(.LibreBodoni(size: 14))
                                            .frame(maxWidth: .infinity, minHeight: 100)
                                    } else {
                                        Text("No events yet!")
                                            .foregroundStyle(Colors.primaryDark)
                                            .font(.LibreBodoni(size: 14))
                                            .frame(maxWidth: .infinity, minHeight: 100)
                                    }
                                }
                                
                                if viewModel.isLoading {
                                    ProgressView()
                                        .padding()
                                }
                            }
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: geometry.frame(in: .named("scrollView")).minY
                                    )
                                }
                            )
                        }
                        .coordinateSpace(name: "scrollView")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                            if offset < -150 {
                                viewModel.loadMoreEventsIfNeeded()
                            }
                        }
                        .frame(height: 200)
                        
                        Button {
                            // appController.path.append(.calendar)
                        } label: {
                            VStack(spacing: 6) {
                                Text("my calendar")
                                    .foregroundStyle(Colors.primaryDark)
                                    .font(.LibreBodoni(size: 10))
                                
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(Color.black)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 2)
                    }
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear(perform: {
            // Only fetch if we don't have recent data or if this is the first load
            if viewModel.events.isEmpty || viewModel.groupedEvent == nil {
                viewModel.fetchUpcomingEvents()
            }
            
            // Refresh profile data if needed and update address
            appController.profileModel.fetchProfile { result in
                switch result {
                case .success(_):
                    // Profile data updated, address will be updated automatically
                    Task {
                        await appController.profileModel.updateAddress()
                    }
                case .failure(let error):
                    print("Failed to fetch profile: \(error)")
                }
            }
        })
        .onDisappear {
            // Cancel any ongoing requests when view disappears
            viewModel.cancelRequests()
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    UpcomingEventsView()
        .environmentObject(AppController.shared)
}

struct UpcomingEventCellView: View {
    
    var event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 16) {
            Text(formattedTime(event.date))
                .foregroundStyle(Color.black)
                .font(.Lugrasimo(size: 12))
            
            // TODO: Get actual event image (or Icon? ask Angela)
            Image("event-image-1")
                .frame(width: 40, height: 40)
            
            Text(event.name)
                .foregroundStyle(Colors.primaryDark)
                .font(.LibreBodoni(size: 14))
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Text("\(event.goingCount) going")
                .foregroundStyle(Color.black)
                .font(.LibreBodoni(size: 12))
        }
        .padding(.horizontal, 16)
    }
    
    func formattedTime(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "h:mm a"

            let timeString = outputFormatter.string(from: date)
            return timeString
        }
        
        return ""
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

