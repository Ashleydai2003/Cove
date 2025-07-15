# Archived Onboarding Files

This directory contains onboarding-related files that are no longer part of the active onboarding flow but have been preserved for potential future use.

## Files Archived

### Screens/
- **AdminVerifyView.swift** - Admin verification screen for admin users
- **ContactsView.swift** - Contact import and friend matching functionality  
- **ProfilePicAndPhotosView.swift** - Extended profile picture upload with multiple photos
- **UserLocationView.swift** - Location selection screen with map interface

### ViewModels/
- **UserLocationViewModel.swift** - View model for UserLocationView (location/map functionality)
- **BaseViewModel.swift** - Base class for view models (only used by UserLocationViewModel)

## Why These Were Archived

These files were moved here as part of onboarding flow cleanup:

1. **Not part of current flow** - The current onboarding sequence is: Login → Phone → OTP → Name → Birthday → Alma Mater → City → Hobbies → Profile Pic → Plugging In
2. **Compilation issues** - Some files had complex expressions causing Swift compiler errors
3. **Unused dependencies** - Referenced removed functions from cleaned up Onboarding.swift
4. **Code organization** - Simplifying the active codebase while preserving potentially useful code

## Current Active Onboarding Flow

1. LoginView.swift
2. UserPhoneNumberView.swift  
3. OtpVerifyView.swift
4. NamePageView.swift
5. BirthdateView.swift
6. AlmaMaterView.swift
7. CitySelectionView.swift
8. HobbiesView.swift
9. ProfilePicView.swift
10. PluggingYouIn.swift

## Notes for Future Development

- These archived files may need imports/dependencies updated if restored
- Some reference removed functions from Onboarding.swift (like storeMoreAboutYou, storeLocation, etc.)
- AdminVerifyView.swift contains admin-related functionality that may be useful for admin flows
- ContactsView.swift has friend import functionality that could be valuable for user growth features

## Last Updated
December 2024 - During onboarding flow cleanup and simplification 