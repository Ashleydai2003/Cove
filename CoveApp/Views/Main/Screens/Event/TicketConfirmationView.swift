//
//  TicketConfirmationView.swift
//  Cove
//
//  Created by Ananya Agarwal
import SwiftUI

struct TicketConfirmationView: View {
    let ticketPrice: Float
    let paymentHandle: String?
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Colors.faf8f4.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Text("this is a ticketed event")
                        .font(.LibreBodoniBold(size: 24))
                        .foregroundColor(Colors.primaryDark)
                        .multilineTextAlignment(.center)
                    
                    Text("have you venmoed $\(String(format: "%.2f", ticketPrice)) to the host?")
                        .font(.LibreBodoni(size: 18))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    if let paymentHandle = paymentHandle, !paymentHandle.isEmpty {
                        Text("(@\(paymentHandle))")
                            .font(.LibreBodoni(size: 16))
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                
                // Ticket icon
                Image(systemName: "ticket")
                    .font(.system(size: 48))
                    .foregroundColor(Colors.primaryDark)
                    .padding(.vertical, 8)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: {
                        onConfirm()
                        dismiss()
                    }) {
                        Text("yes!")
                            .font(.LibreBodoni(size: 20))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Colors.primaryDark)
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 8)
                            )
                    }
                    
                    Button(action: {
                        onDismiss()
                        dismiss()
                    }) {
                        Text("not yet")
                            .font(.LibreBodoni(size: 18))
                            .foregroundColor(Colors.primaryDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Colors.primaryDark, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 40)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    TicketConfirmationView(
        ticketPrice: 25.0,
        paymentHandle: "@johndoe",
        onConfirm: { print("Confirmed") },
        onDismiss: { print("Dismissed") }
    )
} 