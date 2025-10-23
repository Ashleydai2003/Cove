//
//  MatchingTabView.swift
//  Cove
//
//  Main view for AI Matching System (replaces ChatView)
//

import SwiftUI

struct MatchingTabView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject private var surveyModel = SurveyModel()
    @StateObject private var intentionModel = IntentionModel()
    @StateObject private var matchModel = MatchModel()
    @EnvironmentObject var appController: AppController
    
    @State private var showOptIn: Bool = false
    @State private var hasLoadedInitialState: Bool = false
    @State private var isLoading: Bool = true
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Colors.background.ignoresSafeArea()
                
                // Router based on state with fade transitions
                Group {
                    if isLoading {
                        // Show loading state while determining user status
                        VStack {
                            ProgressView()
                                .tint(Colors.primaryDark)
                                .scaleEffect(1.5)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                    } else if showOptIn {
                        // Show opt-in screen only for new users (no survey completed and no intention)
                        MatchingOptInView(onNext: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showOptIn = false
                            }
                        })
                        .transition(.opacity)
                    } else if !surveyModel.isComplete {
                        SurveyFlowView(model: surveyModel)
                            .transition(.opacity)
                    } else if matchModel.currentMatch != nil {
                        MatchedView(match: matchModel.currentMatch!)
                            .transition(.opacity)
                    } else if intentionModel.currentIntention == nil {
                        IntentionComposerView(model: intentionModel)
                            .transition(.opacity)
                    } else {
                        PoolStatusView(model: intentionModel, matchModel: matchModel)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.8), value: intentionModel.currentIntention)
            }
            .onAppear {
                // Load initial state first
                if !hasLoadedInitialState {
                    hasLoadedInitialState = true
                    loadInitialState()
                }
            }
            .onChange(of: surveyModel.isComplete) { _, isComplete in
                if isComplete {
                    print("📋 [MatchingTab] Survey completed, reloading intentions")
                    // Reload intention after survey complete
                    intentionModel.load()
                }
            }
            .onChange(of: intentionModel.currentIntention) { oldValue, newValue in
                print("🔄 [MatchingTab] Intention changed!")
                print("   - Old value: \(oldValue?.id ?? "nil")")
                print("   - New value: \(newValue?.id ?? "nil")")
                
                if newValue != nil && oldValue == nil {
                    print("🎯 [MatchingTab] ✨ Intention created! Transitioning to pool status view...")
                } else if newValue != nil {
                    print("🎯 [MatchingTab] ✨ Intention updated, already showing pool status")
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private func loadInitialState() {
        print("🔄 [MatchingTab] Loading initial state...")
        
        // Load all models
        surveyModel.load()
        intentionModel.load()
        matchModel.load()
        
        // Check if user should see opt-in screen
        // Only show opt-in if: no survey completed AND no intention exists
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let shouldShowOptIn = !surveyModel.isComplete && intentionModel.currentIntention == nil
            
            print("📊 [MatchingTab] State check:")
            print("   - Survey complete: \(surveyModel.isComplete)")
            print("   - Has intention: \(intentionModel.currentIntention != nil)")
            print("   - Should show opt-in: \(shouldShowOptIn)")
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = false
                showOptIn = shouldShowOptIn
            }
        }
    }
}

#Preview {
    MatchingTabView(navigationPath: .constant(NavigationPath()))
        .environmentObject(AppController.shared)
}

