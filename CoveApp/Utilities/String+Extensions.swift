import Foundation

extension String {
    /// Converts the string to lowercase and removes any leading/trailing whitespace
    var normalized: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    /// Converts the string to lowercase while preserving the original string if empty
    var lowercaseIfNotEmpty: String {
        isEmpty ? self : self.lowercased()
    }
    
    /// Filters the string to only allow letters and hyphens, then converts to lowercase
    var lettersAndHyphensOnly: String {
        self.filter { $0.isLetter || $0 == "-" }.lowercased()
    }
} 