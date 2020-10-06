//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/29/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        if uiImage != nil {
            #if os(macOS)
            Image(nsImage: uiImage!)
            #else
            Image(uiImage: uiImage!)
            #endif
        }
    }
}
