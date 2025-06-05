//
//  LocationSearchView.swift
//  Cove
//
//  Created by Ananya Agarwal

import SwiftUI

import SwiftUI
import MapKit

struct LocationSearchView: View {
    
    @StateObject private var viewModel = LocationSearchViewModel()
    var completion: (String?) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search for a place", text: $viewModel.searchQuery)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                List(viewModel.searchResults, id: \.self) { completion in
                    Button {
                        viewModel.selectLocation(completion: completion) { location in
                            self.completion(location)
                            dismiss()
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(completion.title).bold()
                            Text(completion.subtitle).font(.subheadline).foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Search Location")
        }
    }
}

#Preview {
    LocationSearchView { location in
        
    }
}
