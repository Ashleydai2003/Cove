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
            ZStack {
                Colors.faf8f4.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Custom header
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Images.backArrow
                        }
                        Spacer()
                        Text("search address")
                            .font(.LibreBodoniBold(size: 22))
                            .foregroundColor(Colors.primaryDark)
                        Spacer()
                        // invisible filler for alignment
                        Images.backArrow.opacity(0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    // Results list
                    List {
                        ForEach(viewModel.searchResults, id: \.self) { result in
                            Button {
                                viewModel.selectLocation(completion: result) { location in
                                    self.completion(location)
                                    dismiss()
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(Colors.primaryDark)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.title)
                                            .font(.LibreBodoniBold(size: 16))
                                            .foregroundColor(Colors.primaryDark)
                                        Text(result.subtitle)
                                            .font(.LeagueSpartan(size: 14))
                                            .foregroundColor(Colors.k6F6F73)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Colors.faf8f4)
                    .searchable(text: $viewModel.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "enter address")
                }
            }
        }
    }
}

#Preview {
    LocationSearchView { location in
        
    }
}
