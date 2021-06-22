//
//  UtilityViews.swift
//  EmojiArt
//
//  Created by Sergey Blednov on 6/21/21.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?
    var body: some View {
        if uiImage != nil {
            Image(uiImage: uiImage!)
        }
    }
}
