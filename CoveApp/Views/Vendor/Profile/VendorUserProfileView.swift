//
//  VendorUserProfileView.swift
//  Cove
//
//  Vendor user profile page (accessed via circle button)

import SwiftUI

struct VendorUserProfileView: View {
    @EnvironmentObject var vendorController: VendorController
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // User Profile Header
                        VStack(spacing: 16) {
                            // Profile Photo Placeholder
                            Circle()
                                .fill(Colors.primaryDark.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(vendorController.vendorProfile?.name?.prefix(1).uppercased() ?? "U")
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
                        
                        // User Info
                        VStack(spacing: 16) {
                            Text("Personal Information")
                                .font(.LibreBodoniBold(size: 18))
                                .foregroundColor(Colors.primaryDark)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                // Name
                                VendorInfoRow(
                                    icon: "person",
                                    label: "Name",
                                    value: vendorController.vendorProfile?.name ?? ""
                                )
                                
                                // Phone
                                VendorInfoRow(
                                    icon: "phone",
                                    label: "Phone",
                                    value: vendorController.vendorProfile?.phone ?? ""
                                )
                                
                                // Role
                                VendorInfoRow(
                                    icon: "person.badge.key",
                                    label: "Role",
                                    value: roleDisplayName(vendorController.vendorProfile?.role ?? .member)
                                )
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Organization Info
                        VStack(spacing: 16) {
                            Text("Organization")
                                .font(.LibreBodoniBold(size: 18))
                                .foregroundColor(Colors.primaryDark)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                // Organization Name
                                VendorInfoRow(
                                    icon: "building.2",
                                    label: "Organization",
                                    value: vendorController.vendorProfile?.vendor?.organizationName ?? ""
                                )
                                
                                // Location
                                VendorInfoRow(
                                    icon: "location",
                                    label: "Location",
                                    value: vendorController.vendorProfile?.vendor?.city ?? ""
                                )
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationTitle("Profile")
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
            vendorController.fetchVendorProfile()
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
        case .member: return .green
        }
    }
}

#Preview {
    VendorUserProfileView()
        .environmentObject(VendorController.shared)
}
