//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Sergey Blednov on 6/21/21.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @Environment(\.undoManager) var undoManager
    
    let defaultEmojiFontSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            PaletteChooser(emojiFontSize: defaultEmojiFontSize)
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((0, 0), in: geometry))
                )
                .gesture(doubleTapToZoom(in: geometry.size))
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        if document.selectedEmojis.contains(emoji) {
                            Text(emoji.text)
                                .scaleEffect(zoomScale * 1.5)
                                .font(.system(size: fontSize(for: emoji)))
                                .position(position(for: emoji, in: geometry))
                                .gesture(tapToSelect(emoji))
//                                .onDrag { NSItemProvider(object: emoji.text as NSString) /
                        } else {
                            Text(emoji.text)
                                .scaleEffect(zoomScale)
                                .font(.system(size: fontSize(for: emoji)))
                                .position(position(for: emoji, in: geometry))
                                .gesture(tapToSelect(emoji))
                        }
                    }
                    
                }
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                return drop(providers: providers, at: location, in: geometry)
            }
            .gesture(dragGesture().simultaneously(with: zoomGesture()))
            .alert(item: $alertToShow) { alertToShow in
                alertToShow.alert()
            }
            .onChange(of: document.backgroundImageFetchStatus) { status in
                switch status {
                case .failed(let url): showBackgroundImageFetchFailedAlert(url)
                default: break 
                }
            }
            .onReceive(document.$backgroundImage) { image in
                zoomToFit(image, in: geometry.size)
            }
            .toolbar {
                UndoButton(
                    undo: undoManager?.optionalUndoMenuItemTitle,
                    redo: undoManager?.optionalRedoMenuItemTitle
                )
            }
        }
    }
    
    @State private var alertToShow: IdentifiableAlert?
    
    private func showBackgroundImageFetchFailedAlert(_ url: URL) {
        alertToShow = IdentifiableAlert(id: "fetch failed: " + url.absoluteString, alert: {
            Alert(
                title: Text("Background Image Fetch"),
                message: Text("Could't load image from \(url)"),
                dismissButton: .default(Text("OK")))
        })
    }
    
    @SceneStorage("EmojiArtDocumentView.steadyStatePanOffset")
    private var steadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func dragGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestValue, gesturePanOffset, _ in
                gesturePanOffset = latestValue.translation / zoomScale
            }
            .onEnded { finalValue in
                steadyStatePanOffset = steadyStatePanOffset + finalValue.translation / zoomScale
            }
    }
    
    @SceneStorage("EmojiArtDocumentView.steadyStateZoomScale")
    private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let vZoom = size.height / image.size.height
            let hZoom = size.width / image.size.width
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(vZoom, hZoom)
        }
    }
    
    private func toggleSelection(_ emoji: EmojiArtModel.Emoji) {
        document.toggleEmoji(emoji)
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { gestureScaleAtEnd in
                steadyStateZoomScale *= gestureScaleAtEnd
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func tapToSelect(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                withAnimation {
                    toggleSelection(emoji)
                }
            }
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint (
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    private func convertToEmojiCoordinate(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint (
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }
    
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            document.setBackground(.url(url.imageURL), undoManager: undoManager)
        }
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(data),  undoManager: undoManager)
                }
            }
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji { document.addEmoji(
                    String(emoji),
                    at: convertToEmojiCoordinate(location,
                    in: geometry),
                    size: defaultEmojiFontSize / zoomScale,
                    undoManager: undoManager)
                }
            }
        }
        return found
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
