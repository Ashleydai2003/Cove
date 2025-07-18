//
//  DataDiffing.swift
//  Cove
//
//  Created by Assistant for smart data diffing to prevent unnecessary UI updates

import Foundation

/// Protocol for types that can be compared for content changes
protocol ContentComparable {
    /// Returns true if the content of this object is significantly different from another
    func hasContentChanged(from other: Self) -> Bool
}

/// Extension to provide array diffing functionality
extension Array where Element: ContentComparable & Identifiable {
    /// Returns true if this array has meaningful changes compared to another array
    /// - Only checks items that exist in both arrays for content changes
    /// - Returns true if array count changed or any existing items have content changes
    func hasContentChanged(from other: [Element]) -> Bool {
        // If count changed, definitely has changes
        if self.count != other.count {
            return true
        }

        // Create lookup dictionaries for efficient comparison
        let currentDict = Dictionary(uniqueKeysWithValues: self.map { ($0.id, $0) })
        let otherDict = Dictionary(uniqueKeysWithValues: other.map { ($0.id, $0) })

        // Check if any existing items have content changes
        for (id, currentItem) in currentDict {
            if let otherItem = otherDict[id] {
                if currentItem.hasContentChanged(from: otherItem) {
                    return true
                }
            } else {
                // Item exists in current but not in other (new item)
                return true
            }
        }

        // Check for items that were removed
        for id in otherDict.keys {
            if currentDict[id] == nil {
                return true
            }
        }

        return false
    }
}

/// Extension to provide simple value diffing
extension Array where Element: Equatable {
    /// Returns true if this array is different from another array
    func hasChanged(from other: [Element]) -> Bool {
        return self != other
    }
}

/// Smart update function that only triggers UI updates when content actually changes
/// - Parameter currentData: The current data in the view model
/// - Parameter newData: The new data from the API
/// - Parameter updateAction: Closure to update the data (only called if data changed)
/// - Returns: True if data was updated, false if no changes detected
@discardableResult
func updateIfChanged<T: ContentComparable & Identifiable>(
    current currentData: [T],
    new newData: [T],
    update updateAction: () -> Void
) -> Bool {
    if newData.hasContentChanged(from: currentData) {
        Log.debug("DataDiffing: Data changed – refreshing UI")
        updateAction()
        return true
    } else {
        return false
    }
}

/// Smart update function for equatable data
@discardableResult
func updateIfChanged<T: Equatable>(
    current currentData: [T],
    new newData: [T],
    update updateAction: () -> Void
) -> Bool {
    if newData.hasChanged(from: currentData) {
        Log.debug("Data has changes detected - updating UI")
        updateAction()
        return true
    } else {
        return false
    }
}

/// Smart update function for single objects
@discardableResult
func updateIfChanged<T: ContentComparable>(
    current currentData: T?,
    new newData: T,
    update updateAction: () -> Void
) -> Bool {
    if let current = currentData {
        if newData.hasContentChanged(from: current) {
            Log.debug("Object has changes detected - updating UI")
            updateAction()
            return true
        } else {
            return false
        }
    } else {
        // No current data, always update
        Log.debug("No existing data - updating UI")
        updateAction()
        return true
    }
}
