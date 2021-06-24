//
//  PaletteEditor.swift
//  EmojiArt
//
//  Created by Sergey Blednov on 6/23/21.
//

import SwiftUI

struct PaletteEditor: View {
    @Binding var palette: Palette
    
    @State var emojiiToAdd = ""
    
    var body: some View {
        Form{
            nameSection
            addEmojiSection
            removeEmojiSection
        }
        .navigationTitle("Edit \(palette.name)")
        .frame(minWidth: 300, minHeight: 350 )
    }
    
    var nameSection: some View {
        Section(header: Text("Name")) {
            TextField("Name", text: $palette.name)
        }
    }
    
    var addEmojiSection: some View {
        Section(header: Text("Add Emoji")) {
            TextField("", text: $emojiiToAdd)
                .onChange(of: emojiiToAdd) { emojis in
                    addEmojis(emojis)
                }
        }
    }
    
    var removeEmojiSection: some View {
        Section(header: Text("Remove Emoji")) {
            let emojis = palette.emojis.removingDuplicateCharacters.map { String($0) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                ForEach(emojis, id: \.self) { emoji in
                    Text(emoji)
                        .onTapGesture {
                            withAnimation {
                                palette.emojis.removeAll(where: { String($0) == emoji })
                            }
                        }
                }
            }
            .font(.system(size: 40))
        }
    }
    
    private func addEmojis(_ emojis: String) {
        palette.emojis = (emojis + palette.emojis)
            .filter { $0.isEmoji }
            .removingDuplicateCharacters
    }
}

struct PaletteEditor_Previews: PreviewProvider {
    static var previews: some View {
        PaletteEditor(palette: .constant(PaletteStore(named: "Preview").palette(at: 4)))
            .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/300.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/350.0/*@END_MENU_TOKEN@*/))
    }
}
