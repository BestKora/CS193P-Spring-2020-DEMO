//
//  EmojiArtDocumentViewMacOS.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 6/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

// nothing Mac-specific in EmojiArtDocumentView
// other than that we use NSImage instead of UIImage on Mac

typealias UIImage = NSImage

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument

    var body: some View {
        EmojiArtDocumentViewShared(document: document)
    }
}

