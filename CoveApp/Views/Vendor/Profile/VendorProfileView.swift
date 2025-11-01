//
//  VendorProfileView.swift
//  Cove
//
//  Vendor user profile page with organization management
//

import SwiftUI

struct VendorProfileView: View {
    @EnvironmentObject var vendorController: VendorController
    @State private var showCodeSheet: Bool = false
    @State private var showMembersSheet: Bool = false
    @State private var isRotatingCode: Bool = false
    @State private var showRotateConfirmation: Bool = false
    
    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Photo Placeholder
                        Circle()
                            .fill(Colors.primaryDark.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(vendorController.vendorProfile?.name?.prefix(1).uppercased() ?? "V")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(Colors.primaryDark)
                            )
                        
                        // Name
                        Text(vendorController.vendorProfile?.name ?? "Vendor User")
                            .font(.LibreBodoniBold(size: 24))
                            .foregroundColor(Colors.primaryDark)
                        
                        // Role Badge
                        if let role = vendorController.vendorProfile?.role {
                            Text(roleDisplayName(role))
                                .font(.LeagueSpartan(size: 13))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(roleColor(role))
                                )
                        }
                    }
                    .padding(.top, 32)
                    
                    Divider()
                        .padding(.horizontal, 32)
                    
                    // Organization Info
                    VStack(spacing: 16) {
                        Text("Organization")
                            .font(.LibreBodoniBold(size: 18))
                            .foregroundColor(Colors.primaryDark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            // Organization Name
                            InfoRow(
                                icon: "building.2",
                                label: "Name",
                                value: vendorController.vendorProfile?.vendor?.organizationName ?? ""
                            )
                            
                            // Location
                            InfoRow(
                                icon: "location",
                                label: "Location",
                                value: vendorController.vendorProfile?.vendor?.city ?? ""
                            )
                            
                            // Website
                            if let website = vendorController.vendorProfile?.vendor?.website {
                                InfoRow(
                                    icon: "globe",
                                    label: "Website",
                                    value: website
                                )
                            }
                            
                            // Email
                            InfoRow(
                                icon: "envelope",
                                label: "Contact Email",
                                value: vendorController.vendorProfile?.vendor?.primaryContactEmail ?? ""
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Admin Actions (only for ADMIN)
                    if let role = vendorController.vendorProfile?.role,
                       role == .admin {
                        VStack(spacing: 16) {
                            Text("Management")
                                .font(.LibreBodoniBold(size: 18))
                                .foregroundColor(Colors.primaryDark)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                // View/Rotate Code
                                Button(action: {
                                    showCodeSheet = true
                                }) {
                                    ActionRow(
                                        icon: "qrcode",
                                        title: "Organization Code",
                                        subtitle: "View or rotate invitation code"
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // View Members
                                Button(action: {
                                    showMembersSheet = true
                                }) {
                                    ActionRow(
                                        icon: "person.2",
                                        title: "Team Members",
                                        subtitle: "View organization members"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Sign Out Button
                    Button(action: {
                        vendorController.signOut()
                    }) {
                        Text("sign out")
                            .font(.LibreBodoniBold(size: 16))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showCodeSheet) {
            OrganizationCodeSheet(
                currentCode: vendorController.vendorProfile?.vendor?.currentCode ?? "",
                onRotateCode: rotateCode
            )
        }
        .sheet(isPresented: $showMembersSheet) {
            TeamMembersSheet()
        }
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
        case .member: return .gray
        }
    }
    
    private func rotateCode() {
        isRotatingCode = true
        
        VendorNetworkManager.shared.rotateVendorCode { [self] result in
            DispatchQueue.main.async {
                isRotatingCode = false
                
                switch result {
                case .success:
                    // Update the profile with new code
                    vendorController.fetchVendorProfile()
                case .failure(let error):
                    vendorController.errorMessage = "Error rotating code: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Colors.primaryDark.opacity(0.6))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.LeagueSpartan(size: 13))
                    .foregroundColor(Colors.primaryDark.opacity(0.6))
                
                Text(value)
                    .font(.LibreBodoni(size: 16))
                    .foregroundColor(Colors.primaryDark)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct ActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Colors.primaryDark)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundColor(Colors.primaryDark)
                
                Text(subtitle)
                    .font(.LeagueSpartan(size: 13))
                    .foregroundColor(Colors.primaryDark.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Colors.primaryDark.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Organization Code Sheet

struct OrganizationCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let currentCode: String
    let onRotateCode: () -> Void
    @State private var showRotateConfirmation: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Colors.background.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Organization Code")
                            .font(.LibreBodoniBold(size: 20))
                            .foregroundColor(Colors.primaryDark)
                        
                        Text(currentCode)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(Colors.primaryDark)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Colors.primaryDark.opacity(0.1))
                            )
                        
                        Text("Share this code with team members to join your organization")
                            .font(.LeagueSpartan(size: 14))
                            .foregroundColor(Colors.k0B0B0B)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                    
                    // Rotate Code Button (ADMIN only)
                    Button(action: {
                        showRotateConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Rotate Code")
                        }
                        .font(.LibreBodoniBold(size: 16))
                        .foregroundColor(Colors.primaryDark)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Colors.primaryDark.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Rotate Code?", isPresented: $showRotateConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Rotate", role: .destructive) {
                onRotateCode()
                dismiss()
            }
        } message: {
            Text("This will generate a new code and invalidate the old one. Team members with the old code won't be able to join.")
        }
    }
}

// MARK: - Team Members Sheet

struct TeamMembersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var members: [VendorMemberInfo] = []
    @State private var isLoading: Bool = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Colors.background.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(Colors.primaryDark)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(members) { member in
                                MemberRow(member: member)
                            }
                        }
                        .padding(.horizontal, 20)
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
                    print("Error fetching members: \(error)")
                }
            }
        }
    }
}

struct MemberRow: View {
    let member: VendorMemberInfo
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Photo Placeholder
            Circle()
                .fill(Colors.primaryDark.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(member.name?.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Colors.primaryDark)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name ?? "Unknown")
                    .font(.LibreBodoniBold(size: 16))
                    .foregroundColor(Colors.primaryDark)
                
                Text(roleDisplayName(member.role))
                    .font(.LeagueSpartan(size: 13))
                    .foregroundColor(roleColor(member.role))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
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
        case .member: return .gray
        }
    }
}

