//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Sergey Blednov on 6/21/21.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let document = EmojiArtDocument()
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
