//
//  OrganizationCodeSheet.swift
//  Cove
//
//  Sheet for displaying and rotating organization code

import SwiftUI

struct VendorOrganizationCodeSheet: View {
    let currentCode: String
    let onRotateCode: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingRotateConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Colors.background.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Organization Code")
                            .font(.LibreBodoniBold(size: 24))
                            .foregroundColor(Colors.primaryDark)
                        
                        Text("Share this code with team members to join your organization")
                            .font(.LeagueSpartan(size: 16))
                            .foregroundColor(Colors.primaryDark.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 40)
                    
                    // Code Display
                    VStack(spacing: 16) {
                        Text(currentCode)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(Colors.primaryDark)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Colors.primaryDark.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Colors.primaryDark.opacity(0.3), lineWidth: 2)
                                    )
                            )
                        
                        Button(action: {
                            UIPasteboard.general.string = currentCode
                        }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy Code")
                            }
                            .font(.LeagueSpartan(size: 16))
                            .foregroundColor(Colors.primaryDark)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Colors.primaryDark.opacity(0.1))
                            )
                        }
                    }
                    
                    Spacer()
                    
                    // Rotate Code Button
                    Button(action: {
                        showingRotateConfirmation = true
                    }) {
                        Text("Rotate Code")
                            .font(.LeagueSpartan(size: 16))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 32)
            }
            .navigationTitle("Organization Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Rotate Organization Code", isPresented: $showingRotateConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Rotate", role: .destructive) {
                onRotateCode()
                dismiss()
            }
        } message: {
            Text("This will generate a new code and invalidate the current one. Make sure to share the new code with your team members.")
        }
    }
}

#Preview {
    VendorOrganizationCodeSheet(
        currentCode: "ABCD-1234",
        onRotateCode: {}
    )
}
