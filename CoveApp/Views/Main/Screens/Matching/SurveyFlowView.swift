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
    @State private var cardRotation: Double = 0
    @State private var isAnimating = false
    
    private var currentQuestion: SurveyQuestion {
        model.questions[currentQuestionIndex]
    }
    
    var body: some View {
        ZStack {
            // Simple background
            Color(red: 0.96, green: 0.95, blue: 0.93)
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
                
                // Card container
                ZStack {
                    // Next card (peeking out)
                    if currentQuestionIndex < model.questions.count - 1 {
                        SurveyCardView(
                            question: model.questions[currentQuestionIndex + 1],
                            model: model,
                            isActive: false,
                            onAnswer: { _ in }
                        )
                        .scaleEffect(0.9)
                        .offset(x: 50, y: 20)
                        .opacity(0.7)
                    }
                    
                    // Current card
                    SurveyCardView(
                        question: currentQuestion,
                        model: model,
                        isActive: true,
                        onAnswer: { answer in
                            handleAnswer(answer)
                        }
                    )
                    .rotation3DEffect(
                        .degrees(cardRotation),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .scaleEffect(isAnimating ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.6), value: isAnimating)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
        }
        .alert("Survey Complete", isPresented: $model.isComplete) {
            Button("OK") {}
        } message: {
            Text("Thank you for completing the survey!")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(model.errorMessage ?? "An error occurred")
        }
    }
    
    private func handleAnswer(_ answer: String) {
        guard !isAnimating else { return }
        
        // Set the answer
        model.setResponse(
            for: currentQuestion.id,
            value: answer,
            isMustHave: false
        )
        
        // Beautiful, slower card flip animation
        withAnimation(.easeInOut(duration: 1.2)) {
            cardRotation += 180
            isAnimating = true
        }
        
        // Move to next question after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if currentQuestionIndex < model.questions.count - 1 {
                withAnimation(.easeInOut(duration: 0.8)) {
                    currentQuestionIndex += 1
                    cardRotation = 0
                    isAnimating = false
                }
            } else {
                // Submit survey
                model.submit { success in
                    if !success {
                        showingError = true
                    }
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
    let onAnswer: (String) -> Void
    
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
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                }
                
                Text(text)
                    .font(Fonts.libreBodoni(size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: pillHeight)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white, lineWidth: 1)
            )
        }
    }
}

#Preview {
    SurveyFlowView(model: SurveyModel())
}

