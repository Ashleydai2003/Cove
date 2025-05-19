//
//  UserLocationView.swift
//  Cove
//


import SwiftUI


struct UserLocationView: View {
    
    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController
    
    /// ViewModel for managing location coordinate and state variables
    @StateObject private var viewModel = UserLocationViewModel()
    
    /// Focus states for input field
    @FocusState private var isFocused: Bool
    
    var body: some View {
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
            
            Text("where are you \nbased?")
                .foregroundStyle(Colors.primaryDark)
                .font(.LibreBodoniMedium(size: 40))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    HStack(spacing: 16) {
                        VStack {
                            ZStack {
                                if viewModel.state.isEmpty {
                                    Text("state")
                                        .foregroundColor(Colors.k656566)
                                        .font(.LibreCaslon(size: 15))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                TextField("", text: $viewModel.state)
                                    .font(.LibreCaslon(size: 15))
                                    .foregroundStyle(Colors.k656566)
                                    .keyboardType(.alphabet)
                                    .focused($isFocused)
                            }
                            
                            Divider()
                                .frame(height: 2)
                                .background(Color.black)
                        }
                        .frame(width: AppConstants.SystemSize.width * 0.25)
                        
                        VStack {
                            ZStack {
                                if viewModel.city.isEmpty {
                                    Text("neighborhood, city")
                                        .foregroundColor(Colors.k656566)
                                        .font(.LibreCaslon(size: 15))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                TextField("", text: $viewModel.city)
                                    .font(.LibreCaslon(size: 15))
                                    .foregroundStyle(Colors.k656566)
                                    .keyboardType(.alphabet)
                                    .focused($isFocused)
                            }
                            
                            Divider()
                                .frame(height: 2)
                                .background(Color.black)
                        }
                    }
                    .padding(.top, 25)
                    
                    Spacer().frame(height: 15)
                    
                    VStack {
                        MapView(userLocation: $viewModel.locationManager.location, coordinate: $viewModel.selectedCoordinate)
                            .edgesIgnoringSafeArea(.all)
                            .frame(height: AppConstants.SystemSize.height * 0.3)
                    }
                    
                    Spacer().frame(height: 10)
                    
                    HStack {
                        VStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(Colors.k656566)
                                    .onTapGesture {
                                        if viewModel.zipcode.count > 0 {
                                            viewModel.searchZip(viewModel.zipcode)
                                        }
                                    }
                                
                                ZStack {
                                    if viewModel.zipcode.isEmpty {
                                        Text("zip code")
                                            .foregroundColor(Colors.k656566)
                                            .font(.LibreCaslon(size: 15))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    TextField("", text: $viewModel.zipcode)
                                        .font(.LibreCaslon(size: 15))
                                        .foregroundStyle(Colors.k656566)
                                        .keyboardType(.numberPad)
                                        .focused($isFocused)
                                }
                                
                                
                            }
                                
                            Divider()
                                .frame(height: 2)
                                .background(Color.black)
                        }
                        .frame(width: 150)
                        
                        Spacer()
                    }
                    .padding(.top, 10)
                }
            }
            
            HStack {
                Spacer()
                Images.smily
                    .resizable()
                    .frame(width: 52, height: 52)
                    .padding(.bottom, 20)
                    .onTapGesture {
                        //TODO: Push location details to Cloud
                        /// City, state & zip code variable saved in ViewModel
                        /// latitude => viewModel.selectedCoordinate?.latitude
                        /// longitude => viewModel.selectedCoordinate?.longitude
                        appController.path.append(.almaMater)
                    }
            }
            
        }
        .padding(.horizontal, 32)
        .background(Colors.kF5F5F5.edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.startUpdatingLocation()
        }
        .onDisappear {
            viewModel.stopUpdatingLocation()
        }
        .onChange(of: viewModel.selectedCoordinate) { oldValue, newValue in
            if let coordinate = newValue {
                viewModel.getPlacemark(from: coordinate)
            }
        }
        .onChange(of: viewModel.locationManager.location) { oldValue, newValue in
            if let location = newValue {
                viewModel.locationManager.stopUpdatingLocation()
                viewModel.getPlacemark(from: location.coordinate)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isFocused = false // Dismiss keyboard
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
}

#Preview {
    UserLocationView()
}
