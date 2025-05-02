import SwiftUI

struct HobbiesView: View {
    @EnvironmentObject var appController: AppController
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack {
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
                .padding(.top, 40)
                
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
    }
}

#Preview {
    HobbiesView()
        .environmentObject(AppController.shared)
}
