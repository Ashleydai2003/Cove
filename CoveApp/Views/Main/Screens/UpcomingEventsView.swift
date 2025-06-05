//
//  UpcomingEventsView.swift
//  Cove
//
//  Created by Ananya Agarwal
import SwiftUI

struct UpcomingEventsView: View {
    
    @StateObject private var viewModel = UpcomingEventsViewModel()
    
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
                        
                        Text("pacific heights, san francisco")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoni(size: 15))
                    }
                    
                    VStack {
                        Image("landing")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .clipped()
                        
                        Text("105 friends | 14 coves")
                            .foregroundStyle(Colors.primaryDark)
                            .font(.LibreBodoniBold(size: 11))
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
                        
//                        ForEach(viewModel.events, id: \.id) { event in
//                            UpcomingEventCellView(event: event)
//                        }
                        
//                        if let grouped = viewModel.groupedEvent {
//                            for (dateString, events) in grouped {
//                                HStack {
//                                    Text(dateString)
//                                        .foregroundStyle(Color.black)
//                                        .font(.Lugrasimo(size: 12))
//                                    Spacer()
//                                    Image("person-fill")
//                                    
//                            }
//                        }
                        
                        
                        ForEach(viewModel.groupedEvent?.keys.sorted() ?? [], id: \.self) { date in
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
                        
                        
                        
                        Button {
                            
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
            viewModel.fetchUpcomingEvents()
        })
        .navigationBarBackButtonHidden()
        
    }
    
}

#Preview {
    UpcomingEventsView()
}

struct UpcomingEventCellView: View {
    
    var event: Event
    
    var body: some View {
        HStack(spacing: 16) {
            Text(formattedTime(event.date))
                .foregroundStyle(Color.black)
                .font(.Lugrasimo(size: 12))
            
            Image("event-image-1")
                .frame(width: 40, height: 40)
            
            Text(event.name)
                .foregroundStyle(Colors.primaryDark)
                .font(.LibreBodoni(size: 14))
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Text("34 going")
                .foregroundStyle(Color.black)
                .font(.LibreBodoni(size: 12))
        }
        .padding(.horizontal, 16)
    }
    
    func formattedTime(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
//        inputFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let date = inputFormatter.date(from: dateString) {
            // Step 2: Format time only
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "h:mm a"
            outputFormatter.timeZone = TimeZone(secondsFromGMT: 0)

            let timeString = outputFormatter.string(from: date)
            return timeString
        }
        
        return ""
    }
    
}

