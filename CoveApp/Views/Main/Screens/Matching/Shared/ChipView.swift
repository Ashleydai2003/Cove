//
//  ChipView.swift
//  Cove
//
//  Reusable chip component for matching system
//

import SwiftUI

struct ChipView: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Colors.primaryDark)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Colors.primaryDark : Color.gray.opacity(0.1))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Colors.primaryDark : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct ChipSelector: View {
    let title: String?
    let options: [String]
    @Binding var selected: [String]
    let maxSelection: Int?
    let isMustHave: Bool
    let onMustHaveToggle: (() -> Void)?
    
    init(title: String? = nil,
         options: [String],
         selected: Binding<[String]>,
         maxSelection: Int? = nil,
         isMustHave: Bool = false,
         onMustHaveToggle: (() -> Void)? = nil) {
        self.title = title
        self.options = options
        self._selected = selected
        self.maxSelection = maxSelection
        self.isMustHave = isMustHave
        self.onMustHaveToggle = onMustHaveToggle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                HStack {
                    Text(title)
                        .font(.LibreBodoniSemiBold(size: 18))
                        .foregroundColor(Colors.primaryDark)
                    
                    Spacer()
                    
                    if let onToggle = onMustHaveToggle {
                        Button(action: onToggle) {
                            HStack(spacing: 4) {
                                Image(systemName: isMustHave ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isMustHave ? Colors.primaryDark : .gray)
                                Text("Must-have")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    ChipView(
                        text: option,
                        isSelected: selected.contains(option),
                        action: {
                            toggleSelection(option)
                        }
                    )
                }
            }
        }
    }
    
    private func toggleSelection(_ option: String) {
        if selected.contains(option) {
            selected.removeAll { $0 == option }
        } else {
            if let maxSelection = maxSelection, selected.count >= maxSelection {
                // Remove first selection if at max
                selected.removeFirst()
            }
            selected.append(option)
        }
    }
}

// MARK: - Flow Layout for wrapping chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    // New line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(
                width: maxWidth,
                height: currentY + lineHeight
            )
        }
    }
}

#Preview {
    VStack {
        ChipSelector(
            title: "Activities",
            options: ["Coffee", "Live music", "Art walk"],
            selected: .constant(["Coffee"]),
            maxSelection: 2
        )
    }
    .padding()
}

