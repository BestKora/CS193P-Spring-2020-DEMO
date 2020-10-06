//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

// the main change here is getting rid of the document management stuff from lecture
// and replacing it with SwiftUI's new document-handling code below
// (which is essentially the UIDocument architecture mentioned in slides in lecture)

// simple undo capability was also added
// (since it goes along so nicely with the new Document architecture)

// and we moved the zoom/panning storage back to EmojiArtDocumentView
// so that it can be scene-specific @SceneStorage

// new
extension UTType {
    // the type of an EmojiArt document
    // see "Document Types" and "Imported/Exported Type Identifiers"
    // in Info section of Project Settings (aka Info.plist file)
    static var emojiart = UTType(exportedAs: "edu.stanford.cs193p.emojiart")
}

class EmojiArtDocument: ReferenceFileDocument
{
    // required in Xcode 12.0.1
    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let newEmojiArt = EmojiArtModel(json: data)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        emojiArt = newEmojiArt
        fetchBackgroundImageData()
    }
    
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: snapshot)
    }
    
    
    // new
    // this section contains the code to load/save ourself
    // using the new SwiftUI DocumentGroup API
    
    // MARK: Document Handling

    static var readableContentTypes: [UTType] { [.emojiart] }
    static var writeableContentTypes: [UTType] { [.emojiart] }
    
    // a version of our Model (an EmojiArtModel) as a Data
    func snapshot(contentType: UTType) throws -> Data {
        emojiArt.json!
    }
 
    // write a snapshot (i.e. our Model as a Data) into the given FileWrapper
    // note that it's an inout parameter
    // so we're allowed to create an entirely new file if we want (which we do)
    func write(snapshot: Data, to fileWrapper: inout FileWrapper, contentType: UTType) throws {
        fileWrapper = FileWrapper(regularFileWithContents: snapshot)
    }
 
    // load up our Model from the given FileWrapper
    // this is how we're initialized when the user clicks on an EmojiArt document file
    init(fileWrapper: FileWrapper, contentType: UTType) throws {
        guard let data = fileWrapper.regularFileContents,
              let newEmojiArt = EmojiArtModel(json: data)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        emojiArt = newEmojiArt
        fetchBackgroundImageData()
    }
   
    // creates a blank document
    convenience init() {
        let blankEmojiArt = EmojiArtModel()
        let wrapper = FileWrapper(regularFileWithContents: blankEmojiArt.json!)
        try! self.init(fileWrapper: wrapper, contentType: UTType.emojiart)
    }

    // MARK: - Undo

    // new
    // all changes to the Model should (must) be undoable
    // not just because we want a good UI (with Undo and Redo) for our users
    // but because a ReferenceFileDocument only knows to save itself when an undo is registered
    // thus any changes made to the Model without registering an undo are at risk of being lost
    // currently, only our Intent functions can change our Model
    // so the API for those Intent functions now ask for the UndoManager from the View
    // on iOS, there's no "Save" menu item, so documents are "autosaved"
    // (this happens on certain events like switching to another app)

    func undoablyPerform(operation: String, with undoManager: UndoManager?, doit: () -> Void) {
        let oldEmojiArt = emojiArt
        doit()
        undoManager?.setActionName(operation)
        undoManager?.registerUndo(withTarget: self) { [weak self] document in
            // perform the undo undoably (i.e. allow redo)
            self?.undoablyPerform(operation: operation, with: undoManager) {
                let needBackgroundFetch = document.emojiArt.backgroundIsDifferentThan(oldEmojiArt)
                document.emojiArt = oldEmojiArt
                if needBackgroundFetch {
                    self?.fetchBackgroundImageData()
                }
            }
        }
    }
    
    // MARK: - Model
    
    @Published private var emojiArt: EmojiArtModel
    
    @Published private(set) var backgroundImage: UIImage?
    var backgroundURL: URL? { emojiArt.backgroundURL }
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }

    // MARK: - Intent(s)

    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat, undoManager: UndoManager? = nil) {
        undoablyPerform(operation: "Add \(emoji)", with: undoManager) {
            emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
        }
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize, undoManager: UndoManager? = nil) {
        undoablyPerform(operation: "Move Emoji", with: undoManager) {
            if let index = emojiArt.emojis.firstIndex(matching: emoji) {
                emojiArt.emojis[index].x += Int(offset.width)
                emojiArt.emojis[index].y += Int(offset.height)
            }
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat, undoManager: UndoManager? = nil) {
        undoablyPerform(operation: "Resize Emoji", with: undoManager) {
            if let index = emojiArt.emojis.firstIndex(matching: emoji) {
                emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
            }
        }
    }

    func setBackgroundURL(_ url: URL?, undoManager: UndoManager? = nil) {
        undoablyPerform(operation: "Set Background URL", with: undoManager) {
            emojiArt.backgroundImageData = nil
            emojiArt.backgroundURL = url?.imageURL
            fetchBackgroundImageData()
        }
    }

    // new
    func setBackgroundImageData(_ data: Data, undoManager: UndoManager? = nil) {
        undoablyPerform(operation: "Set Background Image", with: undoManager) {
            emojiArt.backgroundImageData = data
            emojiArt.backgroundURL = nil
            backgroundImage = UIImage(data: data)
        }
    }
    
    // MARK: - Fetching Background Image
    
    private var fetchImageCancellable: AnyCancellable?
    @Published private(set) var isFetchingBackground = false
    
    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = emojiArt.backgroundURL?.imageURL {
            isFetchingBackground = true
            fetchImageCancellable?.cancel()
            fetchImageCancellable = URLSession.shared.dataTaskPublisher(for: url)
                .map { data, urlResponse in UIImage(data: data) }
                .receive(on: DispatchQueue.main)
                .replaceError(with: nil)
                .sink { image in
                    self.isFetchingBackground = false
                    self.backgroundImage = image
                }
        } else if let imageData = emojiArt.backgroundImageData {
            // new
            backgroundImage = UIImage(data: imageData)
        }
    }
}

extension EmojiArtModel.Emoji {
    var fontSize: CGFloat { CGFloat(size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}

extension EmojiArtModel {
    func backgroundIsDifferentThan(_ otherEmojiArt: EmojiArtModel) -> Bool {
        (backgroundURL != otherEmojiArt.backgroundURL) ||
        (backgroundImageData != otherEmojiArt.backgroundImageData)
    }
}
