//
//  FloatingActionView.swift
//  Cove
//
//  Created by Assistant

import SwiftUI

/// FloatingActionView: A circular + button that shows event and cove creation options
struct FloatingActionView: View {
    let coveId: String?
    @State private var showMenu = false
    @State private var showCreateEventSheet = false
    @State private var showCreateCoveSheet = false
    @EnvironmentObject private var appController: AppController
    
    // MARK: - Initializer
    init(coveId: String? = nil) {
        self.coveId = coveId
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            // Menu options - appear above the + button
            if showMenu {
                VStack(alignment: .trailing, spacing: 12) {
                    // Cove option
                    Button(action: {
                        showMenu = false
                        showCreateCoveSheet = true
                    }) {
                        HStack(spacing: 12) {
                            Text("cove")
                                .font(.LibreBodoni(size: 25))
                                .foregroundColor(.white)
                            Spacer()
                            Image("cove_selected")
                                .resizable()
                                .frame(maxWidth: 35, maxHeight: 35)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Colors.primaryDark)
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        )
                    }
                    
                    // Event option
                    Button(action: {
                        showMenu = false
                        showCreateEventSheet = true
                    }) {
                        HStack() {
                            Text("event")
                                .font(.LibreBodoni(size: 25))
                                .foregroundColor(.white)
                            Spacer()
                            Image("confetti")
                                .resizable()
                                .frame(maxWidth: 35, maxHeight: 35)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Colors.primaryDark)
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        )
                    }
                }
                .frame(maxWidth: 160) // Increase width to prevent text wrapping
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
        .sheet(isPresented: $showCreateCoveSheet) {
            CreateCoveView()
        }
    }
}

#Preview {
    FloatingActionView(coveId: nil)
        .environmentObject(AppController.shared)
} 