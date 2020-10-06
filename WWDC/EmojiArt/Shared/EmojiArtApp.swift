//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 6/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

// new
// big change here from what was presented in lecture:
// a pure SwiftUI application
// which fully handles editing multiple EmojiArt documents
// and which works on both iOS and macOS
// (notice no SceneDelegate/AppDelegate stuff at all here)

@main
struct EmojiArtApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: EmojiArtDocument.init)
            /*    { file in
            EmojiArtDocumentView(document: file.document)
        }*/
        { config in
            EmojiArtDocumentView(document: config.document)
        }
    }
}
