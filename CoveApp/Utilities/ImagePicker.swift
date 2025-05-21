//
//  ImagePicker.swift
//  Cove
//
//  Created by Sheng Moua on 5/15/25.
//


import SwiftUI
import PhotosUI

/// Wraps PHPickerViewController for SwiftUI
struct ImagePicker: UIViewControllerRepresentable {
  @Binding var image: UIImage?
  @Environment(\.presentationMode) var presentationMode

  func makeUIViewController(context: Context) -> PHPickerViewController {
    var config = PHPickerConfiguration(photoLibrary: .shared())
    config.filter = .images
    config.selectionLimit = 1

    let picker = PHPickerViewController(configuration: config)
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, PHPickerViewControllerDelegate {
    let parent: ImagePicker
    init(_ parent: ImagePicker) { self.parent = parent }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      parent.presentationMode.wrappedValue.dismiss()
      guard let item = results.first?.itemProvider,
            item.canLoadObject(ofClass: UIImage.self)
      else { return }
      item.loadObject(ofClass: UIImage.self) { img, _ in
        DispatchQueue.main.async {
          self.parent.image = img as? UIImage
        }
      }
    }
  }
}
