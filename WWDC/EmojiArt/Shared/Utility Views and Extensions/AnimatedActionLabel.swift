//
//  AnimatedActionLabel.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 6/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

// a Label that performs withAnimation a closure when tapped on
// only supports systemImage version of Label for now

struct AnimatedActionLabel: View {
    let title: String
    let systemImage: String
    let onTap: (() -> Void)?
    
    init(_ title: String, systemImage: String, onTap: (() -> Void)? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.onTap = onTap
    }
    
    init(_ title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
        self.onTap = nil
    }

    var body: some View {
        Button {
            if let onTap = self.onTap {
                withAnimation {
                    onTap()
                }
            }
        } label: {
            Label(title, systemImage: systemImage)
        }
    }
}

struct AnimatedLabelItem_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedActionLabel("Test", systemImage: "circle")
            .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/150.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/30.0/*@END_MENU_TOKEN@*/))
    }
}
