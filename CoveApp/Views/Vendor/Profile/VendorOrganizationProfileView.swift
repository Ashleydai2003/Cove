//
//  VendorOrganizationProfileView.swift
//  Cove
//
//  Vendor organization profile page (main profile tab)

import SwiftUI

struct VendorOrganizationProfileView: View {
    @EnvironmentObject var vendorController: VendorController
    @Binding var showingUserProfile: Bool
    @Binding var navigationPath: NavigationPath
    @State private var showCodeSheet: Bool = false
    @State private var showMembersSheet: Bool = false
    @State private var isRotatingCode: Bool = false
    @State private var showRotateConfirmation: Bool = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Organization Header
                        VStack(spacing: 16) {
                            // Organization Logo Placeholder
                            Circle()
                                .fill(Colors.primaryDark.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(vendorController.vendorProfile?.vendor?.organizationName.prefix(1).uppercased() ?? "O")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(Colors.primaryDark)
                                )
                            
                            // Organization Name
                            Text(vendorController.vendorProfile?.vendor?.organizationName ?? "Organization")
                                .font(.LibreBodoniBold(size: 24))
                                .foregroundColor(Colors.primaryDark)
                            
                            // Location
                            if let city = vendorController.vendorProfile?.vendor?.city {
                                Text(city)
                                    .font(.LeagueSpartan(size: 16))
                                    .foregroundColor(Colors.primaryDark.opacity(0.7))
                            }
                        }
                        .padding(.top, 32)
                        
                        Divider()
                            .padding(.horizontal, 32)
                        
                        // Organization Info
                        VStack(spacing: 16) {
                            Text("Organization Details")
                                .font(.LibreBodoniBold(size: 18))
                                .foregroundColor(Colors.primaryDark)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                // Organization Name
                                VendorInfoRow(
                                    icon: "building.2",
                                    label: "Name",
                                    value: vendorController.vendorProfile?.vendor?.organizationName ?? ""
                                )
                                
                                // Location
                                VendorInfoRow(
                                    icon: "location",
                                    label: "Location",
                                    value: vendorController.vendorProfile?.vendor?.city ?? ""
                                )
                                
                                // Website
                                if let website = vendorController.vendorProfile?.vendor?.website, !website.isEmpty {
                                    VendorInfoRow(
                                        icon: "globe",
                                        label: "Website",
                                        value: website
                                    )
                                }
                                
                                // Primary Contact Email
                                VendorInfoRow(
                                    icon: "envelope",
                                    label: "Contact Email",
                                    value: vendorController.vendorProfile?.vendor?.primaryContactEmail ?? ""
                                )
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Organization Code Section
                        VStack(spacing: 16) {
                            Text("Organization Code")
                                .font(.LibreBodoniBold(size: 18))
                                .foregroundColor(Colors.primaryDark)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                // Current Code
                                Button(action: {
                                    showCodeSheet = true
                                }) {
                                    VendorActionRow(
                                        icon: "key",
                                        title: "View Organization Code",
                                        subtitle: "Share with team members to join"
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // View Members
                                Button(action: {
                                    showMembersSheet = true
                                }) {
                                    VendorActionRow(
                                        icon: "person.2",
                                        title: "Team Members",
                                        subtitle: "View organization members"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 32)
                        
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
            .navigationTitle("Organization")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingUserProfile = true
                    }) {
                        Circle()
                            .fill(Colors.primaryDark.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(vendorController.vendorProfile?.name?.prefix(1).uppercased() ?? "U")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Colors.primaryDark)
                            )
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCodeSheet) {
            VendorOrganizationCodeSheet(
                currentCode: vendorController.vendorProfile?.vendor?.currentCode ?? "",
                onRotateCode: rotateCode
            )
        }
        .sheet(isPresented: $showMembersSheet) {
            VendorTeamMembersSheet()
        }
        .onAppear {
            vendorController.fetchVendorProfile()
        }
    }
    
    private func rotateCode() {
        isRotatingCode = true
        
        VendorNetworkManager.shared.rotateVendorCode { result in
            DispatchQueue.main.async {
                isRotatingCode = false
                
                switch result {
                case .success:
                    // Refresh profile to get new code
                    vendorController.fetchVendorProfile()
                case .failure(let error):
                    vendorController.errorMessage = "Failed to rotate code: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Info Row Component
struct VendorInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Colors.primaryDark)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.LeagueSpartan(size: 12))
                    .foregroundColor(Colors.primaryDark.opacity(0.6))
                
                Text(value)
                    .font(.LeagueSpartan(size: 16))
                    .foregroundColor(Colors.primaryDark)
            }
            
            Spacer()
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
}

// MARK: - Action Row Component
struct VendorActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Colors.primaryDark)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.LeagueSpartan(size: 16))
                    .foregroundColor(Colors.primaryDark)
                
                Text(subtitle)
                    .font(.LeagueSpartan(size: 12))
                    .foregroundColor(Colors.primaryDark.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Colors.primaryDark.opacity(0.4))
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
}

#Preview {
    VendorOrganizationProfileView(
        showingUserProfile: .constant(false),
        navigationPath: .constant(NavigationPath())
    )
    .environmentObject(VendorController.shared)
}
