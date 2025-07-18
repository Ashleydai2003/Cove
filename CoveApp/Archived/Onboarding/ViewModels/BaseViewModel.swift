//
//  BaseViewModel.swift
//  Cove
//

import Foundation

class BaseViewModel: NSObject, ObservableObject {

    @Published var showLoadingIndicator: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

}
