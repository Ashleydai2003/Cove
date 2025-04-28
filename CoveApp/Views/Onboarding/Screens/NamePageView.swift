import SwiftUI

struct NamePageView: View {
    
    @EnvironmentObject var appController: AppController
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""

    var body: some View {
        GeometryReader { geometry in
            ZStack() {
                // backgroun image
                OnboardingBackgroundView(imageName: "name_background")
                    .opacity(0.2)
                
                // main content container view
                VStack {
                    VStack(alignment: .leading) {
                        Text("what's your \nname?")
                            .font(.LibreBodoni(size: 40))
                            .foregroundColor(Colors.primaryDark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("only your first name will be displayed.")
                            .font(.LeagueSpartan(size: 15))
                            .foregroundColor(Colors.k6F6F73)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 40)
                    
                    // input boxes for name
                    // TODO: Change font
                    VStack {
                        TextField("first name", text: $firstName)
                            .font(.LibreCaslon(size: 25))
                            .padding(.horizontal, 10)
                        
                        Divider()
                            .frame(height: 2)
                            .background(Color.black.opacity(0.58))
                        
                        TextField("last name", text: $lastName)
                            .font(.LibreCaslon(size: 25))
                            .padding(.top)
                            .padding(.horizontal, 10)
                        
                        Divider()
                            .frame(height: 2)
                            .background(Color.black.opacity(0.58))
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Images.smily
                            .resizable()
                            .frame(width: 52, height: 52)
                            .padding(.init(top: 0, leading: 0, bottom: 60, trailing: 20))
                            .onTapGesture {
                                appController.path.append(.birthdate)
                            }
                    }
                }
                .padding(.horizontal, 20)
                .safeAreaPadding()
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    NamePageView()
} 
