//
//  VendorModels.swift
//  Cove
//
//  Models for vendor accounts and organizations
//

import Foundation

// MARK: - Vendor Organization
struct Vendor: Codable, Identifiable {
    let id: String
    let organizationName: String
    let website: String?
    let primaryContactEmail: String
    let city: String
    let latitude: Double?
    let longitude: Double?
    let currentCode: String?
    let codeRotatedAt: Date
    let createdAt: Date
}

// MARK: - Vendor User
struct VendorUser: Codable, Identifiable {
    let id: String
    let name: String?
    let phone: String
    let vendorId: String?
    let role: VendorRole
    let onboarding: Bool
    let verified: Bool
    let profilePhotoID: String?
    let createdAt: Date
}

// MARK: - Vendor Role
enum VendorRole: String, Codable {
    case member = "MEMBER"
    case admin = "ADMIN"
}

// MARK: - API Response Models

struct VendorLoginResponse: Codable {
    let message: String
    let vendorUser: VendorUserLoginInfo
}

struct VendorUserLoginInfo: Codable {
    let uid: String
    let onboarding: Bool
    let verified: Bool
    let vendorId: String?
    let role: VendorRole
}

struct ValidateVendorCodeResponse: Codable {
    let valid: Bool
    let vendorId: String?
    let organizationName: String?
    let message: String?
}

struct CreateVendorOrganizationResponse: Codable {
    let message: String
    let vendor: CreatedVendorInfo
}

struct CreatedVendorInfo: Codable {
    let id: String
    let organizationName: String
    let code: String
}

struct VendorProfileResponse: Codable {
    let vendorUser: VendorUserProfile
}

struct VendorUserProfile: Codable {
    let id: String
    let name: String?
    let phone: String
    let role: VendorRole
    let vendorId: String?
    let profilePhotoID: String?
    let vendor: VendorOrganizationInfo?
}

struct VendorOrganizationInfo: Codable {
    let id: String
    let organizationName: String
    let website: String?
    let primaryContactEmail: String
    let city: String
    let currentCode: String?
    let codeRotatedAt: Date
    let coverPhotoID: String?
}

struct RotateCodeResponse: Codable {
    let message: String
    let newCode: String
    let codeRotatedAt: Date
}

struct VendorMembersResponse: Codable {
    let members: [VendorMemberInfo]
}

struct VendorMemberInfo: Codable, Identifiable {
    let id: String
    let name: String?
    let phone: String
    let role: VendorRole
    let profilePhotoID: String?
    let createdAt: Date
}

