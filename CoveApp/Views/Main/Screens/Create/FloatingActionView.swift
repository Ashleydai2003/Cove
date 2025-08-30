//
//  FloatingActionView.swift
//  Cove
//
//  Created by Assistant

import SwiftUI
import UIKit

/// FloatingActionView: A circular + button that shows event and cove creation options
struct FloatingActionView: View {
    let coveId: String?
    let coveName: String?
    var onEventCreated: (() -> Void)? = nil
    @State private var showMenu = false
    @State private var showCreatePostSheet = false
    @State private var navigateToCreateEvent = false
    @State private var navigateToCreateCove = false
    @EnvironmentObject private var appController: AppController

    // MARK: - Initializer
    init(coveId: String? = nil, coveName: String? = nil, onEventCreated: (() -> Void)? = nil) {
        self.coveId = coveId
        self.coveName = coveName
        self.onEventCreated = onEventCreated
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            // Menu options - appear above the + button
            if showMenu {
                VStack(alignment: .trailing, spacing: 12) {
                    // Cove option – only at top level (no coveId) and for verified users
                    if appController.profileModel.verified && coveId == nil {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showMenu = false
                            navigateToCreateCove = true
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
                    }

                    // Event option - only show when there's a cove context
                    if coveId != nil {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showMenu = false
                        navigateToCreateEvent = true
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

                    // Post option - only show when there's a cove context
                    if coveId != nil {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showMenu = false
                        showCreatePostSheet = true
                    }) {
                        HStack() {
                            Text("post")
                                .font(.LibreBodoni(size: 25))
                                .foregroundColor(.white)
                            Spacer()
                            Image("post_icon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
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
                }
                .frame(maxWidth: 170) // Increase width to prevent text wrapping
                .transition(.opacity.combined(with: .scale))
            }

            // Main + button - always visible at bottom right
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
        .navigationDestination(isPresented: $navigateToCreateEvent) {
            CreateEventView(coveId: coveId, onEventCreated: onEventCreated)
        }
        .navigationDestination(isPresented: $navigateToCreateCove) {
            CreateCoveView()
        }
        .sheet(isPresented: $showCreatePostSheet) {
            CreatePostView(coveId: coveId, coveName: coveName, onPostCreated: onEventCreated)
                .presentationDetents([.medium, .large])
                .interactiveDismissDisabled(true)
        }
    }
}

#Preview {
    FloatingActionView(coveId: nil, coveName: nil, onEventCreated: nil)
        .environmentObject(AppController.shared)
}
