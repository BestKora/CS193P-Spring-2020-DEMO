//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

// no significant changes here post-quarter
// (other than those mentioned in EmojiArtDocument)
// (and those made as a result of the new PaletteChooser)

// Gesture and Drag/Drop code
// was moved out into their own files to clean up this file
// and there was a small amount of code cleanup
// (e.g. remove "self." everywhere)

// notice that this has been renamed with Shared on the end
// because this app is now both an iOS app and a macOS app
// and the non-"Shared" version is now platform-dependent
// (mostly because there's a camera/photo-library option only on iOS)

struct EmojiArtDocumentViewShared: View {
    @Environment(\.undoManager) var undoManager // new (see EmojiArtDocument)
    @ObservedObject var document: EmojiArtDocument
        
    // new: added @ScaledMetric this this line of code
    // so our default emoji size now scales with the user's font size preference
    @ScaledMetric var defaultEmojiSize: CGFloat = 40
    
    // zoom and panOffset have moved back here from EmojiArtDocument
    // note that in order to store CGSize or CGFloat in a @SceneStorage
    // we have to make CGSize and CGFloat RawRepresentable
    // (see EmojiArtExtensions.swift for that)
    @SceneStorage("EmojiArtDocumentView.panOffset") var steadyStatePanOffset = CGSize.zero
    @SceneStorage("EmojiArtDocumentView.zoom") var steadyStateZoomScale: CGFloat = 1
    
    var body: some View {
        VStack {
            documentBody
            palette
        }
    }
    
    private var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .offset(panOffset)
                )
                .gesture(doubleTapToZoom(in: geometry.size))
                if document.isFetchingBackground {
                    Image(systemName: "hourglass").imageScale(.large).spinning()
                } else {
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .font(animatableWithSize: emoji.fontSize * zoomScale)
                            .position(position(for: emoji, in: geometry.size))
                    }
                }
            }
            .clipped()
            .gesture(panGesture())
            .gesture(zoomGesture())
            .edgesIgnoringSafeArea([.horizontal, .bottom])
            .onReceive(document.$backgroundImage) { image in
                zoomToFit(image, in: geometry.size)
            }
            // new: .onDrop now takes UniformTypeIdentifiers
            .onDrop(of: [.url,.utf8PlainText,.image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
        }
            .zIndex(-1)
            .frame(minWidth: 350, minHeight: 350)
    }
    
    private var palette: some View {
        // new (see PaletteChooser.swift)
        PaletteChooser()
            .environmentObject(PaletteStore.shared)
            .font(Font.system(size: defaultEmojiSize))
    }
    
    // converts from EmojiArt location to view coordinate space
    private func position(for emoji: EmojiArtModel.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        return location
    }
    
    // drop-handling code lives in EmojiArtDocumentView+Drop
    
    // gesture code lives in EmojiArtDocumentView+Gestures
    
    @GestureState var gestureZoomScale: CGFloat = 1.0
    @GestureState var gesturePanOffset: CGSize = .zero
}
