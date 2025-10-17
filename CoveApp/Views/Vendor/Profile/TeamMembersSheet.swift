//
//  TeamMembersSheet.swift
//  Cove
//
//  Sheet for displaying organization team members

import SwiftUI

struct VendorTeamMembersSheet: View {
    @EnvironmentObject var vendorController: VendorController
    @Environment(\.dismiss) private var dismiss
    @State private var members: [VendorMemberInfo] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Colors.background.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(members) { member in
                                VendorMemberRow(member: member)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Team Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            fetchMembers()
        }
    }
    
    private func fetchMembers() {
        VendorNetworkManager.shared.getVendorMembers { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    members = response.members
                case .failure(let error):
                    vendorController.errorMessage = "Failed to load members: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct VendorMemberRow: View {
    let member: VendorMemberInfo
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Photo
                Circle()
                    .fill(Colors.primaryDark.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text((member.name ?? "U").prefix(1).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Colors.primaryDark)
                    )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name ?? "Unknown")
                    .font(.LeagueSpartan(size: 16))
                    .foregroundColor(Colors.primaryDark)
                
                Text(roleDisplayName(member.role))
                    .font(.LeagueSpartan(size: 12))
                    .foregroundColor(Colors.primaryDark.opacity(0.6))
            }
            
            Spacer()
            
            // Role Badge
            Text(roleDisplayName(member.role))
                .font(.LeagueSpartan(size: 12))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(roleColor(member.role))
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    private func roleDisplayName(_ role: VendorRole) -> String {
        switch role {
        case .admin: return "Admin"
        case .member: return "Member"
        }
    }
    
    private func roleColor(_ role: VendorRole) -> Color {
        switch role {
        case .admin: return .blue
        case .member: return .green
        }
    }
}

#Preview {
    VendorTeamMembersSheet()
        .environmentObject(VendorController.shared)
}
