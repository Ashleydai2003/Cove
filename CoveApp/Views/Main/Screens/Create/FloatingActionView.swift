//
//  FloatingActionView.swift
//  Cove
//
//  Created by Assistant

import SwiftUI

/// FloatingActionView: A circular + button that shows event creation option
struct FloatingActionView: View {
    let coveId: String?
    @State private var showMenu = false
    @State private var showCreateEventSheet = false
    @EnvironmentObject private var appController: AppController
    
    // MARK: - Initializer
    init(coveId: String? = nil) {
        self.coveId = coveId
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            // Event option - appears above the + button
            if showMenu {
                    Button(action: {
                        showMenu = false
                    showCreateEventSheet = true
                    }) {
                    HStack(spacing: 12) {
                        Text("event")
                            .font(.LibreBodoni(size: 20))
                            .foregroundColor(.white)
                            Image("confetti")
                            .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                        .background(
                        RoundedRectangle(cornerRadius: 28)
                                .fill(Colors.primaryDark)
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        )
                }
                .transition(.opacity.combined(with: .scale))
            }
            
            // Main + button - always visible at bottom right
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showMenu.toggle()
                }
            }) {
                Image(systemName: showMenu ? "xmark" : "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Colors.primaryDark)
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                    )
                    .rotationEffect(.degrees(showMenu ? 180 : 0))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showMenu)
        .sheet(isPresented: $showCreateEventSheet) {
            CreateEventView(coveId: coveId)
        }
    }
}

#Preview {
    FloatingActionView(coveId: nil)
        .environmentObject(AppController.shared)
} 