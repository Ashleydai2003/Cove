//
//  NewFriendMutualsView.swift
//  Cove
//

import SwiftUI

struct NewFriendMutualsView: View {
    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()
            VStack {
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    NewFriendMutualsView()
        .environmentObject(AppController.shared)
}


