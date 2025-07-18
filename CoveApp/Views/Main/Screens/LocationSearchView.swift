//
//  LocationSearchView.swift
//  Cove
//
//  Created by Ananya Agarwal

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
                    .padding(.top, 20)

                    // Search bar under title
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Colors.k6F6F73)
                            .font(.system(size: 16))

                        TextField("enter address", text: $viewModel.searchQuery)
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(Colors.primaryDark)
                            .textFieldStyle(PlainTextFieldStyle())

                        if !viewModel.searchQuery.isEmpty {
                            Button {
                                viewModel.searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Colors.k6F6F73)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

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
                                        .font(.system(size: 20))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.title)
                                            .font(.LibreBodoniBold(size: 16))
                                            .foregroundColor(Colors.primaryDark)
                                            .multilineTextAlignment(.leading)

                                        Text(result.subtitle)
                                            .font(.LeagueSpartan(size: 14))
                                            .foregroundColor(Colors.k6F6F73)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Colors.faf8f4) // Same as background
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Colors.faf8f4) // Same as background
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Colors.faf8f4)
                }
            }
        }
    }
}

#Preview {
    LocationSearchView { location in

    }
}
