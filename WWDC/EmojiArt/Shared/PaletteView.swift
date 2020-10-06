//
//  PaletteView.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 6/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

// new

// shows a single Palette
// consisting of its name and its emojis in a horizontally scrolling view
// will be editable if the editing Binding is Identifiable-y the same as our Palette

// this is a little bit of a funky UI for editing palettes
// see the comment for editableName for more on that

struct PaletteView: View
{
    // MARK: Properties & Initialization
    
    @EnvironmentObject private var store: PaletteStore
    @Environment(\.undoManager) var undoManager

    init(_ palette: Palette?, paletteBeingEdited: Binding<Palette?>, currentlyShowingPalette: Binding<Palette?>) {
        self.palette = palette
        self._paletteBeingEdited = paletteBeingEdited
        self._currentlyShowingPalette = currentlyShowingPalette
    }

    // palette to show/edit
    private var palette: Palette?
    
    // this Binding can be used to switch the PaletteChooser to a different palette
    // while we are visible, this is the same as our palette
    // (but undo happens asynchronously, so we might be gone by the time we want to switch)
    @Binding private var currentlyShowingPalette: Palette?

    // palette to edit (is a Binding because we can set ourselves to edit)
    @Binding private var paletteBeingEdited: Palette?
    
    // whether we are the currently-being-edited palette
    private var isEditing: Bool {
        palette != nil && paletteBeingEdited?.id == palette?.id
    }

    // the name of the palette we are showing/editing
    private var name: String { palette?.name ?? "" }
    
    // the editable name of the palette we are showing/editing
    // any emoji included in the editableName will be added to the palette
    // (this is sort of an experimental UI approach to streamline emoji input)
    // (and is very simple to implement)
    // (but entering emoji via the keyboard on iOS is a bit of a chore even so)
    // (and eventually we'll probably need something more sophisticated for emoji entering)
    @State private var editableName: String = ""
        
    // MARK: - Body
    
    var body: some View {
        HStack {
            nameView
            emojisView
        }
        .onChange(of: name) { newName in
            editableName = newName
        }
        .onChange(of: isEditing) { isEditing in
            if !isEditing {
                // ended editing, update store ...
                DispatchQueue.main.async {
                    updateStoreFromEditableName()
                }
            }
        }
    }

    // extracts any emoji from editableName
    // and adds those emoji to the palette
    // then takes the remainder and renames the palette to that
    // auto-deletes any palette with both name.isEmpty and emojis.isEmpty
    private func updateStoreFromEditableName() {
        if let palette = self.palette {
            let name = editableName.characters(where: { !$0.isEmoji }).trimWhitespace
            let emojis = editableName.characters(where: { $0.isEmoji })
            withAnimation {
                updateStore(palette: palette, emojisToAdd: emojis, renameTo: name, undoManager: undoManager)
                editableName = name
            }
        }
    }
    
    private var nameView: some View {
        Group {
            if isEditing {
                TextField("Name & Emoji, e.g. Faces 😀😉", text: $editableName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 230)
            } else {
                Text(name)
            }
        }
        .font(.headline)
        .gesture(TapGesture(count: 2).onEnded {
            withAnimation {
                paletteBeingEdited = palette
            }
        })
    }
        
    // the horizontally scrollable list of emojis to choose from
    // emojis can be dragged/dropped from here
    // and, if editing, can be deleted directly from here as well
    private var emojisView: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach((palette?.emojis ?? "").map { String($0) }, id: \.self) { emoji in
                    ZStack(alignment: .topTrailing) {
                        Text(emoji)
                            .onDrag { NSItemProvider(object: emoji as NSString) }
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.headline).imageScale(.large)
                            .opacity(isEditing ? 1 : 0)
                            .onTapGesture {
                                withAnimation {
                                    updateStore(palette: palette!, emojisToDelete: emoji, undoManager: undoManager)
                                }
                            }
                    }
                }
                Text(" ")
            }
        }
            .zIndex(-1)
    }
    
    // MARK: - Undoable Store Update
    
    // all the possible undo cases in this View
    // gathered into one function
    // (so it is easy to ignore if you aren't interested)
    
    private func updateStore(palette: Palette, emojisToAdd: String = "", emojisToDelete: String = "", renameTo newName: String? = nil, from: String? = nil, undoManager: UndoManager? = nil) {
        let isUndoing = undoManager?.isUndoing ?? false
        let oldName = from ?? store.data[palette].name
        let name = newName ?? oldName
        var actions = [String]()
        
        withAnimation {
            if !emojisToAdd.isEmpty {
                actions.append("Add \(emojisToAdd)")
                if isUndoing {
                    store.removeEmojis(emojisToAdd, from: palette)
                } else {
                    store.addEmojis(emojisToAdd, to: palette)
                }
            }
            if !emojisToDelete.isEmpty {
                actions.append("Delete \(emojisToDelete)")
                if isUndoing {
                    store.addEmojis(emojisToDelete, to: palette)
                } else {
                    store.removeEmojis(emojisToDelete, from: palette)
                }
            }
            if name != oldName {
                actions.append("Rename \(oldName) to \(name)")
                if isUndoing {
                    store.rename(palette, to: oldName)
                } else {
                    store.rename(palette, to: name)
                }
            }
            if store.deleteIfEmpty(palette) == nil {
                currentlyShowingPalette = palette
                if let undoManager = undoManager, !actions.isEmpty, !palette.emojis.isEmpty, !palette.name.isEmpty {
                    undoManager.setActionIsDiscardable(true)
                    undoManager.setActionName(actions.joined(separator: ", "))
                    undoManager.registerUndo(withTarget: store) { store in
                        updateStore(palette: palette, emojisToAdd: emojisToAdd, emojisToDelete: emojisToDelete, renameTo: name, from: oldName, undoManager: undoManager)
                    }
                }
            }
        }
    }
}
