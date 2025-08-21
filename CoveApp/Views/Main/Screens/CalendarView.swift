//
//  CalendarView.swift (new)
//  Cove
//

import SwiftUI

struct CalendarView: View {
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
    CalendarView()
        .environmentObject(AppController.shared)
}


