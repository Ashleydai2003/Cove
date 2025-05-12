//
//  UserLocationView.swift
//  Cove
//


import SwiftUI


struct UserLocationView: View {
    
    /// App controller for managing navigation and shared state
    @EnvironmentObject var appController: AppController
    
    @StateObject private var viewModel = UserLocationViewModel()
    
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
                    
                    VStack {
                        if let location = viewModel.locationManager.location {
                            MapView(userLocation: .constant(location), coordinate: $viewModel.selectedCoordinate)
                                .edgesIgnoringSafeArea(.all)
                                .frame(height: AppConstants.SystemSize.height * 0.3)
                        } else {
                            //                            ProgressView("Locating...")
                            MapView(userLocation: $viewModel.locationManager.location, coordinate: $viewModel.selectedCoordinate)
                                .edgesIgnoringSafeArea(.all)
                                .frame(height: AppConstants.SystemSize.height * 0.3)
                        }
                    }
                    
                    HStack {
                        VStack {
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
                            
                            Divider()
                                .frame(height: 2)
                                .background(Color.black)
                        }
                        .frame(width: 100)
                        
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
