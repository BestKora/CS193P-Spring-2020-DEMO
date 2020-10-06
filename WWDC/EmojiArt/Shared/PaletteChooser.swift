//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 6/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

// new
// an entirely new take on the PaletteEditor functionality

// instead of using a popover/sheet
// this allows direct, in-place editing of the palettes
// and relies heavily on context menus
// (a design emphasis for iOS14/Big Sur)

// it also uses a true store for the palettes
// (i.e. with Identifiable Palette objects)
// rather than the demoware approach from lecture

// and a second example of undo thrown in for good measure

struct PaletteChooser: View
{
    // MARK: Properties
    
    @Environment(\.undoManager) var undoManager
    @EnvironmentObject private var store: PaletteStore
    
    // the cursor into our store of the Palette we're showing
    // a cursor keeps working even if a Palette gets deleted out from under us
    @State private var cursor = PaletteStore.Cursor()

    // get the palette we're currently showing
    // (convenience access to currentlyShowingPalette)
    private var palette: Palette? {
        currentlyShowingPalette.wrappedValue
    }
    // change the palette we're currently showing
    // (convenience access to currentlyShowingPalette)
    private func switchToPalette(_ palette: Palette?) {
        currentlyShowingPalette.wrappedValue = palette
    }
    
    // a Binding to the palette in the store at our cursor
    private var currentlyShowingPalette: Binding<Palette?> {
        Binding<Palette?>(
            get: { store[cursor] },
            set: { newValue in self.cursor.palette = newValue }
        )
    }

    // the palette that is currently being edited (if any)
    @State private var paletteBeingEdited: Palette?
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .center) {
            paletteControlButton
            PaletteView(palette, paletteBeingEdited: $paletteBeingEdited, currentlyShowingPalette: currentlyShowingPalette)
                .id(palette?.id ?? 0) // relies on PaletteStore never assigning id 0 (meh design decision)
                .transition(transition)
                .onAppear { paletteAppeared(palette) }
        }
            .padding(.leading)
            .clipped()
    }
    
    private func paletteAppeared(_ palette: Palette?) {
        cursor = store.updatedVersionOfCursor(cursor)
        lastCursor = cursor
        if !isEditing(palette) {
            stopEditing()
        }
    }

    // MARK: - Palette Control Button

    private var paletteControlButton: some View {
        Image(systemName: "paintpalette")
            .foregroundColor(.accentColor)
            .contextMenu {
                Group {
                    if let editing = self.paletteBeingEdited {
                        AnimatedActionLabel("Delete", systemImage: "minus.circle") {
                            delete(editing)
                        }
                        AnimatedActionLabel("End Editing", systemImage: "textbox") {
                            stopEditing()
                        }
                    } else {
                        if let palette = self.palette {
                            AnimatedActionLabel("Delete " + palette.name, systemImage: "minus.circle") {
                                delete(palette)
                            }
                        }
                        #if !os(macOS) // use Undo instead on Mac
                        if let lastDeleted = store.mostRecentlyDeleted {
                            AnimatedActionLabel("Undelete " + lastDeleted.name, systemImage: "arrow.uturn.left.square") {
                                undelete(lastDeleted, at: cursor)
                            }
                        }
                        #endif
                        AnimatedActionLabel("New Palette", systemImage: "plus") {
                            switchToPalette(store.insertPalette(at: cursor))
                            startEditing()
                        }
                        if let palette = self.palette {
                            AnimatedActionLabel("Edit \(palette.name)", systemImage: "textbox") {
                                startEditing()
                            }
                        }
                    }
                }
                .font(.body)
            }
            .gesture(TapGesture(count: 2).onEnded {
                showPalette(offsetFromCurrentPaletteBy: -1)
            }.exclusively(before: TapGesture(count: 1).onEnded {
                showPalette(offsetFromCurrentPaletteBy: 1)
            }))
            .padding(.vertical)
    }
    
    private func showPalette(offsetFromCurrentPaletteBy offset: Int) {
        withAnimation {
            if isEditing {
                stopEditing()
            } else if store.data.isEmpty {
                switchToPalette(store.insertPalette(at: cursor))
            } else {
                cursor = store.cursor(offsetting: cursor, by: offset)
            }
        }
    }
    
    private func delete(_ paletteToDelete: Palette, actionName: String = "Delete") {
        undoablyPerform("\(actionName) \(paletteToDelete.name)") {
            undelete(paletteToDelete, at: cursor, actionName: actionName)
        }
        store.delete(paletteToDelete)
    }
    
    private func undelete(_ paletteToUndelete: Palette, at cursor: PaletteStore.Cursor, actionName: String = "Undelete") {
        if let paletteToUndelete = store.undelete(paletteToUndelete, at: cursor) {
            undoablyPerform("\(actionName) \(paletteToUndelete.name)") {
                delete(paletteToUndelete, actionName: actionName)
            }
            switchToPalette(paletteToUndelete)
        }
    }
    
    private func undoablyPerform(_ operation: String, animated: Bool = true, doit: @escaping () -> Void) {
        undoManager?.setActionIsDiscardable(true)
        undoManager?.setActionName(operation)
        undoManager?.registerUndo(withTarget: store) { store in
            withAnimation {
                if animated {
                    withAnimation { doit() }
                } else {
                    doit()
                }
            }
        }
    }

    // MARK: - Editing
    
    private var isEditing: Bool { paletteBeingEdited != nil }
    
    private func isEditing(_ palette: Palette?) -> Bool {
        palette != nil && paletteBeingEdited?.id == palette?.id
    }
    
    private func stopEditing() {
        paletteBeingEdited = nil
    }
    
    private func startEditing() {
        paletteBeingEdited = palette
    }
    
    // MARK: - Transition Animation
    
    // the cursor to the last palette we showed
    // (so we can do the proper animation as we transition between palettes)
    @State private var lastCursor = PaletteStore.Cursor()

    private var transition: AnyTransition {
        if !store.contains(lastCursor.palette) {
            // palette was deleted
            return .moveUp
        } else {
            let last = store.updatedVersionOfCursor(lastCursor)
            let current = cursor
            if last.index < current.index {
                return .moveUp
            } else if last.index > current.index {
                return .moveDown
            } else if last.palette != current.palette {
                // palette was inserted
                return .moveDown
            }
        }
        return .identity
    }
}
