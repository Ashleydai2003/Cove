//
//  SurveyFlowView.swift
//  Cove
//
//  Beautiful card-spinning survey flow
//

import SwiftUI

struct SurveyFlowView: View {
    @ObservedObject var model: SurveyModel
    @State private var currentQuestionIndex = 0
    @State private var showingError = false
    @State private var cardOpacity: Double = 1.0
    @State private var isAnimating = false
    @State private var selectedOptions: Set<String> = []
    
    private var currentQuestion: SurveyQuestion {
        model.questions[currentQuestionIndex]
    }
    
    var body: some View {
        ZStack {
            // Simple background
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Status bar area
                HStack {
                    Text("9:41")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "cellularbars")
                        Image(systemName: "wifi")
                        Image(systemName: "battery.100")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                Spacer()
                
                // Card container - single card only
                SurveyCardView(
                    question: currentQuestion,
                    model: model,
                    isActive: true,
                    selectedOptions: $selectedOptions,
                    onAnswer: { answer in
                        handleAnswer(answer)
                    },
                    onContinue: {
                        handleContinue()
                    }
                )
                .opacity(cardOpacity)
                .animation(.easeInOut(duration: 0.4), value: cardOpacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
        }
        .alert("survey complete", isPresented: $model.isComplete) {
            Button("ok") {}
        } message: {
            Text("thank you for completing the survey!")
        }
        .alert("error", isPresented: $showingError) {
            Button("ok") {}
        } message: {
            Text(model.errorMessage ?? "an error occurred")
        }
    }
    
    private func handleAnswer(_ answer: String) {
        // For single select questions, immediately move to next
        if currentQuestion.type == .singleSelect {
            guard !isAnimating else { return }
            isAnimating = true
            
            // Set the answer
            model.setResponse(
                for: currentQuestion.id,
                value: answer,
                isMustHave: false
            )
            
            moveToNextQuestion()
        } else {
            // For multiselect, toggle the selection
            if selectedOptions.contains(answer) {
                selectedOptions.remove(answer)
            } else {
                // Check if we've hit the max selection limit
                if let maxSelection = currentQuestion.maxSelection, selectedOptions.count >= maxSelection {
                    // Don't allow more selections
                    return
                }
                selectedOptions.insert(answer)
            }
        }
    }
    
    private func handleContinue() {
        guard !isAnimating else { return }
        guard !selectedOptions.isEmpty else { return }
        
        isAnimating = true
        
        // Set the multiselect answer
        model.setResponse(
            for: currentQuestion.id,
            value: Array(selectedOptions),
            isMustHave: false
        )
        
        // Clear selections for next question
        selectedOptions.removeAll()
        
        moveToNextQuestion()
    }
    
    private func moveToNextQuestion() {
        // Fade out animation
        withAnimation(.easeOut(duration: 0.3)) {
            cardOpacity = 0.0
        }
        
        // Move to next question after fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if currentQuestionIndex < model.questions.count - 1 {
                // Update question
                currentQuestionIndex += 1
                
                // Fade in new card
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        cardOpacity = 1.0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isAnimating = false
                    }
                }
            } else {
                // Submit survey
                model.submit { success in
                    if !success {
                        showingError = true
                    }
                    isAnimating = false
                }
            }
        }
    }
}

// MARK: - Survey Card View
struct SurveyCardView: View {
    let question: SurveyQuestion
    @ObservedObject var model: SurveyModel
    let isActive: Bool
    @Binding var selectedOptions: Set<String>
    let onAnswer: (String) -> Void
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Simple card matching the design
            RoundedRectangle(cornerRadius: 20)
                .fill(Colors.primaryDark) // Cove primary dark
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 2)
                )
                .overlay(
                    VStack(spacing: 16) {
                        // Question title - simple and clean
                        Text(question.question.lowercased())
                            .font(.LibreBodoniSemiBold(size: 24))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        // Question subtitle
                        if let subtitle = getSubtitle() {
                            Text(subtitle)
                                .font(.LibreBodoniItalic(size: 16))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                        }
                        
                        // Answer options - scrollable when needed
                        if question.options.count > 6 {
                            // Scrollable for many options
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 8) {
                                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                        ConsistentAnswerButton(
                                            text: option,
                                            totalOptions: question.options.count,
                                            icon: getIconForOption(option, questionId: question.id),
                                            isSelected: selectedOptions.contains(option),
                                            isMultiSelect: question.type == .multiSelect,
                                            action: {
                                                if isActive {
                                                    onAnswer(option)
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        } else {
                            // Non-scrollable for few options
                            VStack(spacing: 8) {
                                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                    ConsistentAnswerButton(
                                        text: option,
                                        totalOptions: question.options.count,
                                        icon: getIconForOption(option, questionId: question.id),
                                        isSelected: selectedOptions.contains(option),
                                        isMultiSelect: question.type == .multiSelect,
                                        action: {
                                            if isActive {
                                                onAnswer(option)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Continue button for multiselect questions
                        if question.type == .multiSelect && !selectedOptions.isEmpty {
                            Button(action: onContinue) {
                                Text("continue")
                                    .font(.LibreBodoniSemiBold(size: 18))
                                    .foregroundColor(Colors.primaryDark)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white)
                                    .cornerRadius(20)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                )
        }
        .frame(width: 320, height: 500)
        .opacity(isActive ? 1.0 : 0.6)
    }
    
    private func getSubtitle() -> String? {
        switch question.id {
        case .energySource:
            return "after a long week, do you recharge by being around people or having time to yourself?"
        case .groupSize:
            return "do you prefer intimate gatherings or bigger groups?"
        case .valuedTraits:
            return "select your top four:"
        case .idealConnection:
            return "what are you looking for in a connection?"
        case .industry:
            return "what field do you work in?"
        case .relationshipStatus:
            return "what's your current relationship status?"
        case .sexualOrientation:
            return "how do you identify?"
        case .musicGenres:
            return "what music do you enjoy?"
        case .drinkingHabits:
            return "what's your relationship with alcohol?"
        }
    }
    
    private func getIconForOption(_ option: String, questionId: SurveyQuestionID) -> String? {
        switch questionId {
        case .energySource:
            if option.lowercased().contains("introvert") {
                return "introvert"
            } else if option.lowercased().contains("ambivert") {
                return "ambivert"
            } else if option.lowercased().contains("extrovert") {
                return "extrovert"
            }
        case .groupSize:
            if option.lowercased().contains("one-on-one") || option.lowercased().contains("small") {
                return "small_group"
            } else if option.lowercased().contains("medium") {
                return "medium_group"
            } else if option.lowercased().contains("large") {
                return "large_group"
            } else if option.lowercased().contains("flexible") || option.lowercased().contains("depends") {
                return "random_group"
            }
        default:
            return nil
        }
        return nil
    }
}

// MARK: - Consistent Answer Button
struct ConsistentAnswerButton: View {
    let text: String
    let totalOptions: Int
    let icon: String?
    let isSelected: Bool
    let isMultiSelect: Bool
    let action: () -> Void
    
    private var pillHeight: CGFloat {
        // Fewer options = thicker pills, more options = thinner pills
        switch totalOptions {
        case 1...3: return 60  // Thick pills for few options
        case 4...6: return 50  // Medium pills
        case 7...10: return 40 // Thinner pills for many options
        default: return 35     // Very thin for many options
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(isSelected ? Colors.primaryDark : .white)
                        .frame(width: 24, height: 24)
                }
                
                Text(text)
                    .font(Fonts.libreBodoni(size: 14))
                    .foregroundColor(isSelected ? Colors.primaryDark : .white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: pillHeight)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.white : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white, lineWidth: 1)
            )
        }
    }
}

#Preview {
    SurveyFlowView(model: SurveyModel())
}

