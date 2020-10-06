//
//  EmojiArtDocumentView_iOS.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 6/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

// here we add some iOS-platform-specific stuff to EmojiArtDocumentViewShared
// and other than some minor code cleanup
// this is unchanged from lecture

// here are the iOS-specific things we do ...

// we need to add our bar button items here since we don't need those on Mac
//  to set the background from the photo library
//  to set the background from the camera
//  to paste the background (for iPhones mostly)
// on iPhone (vs iPad) these might want to be a single button with a context menu
// (since they all do the same thing (set the background))

struct EmojiArtDocumentView: View {
    @Environment(\.undoManager) var undoManager
    @ObservedObject var document: EmojiArtDocument
    
    var body: some View {
        EmojiArtDocumentViewShared(document: document)
            .navigationBarItems(trailing: iOSOnlyToolbarItems)
            .alert(isPresented: $confirmBackgroundPaste, content: confirmBackgroundPasteAlert)
    }
    
    @State var showImagePicker = false
    @State var imagePickerSourceType = UIImagePickerController.SourceType.photoLibrary
    @State var explainBackgroundPaste = false
    @State var confirmBackgroundPaste = false
    
    private var iOSOnlyToolbarItems: some View {
        HStack(spacing: 20) {
            photoLibraryImagePicker
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                cameraImagePicker
            }
            pasteBackgroundImage
        }
        .sheet(isPresented: $showImagePicker) {
            imagePicker
        }
    }
    
    private var photoLibraryImagePicker: some View {
        Image(systemName: "photo").imageScale(.large).foregroundColor(.accentColor)
            .onTapGesture {
                imagePickerSourceType = .photoLibrary
                showImagePicker = true
            }
    }
    
    private var cameraImagePicker: some View {
        Image(systemName: "camera").imageScale(.large).foregroundColor(.accentColor)
            .onTapGesture {
                imagePickerSourceType = .camera
                showImagePicker = true
            }
    }
    
    private var imagePicker: some View {
        ImagePicker(sourceType: imagePickerSourceType) { image in
            if image != nil {
                DispatchQueue.main.async {
                    if let imageData = image?.jpegData(compressionQuality: 1.0) {
                        document.setBackgroundImageData(imageData, undoManager: undoManager)
                    }
                }
            }
            showImagePicker = false
        }
    }
    
    private var pasteBackgroundImage: some View {
        Button(action: {
            if let url = UIPasteboard.general.url, url != document.backgroundURL {
                confirmBackgroundPaste = true
            } else if UIPasteboard.general.image != nil {
                confirmBackgroundPaste = true
            } else {
                explainBackgroundPaste = true
            }
        }, label: {
            Image(systemName: "doc.on.clipboard").imageScale(.large)
                .alert(isPresented: $explainBackgroundPaste) {
                    Alert(
                        title: Text("Paste Background"),
                        message: Text("Copy an image to the clip board and touch this button to make it the background of your document."),
                        dismissButton: .default(Text("OK"))
                    )
                }
        })
    }
    
    private func confirmBackgroundPasteAlert() -> Alert {
        let url = UIPasteboard.general.url
        let pastedThing = url == nil ? "pasted image" : url!.absoluteString
        return Alert(
            title: Text("Paste Background"),
            message: Text("Replace your background with \(pastedThing)?."),
            primaryButton: .default(Text("OK")) {
                if url != nil {
                    document.setBackgroundURL(url, undoManager: undoManager)
                } else if let imageData = UIPasteboard.general.image?.jpegData(compressionQuality: 1.0) {
                    document.setBackgroundImageData(imageData, undoManager: undoManager)
                }
            },
            secondaryButton: .cancel()
        )
    }
}
