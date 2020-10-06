//
//  PaletteStore.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 6/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI
import Combine

// new

// a store of emoji palettes
// this is mostly just syntactic sugar
// on top of a UserDefaultsStore<Palette>

struct Palette: Codable, Identifiable, Equatable {
    fileprivate(set) var name: String
    fileprivate(set) var emojis: String
    let id: Int
    
    fileprivate init(name: String, emojis: String, id: Int) {
        self.name = name
        self.emojis = emojis
        self.id = id
    }
}

// MARK: -

final class PaletteStore: UserDefaultsStore<Palette>
{
    // MARK: Initialization
    
    private static var defaultPalettes: [Palette] {
        let defaultPalettes: [String:String] = [
            "Faces":"😀😇🥰😎🧐🥳🤯🥶😱🤔🤥🥱😴🤢🤮😷🤧🤠",
            "Halloween":"💀👻🎃🕷🕸😈",
            "Sports":"⚽️🏀🏈⚾️🎾🏐🏓🏏⛳️🥌⛷🏂🏄",
            "Vehicles":"🚕🏎🚓🚑🚒🚜🚲🏍🚂✈️🚀🚁"
        ]
        var unique = 0
        return defaultPalettes.map { (name, emojis) -> Palette in
            unique += 1
            return Palette(name: name, emojis: emojis, id: unique)
        }
    }
    
    static var shared = PaletteStore(
        key: "PaletteStore.shared",
        defaultPalettes: defaultPalettes,
        recentlyDeleted: PaletteStore(key: "PaletteStore.shared.recentlyDeleted")
    )

    init(key: String, defaultPalettes: [Palette] = [], watchForChanges: Bool = false, recentlyDeleted: PaletteStore? = nil) {
        self.recentlyDeleted = recentlyDeleted
        super.init(key: key, defaultData: defaultPalettes, watchForChanges: watchForChanges)
    }
    
    // MARK: Properties/Utilities

    func contains(_ palette: Palette?) -> Bool {
        palette != nil && data.contains(matching: palette!)
    }
    
    private(set) var recentlyDeleted: PaletteStore?
    var mostRecentlyDeleted: Palette? { recentlyDeleted?.data.last }

    private var nextUniquePaletteId: Int { (data.map { $0.id }.max() ?? 0) + 1 }
    
    // MARK: User Intent(s)
    
    @discardableResult
    func insertPalette(withEmojis emojis: String = "", named name: String = "", at cursor: Cursor) -> Palette {
        let id = max(nextUniquePaletteId, recentlyDeleted?.nextUniquePaletteId ?? 0)
        let palette = Palette(name: name, emojis: emojis, id: id)
        data.insert(palette, at: cursor.index.wrapped(into: data.indices))
        return palette
    }
    
    @discardableResult
    func appendPalette(withEmojis emojis: String = "", named name: String = "") -> Palette {
        insertPalette(withEmojis: emojis, named: name, at: Cursor(index: data.count-1))
    }
    
    func rename(_ palette: Palette, to name: String) {
        data[palette].name = name
    }
    
    func addEmojis(_ emojis: String, to palette: Palette) {
        data[palette].emojis = (emojis + palette.emojis).uniqued()
    }
    
    func removeEmojis(_ emojisToRemove: String, from palette: Palette) {
        data[palette].emojis = palette.emojis.filter { !emojisToRemove.contains($0) }
    }
    
    @discardableResult
    func delete(_ palette: Palette) -> Palette? {
        if !palette.emojis.isEmpty || !palette.name.isEmpty {
            recentlyDeleted?.data.append(palette)
        }
        return data.removeFirst(matching: palette)
    }
    
    @discardableResult
    func deleteIfEmpty(_ palette: Palette) -> Palette? {
        if data[palette].emojis.isEmpty, data[palette].name.isEmpty {
            return delete(palette)
        } else {
            return nil
        }
    }
    
    @discardableResult
    func undelete(_ palette: Palette, at cursor: Cursor) -> Palette? {
        recentlyDeleted?.data.removeAll(matching: palette)
        return insertPalette(withEmojis: palette.emojis, named: palette.name, at: cursor)
    }

    // MARK: - Cursor
    
    // a Cursor is a way of specifying which data you want from the PaletteStore
    // it contains both a Palette and an index
    // the Cursor's index is a "backup"
    // for when its Palette cannot be found in the PaletteStore (by Identifiable-ness)
    // the index is never invalid (it wraps-around)
    // so it continues to work even as items are deleted from the store, for example
    
    // update the Cursor's index to point to its Palette (if it's in the PaletteStore)
    // if it's not in the PaletteStore, update the Cursor's Palette to what's at its index
    func updatedVersionOfCursor(_ existingCursor: Cursor) -> Cursor {
        if let palette = existingCursor.palette, let index = data.firstIndex(matching: palette) {
            if index == existingCursor.index.wrapped(into: data.indices) {
                return existingCursor
            } else {
                return Cursor(palette: palette, index: index)
            }
        } else if data.isEmpty {
            return existingCursor
        } else {
            let palette = data[existingCursor.index.wrapped(into: data.indices)]
            return Cursor(palette: palette, index: existingCursor.index)
        }
    }
    
    // move the Cursor around in the PaletteStore
    // again, a Cursor is incapable of pointing outside of the data in the PaletteStore
    func cursor(offsetting otherCursor: Cursor, by offset: Int) -> Cursor {
        if let palette = otherCursor.palette, let index = data.firstIndex(matching: palette) {
            let newPalette = data[(index+offset).wrapped(into: data.indices)]
            if index.wrapped(into: data.indices) == otherCursor.index.wrapped(into: data.indices) {
                return Cursor(palette: newPalette, index: otherCursor.index+offset)
            } else {
                return Cursor(palette: newPalette, index: index+offset)
            }
        } else {
            return Cursor(palette: otherCursor.palette, index: otherCursor.index+offset)
        }
    }
    
    // get the Palette at the given Cursor
    // only returns nil if the PaletteStore is empty
    // otherwise returns the version of the specified Palette that is in the PaletteStore
    // or, if the Cursor's Palette is nil or not in the PaletteStore
    // returns the pPalette that is at the Cursor's index
    subscript(cursor: Cursor) -> Palette? {
        get {
            if let palette = cursor.palette, let index = data.firstIndex(matching: palette) {
                return data[index]
            } else if data.isEmpty {
                return nil
            } else {
                return data[cursor.index.wrapped(into: data.indices)]
            }
        }
    }
    
    struct Cursor: CustomStringConvertible {
        var palette: Palette?
        var index: Int
        
        init(palette: Palette? = nil, index: Int = 0) {
            self.palette = palette
            self.index = index
        }
        
        var description: String {
            "@\(index) \(palette?.name ?? "nil")"
        }
    }
}
