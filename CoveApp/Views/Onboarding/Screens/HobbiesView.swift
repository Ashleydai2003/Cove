import SwiftUI
import Inject

struct HobbiesView: View {
    @EnvironmentObject var appController: AppController
    @State private var selectedButtons: Set<String> = []
    @ObserveInjection var inject
    
    // Define grid layout
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    // Organized categories of hobbies with emojis
    private let hobbyCategories: [(String, [(String, String)])] = [
        ("Sports & Fitness 🏃‍♀️", [
            ("Soccer Teams", "⚽️"),
            ("Basketball Leagues", "🏀"),
            ("Tennis Groups", "🎾"),
            ("Hiking Groups", "🥾"),
            ("Yoga Classes", "🧘‍♀️"),
            ("Surfing Meetups", "🏄‍♀️"),
            ("Rock Climbing", "🧗‍♀️"),
            ("Swimming Clubs", "🏊‍♀️"),
            ("Running Groups", "🏃‍♀️"),
            ("Volleyball Teams", "🏐"),
            ("Spin Classes", "🚴‍♀️")
        ]),
        ("Creative Pursuits 🎨", [
            ("Art Museums", "🖼️"),
            ("Pottery Classes", "🏺"),
            ("Dance Studios", "💃"),
            ("Music Festivals", "🎵"),
            ("Theater Groups", "🎭"),
            ("Cooking Classes", "👨‍🍳"),
            ("Craft Workshops", "✂️"),
            ("Writing Circles", "✍️"),
            ("Film Clubs", "🎬")
        ]),
        ("Entertainment 🎉", [
            ("Cocktail Bars", "🍸"),
            ("Clubs", "🍷"),
            ("Wine Tastings", "🍷"),
            ("Comedy Clubs", "😄"),
            ("Karaoke Nights", "🎤"),
            ("Escape Rooms", "🔐"),
            ("Bowling Leagues", "🎳"),
            ("Live Music Venues", "🎸")
        ]),
        ("Social Activities 🌟", [
            ("Book Clubs", "📚"),
            ("Travel Groups", "✈️"),
            ("Founders Groups", "💻"),
            ("Chess Clubs", "♟️"),
            ("Volunteer Groups", "🤝"),
        ])
    ]
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button {
                        appController.path.removeLast()
                    } label: {
                        Images.backArrow
                    }
                    Spacer()
                }
                .padding(.top, 10)
                
                // Content
                VStack(alignment: .leading, spacing: 10) {
                    Text("what are your favorite social pass times?")
                        .foregroundStyle(Colors.primary)
                        .font(.LibreBodoni(size: 35))
                    
                    HStack(alignment: .center, spacing: 4) {
                        Text("select at least 5 activities you wish to see in your area.")
                            .foregroundStyle(Colors.primary)
                            .font(.LeagueSpartan(size: 12))
                        
                        Image("smiley")
                            .resizable()
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                .enableInjection()
                
                // Grid of buttons
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(hobbyCategories, id: \.0) { category in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(category.0)
                                    .font(.LeagueSpartan(size: 16))
                                    .foregroundStyle(Colors.primary)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(category.1, id: \.0) { hobby in
                                        Button(action: {
                                            if selectedButtons.contains(hobby.0) {
                                                selectedButtons.remove(hobby.0)
                                            } else {
                                                selectedButtons.insert(hobby.0)
                                            }
                                        }) {
                                            ZStack {
                                                Image(selectedButtons.contains(hobby.0) ? "buttonRed" : "buttonWhite")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                
                                                HStack(spacing: 4) {
                                                    Text(hobby.1)
                                                    Text(hobby.0.lowercased())
                                                }
                                                .foregroundColor(selectedButtons.contains(hobby.0) ? .white : .black)
                                                .font(.LeagueSpartan(size: 14))
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .multilineTextAlignment(.center)
                                            }
                                            .frame(height: 48)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Images.smily
                        .resizable()
                        .frame(width: 52, height: 52)
                        .padding(.init(top: 0, leading: 0, bottom: 20, trailing: 20))
                        .onTapGesture {
                            appController.path.append(.mutuals)
                        }
                }
            }
            .padding(.horizontal, 20)
            .safeAreaPadding()
        }
        .navigationBarBackButtonHidden()
        .enableInjection()
    }
}

#Preview {
    HobbiesView()
        .environmentObject(AppController.shared)
}
