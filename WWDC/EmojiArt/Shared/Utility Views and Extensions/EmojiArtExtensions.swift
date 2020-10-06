//
//  EmojiArtExtensions.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

extension Collection where Element: Identifiable {
    func firstIndex(matching element: Element) -> Self.Index? {
        firstIndex(where: { $0.id == element.id })
    }
    func contains(matching element: Element) -> Bool {
        contains(where: { $0.id == element.id })
    }
}

// new
extension RangeReplaceableCollection where Element: Identifiable {
    @discardableResult
    mutating func removeFirst(matching element: Element) -> Element? {
        if let index = firstIndex(matching: element) {
            return remove(at: index)
        } else {
            return nil
        }
    }
    
    mutating func removeAll(matching element: Element) {
        removeAll(where: { $0.id == element.id })
    }
}

// new
// adds sort of an interesting semantic for subscripting a Collection:
// if you look for an Identifiable in a Collection of Identifiable
// using this subscript
// and it cannot be found
// this returns the Identifiable you were looking up instead
// this can simplify code where you rarely expect that Identifiable to not be found
// (but don't want to be checking for that all the time)
// and are fine with "throwing away" any work you do when it can't be found
// (by applying it to the returned copy of what you looked up)
// this operates on the "firstIndex" it finds
// so it's sort of assuming that the Collection has unique Identifiables in it
// it's also interesting to have a Binding to this subscript (e.g. $viewmodel.data[identifiable])
// (the Binding will not fail even if the the Collection is reordered out from under it)
// (nor will it fail if the Identifiable is deleted out from under the Binding)

extension RangeReplaceableCollection where Element: Identifiable {
    subscript(_ element: Element) -> Element {
        get {
            if let index = firstIndex(matching: element) {
                return self[index]
            } else {
                return element
            }
        }
        set {
            if let index = firstIndex(matching: element) {
                replaceSubrange(index...index, with: [newValue])
            }
        }
    }
}

extension URL {
    var imageURL: URL {
        // check to see if there is an embedded imgurl reference
        for query in query?.components(separatedBy: "&") ?? [] {
            let queryComponents = query.components(separatedBy: "=")
            if queryComponents.count == 2 {
                if queryComponents[0] == "imgurl", let url = URL(string: queryComponents[1].removingPercentEncoding ?? "") {
                    return url
                }
            }
        }
        return baseURL ?? self
    }
}

extension GeometryProxy {
    func convert(_ point: CGPoint, from coordinateSpace: CoordinateSpace) -> CGPoint {
        let frame = self.frame(in: coordinateSpace)
        return CGPoint(x: point.x-frame.origin.x, y: point.y-frame.origin.y)
    }
}

extension Array where Element == NSItemProvider {
    func loadObjects<T>(ofType theType: T.Type, firstOnly: Bool = false, using load: @escaping (T) -> Void) -> Bool where T: NSItemProviderReading {
        if let provider = first(where: { $0.canLoadObject(ofClass: theType) }) {
            provider.loadObject(ofClass: theType) { object, error in
                if let value = object as? T {
                    DispatchQueue.main.async {
                        load(value)
                    }
                }
            }
            return true
        }
        return false
    }
    func loadObjects<T>(ofType theType: T.Type, firstOnly: Bool = false, using load: @escaping (T) -> Void) -> Bool where T: _ObjectiveCBridgeable, T._ObjectiveCType: NSItemProviderReading {
        if let provider = first(where: { $0.canLoadObject(ofClass: theType) }) {
            let _ = provider.loadObject(ofClass: theType) { object, error in
                if let value = object {
                    DispatchQueue.main.async {
                        load(value)
                    }
                }
            }
            return true
        }
        return false
    }
    func loadFirstObject<T>(ofType theType: T.Type, using load: @escaping (T) -> Void) -> Bool where T: NSItemProviderReading {
        loadObjects(ofType: theType, firstOnly: true, using: load)
    }
    func loadFirstObject<T>(ofType theType: T.Type, using load: @escaping (T) -> Void) -> Bool where T: _ObjectiveCBridgeable, T._ObjectiveCType: NSItemProviderReading {
        loadObjects(ofType: theType, firstOnly: true, using: load)
    }
}

extension Data {
    var utf8: String? { String(data: self, encoding: .utf8 ) }
}

extension String {
    func uniqued() -> String {
        var uniqued = ""
        for ch in self {
            if !uniqued.contains(ch) {
                uniqued.append(ch)
            }
        }
        return uniqued
    }
    
    // new
    func characters(where predicate: (Character) -> Bool) -> String {
        String(compactMap { predicate($0) ? $0 : nil })
    }
    
    // new
    var trimWhitespace: String {
        String(reversed().drop(while: { $0.isWhitespace }).reversed().drop(while: { $0.isWhitespace }))
    }
}

// new
extension Character {
    var isEmoji: Bool {
        // Swift does not have a way to ask if a Character isEmoji
        // but it does let us check to see if our component scalars isEmoji
        // unfortunately unicode allows certain scalars (like 1)
        // to be modified by another scalar to become emoji (e.g. 1️⃣)
        // so the scalar "1" will report isEmoji = true
        // so we can't just check to see if the first scalar isEmoji
        // the quick and dirty here is to see if the scalar is at least the first true emoji we know of
        // (the start of the "miscellaneous items" section)
        // or check to see if this is a multiple scalar unicode sequence
        // (e.g. a 1 with a unicode modifier to force it to be presented as emoji 1️⃣)
        if let firstScalar = unicodeScalars.first, firstScalar.properties.isEmoji {
            return (firstScalar.value >= 0x238d || unicodeScalars.count > 1)
        } else {
            return false
        }
    }
}

extension CGPoint {
    static func -(lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.x - rhs.x, height: lhs.y - rhs.y)
    }
    static func +(lhs: Self, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
    }
    static func -(lhs: Self, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x - rhs.width, y: lhs.y - rhs.height)
    }
    static func *(lhs: Self, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    static func /(lhs: Self, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
}

extension CGSize {
    static func +(lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    static func -(lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    static func *(lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    static func /(lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width/rhs, height: lhs.height/rhs)
    }
}

// new
// CGSize and CGFloat are made to be RawRepresentable
// so that they can be used with @SceneStorage

extension CGSize: RawRepresentable {
    // want to use NSCoder.cgSize, but evidently not available on Mac?
    // so we use our own format for representing a CGSize as a String
    public var rawValue: String {
        "\(width),\(height)"
    }
    public init?(rawValue: String) {
        let values = rawValue.components(separatedBy: ",")
        if values.count == 2, let width = Double(values[0]), let height = Double(values[1]) {
            self.init(width: width, height: height)
        } else {
            return nil
        }
    }
}

extension CGFloat: RawRepresentable {
    public var rawValue: String {
        description
    }
    public init?(rawValue: String) {
        if let doubleValue = Double(rawValue) {
            self.init(doubleValue)
        } else {
            return nil
        }
    }
}

// new
extension AnyTransition {
    static var moveUp: AnyTransition {
        asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top))
    }
    static var moveDown: AnyTransition {
        asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom))
    }
}

// new
extension Int {
    func wrapped(into range: Range<Int>) -> Int {
        if range.isEmpty {
            return 0
        } else if self >= range.lowerBound {
            return range.lowerBound + ((self - range.lowerBound) % range.count)
        } else {
            return range.upperBound - 1 - ((range.lowerBound - self) % range.count)
        }
    }
}
