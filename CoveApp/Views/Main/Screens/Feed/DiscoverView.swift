//
//  DiscoverView.swift
//  Cove
//

import SwiftUI

// MARK: - DiscoverView
struct DiscoverView: View {

    var body: some View {
        VStack {
            Spacer()
            Text("coming soon!")
                .font(.LibreBodoni(size: 18))
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Colors.faf8f4)
    }
}

// MARK: - Preview
struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}
