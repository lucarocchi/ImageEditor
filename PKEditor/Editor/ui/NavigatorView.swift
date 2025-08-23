//
//  NavigatorView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 28/07/25.
//


import SwiftUI

struct NavigatorView: View {
    @ObservedObject var model = EditorModel.shared
    // @State private var navigatorOffset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero

    // The size of the floating navigator window
    private let navigatorSize: CGFloat = 100

    /*
    var body: some View {
        if model.isShowingNavigator, let image = model.navigatorImage {
            VStack {
                // The main content of the navigator
                ZStack(alignment: .topLeading) {
                    // 1. The thumbnail of the entire canvas
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                    
                    // 2. The rectangle showing the visible area
                    Rectangle()
                        .stroke(Color.red, lineWidth: 3)
                        .frame(
                            width: model.visibleRectInCanvas.width * scaleRatio(),
                            height: model.visibleRectInCanvas.height * scaleRatio()
                        )
                        .offset(
                            x: model.visibleRectInCanvas.origin.x * scaleRatio(),
                            y: model.visibleRectInCanvas.origin.y * scaleRatio()
                        )
                }
                .frame(width: navigatorSize, height: navigatorSize/model.aspectRatio)
                .border(Color.secondary)
                .background(.thinMaterial)
                
                // Optional: Button to close the navigator
                //Button("Close Navigator") {
                //model.isShowingNavigator = false
                //}
                .font(.caption)
            }
        }
    }
    */
    
    var body: some View {
        if model.isShowingNavigator, let image = model.navigatorImage {
            VStack {
                ZStack(alignment: .topLeading) {
                    // 1. L'anteprima dell'intera tela (invariata)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                    
                 
                    Rectangle()
                   .stroke(Color.red, lineWidth: 2)
                   .contentShape(Rectangle())
                   .frame(width: clampedVisibleRect().width, height: clampedVisibleRect().height)
                   //.offset(x: clampedVisibleRect().origin.x, y: clampedVisibleRect().origin.y)
                   .gesture(
                       DragGesture(minimumDistance: 0)
                           .onChanged { value in
                               model.isProgrammaticScroll = true
                               let clampedTranslation = adjustTranslation(value: value)
                               self.dragOffset = clampedTranslation
                           }
                           .onEnded { value in
                              
                               let clampedTranslation = adjustTranslation(value: value)
                           
                               let ratio = scaleRatio()
                               guard ratio > 0 else {
                                   return
                               }
                               
                               let deltaX = clampedTranslation.width / ratio
                               let deltaY = clampedTranslation.height / ratio
                               
                               let newOffsetX = model.contentOffset.x + deltaX
                               let newOffsetY = model.contentOffset.y + deltaY
                               DispatchQueue.main.async {
                                   model.contentOffset = CGPoint(x: newOffsetX, y: newOffsetY)
                                   self.dragOffset = .zero
                                   model.updateContentOffset()
                                   NotificationCenter.default.post(name: Notification.UpdateNavigator, object: nil, userInfo: [:])
                                   model.isProgrammaticScroll = false
                                 
                               }
                           }
                   )
                   .offset(x: clampedVisibleRect().origin.x + dragOffset.width,
                           y: clampedVisibleRect().origin.y + dragOffset.height)
                }
                .frame(width: navigatorSize, height: navigatorSize)
                .border(Color.secondary)
                .background(.thinMaterial)
                .clipped() // Aggiungiamo .clipped() per essere sicuri che nulla esca dai bordi
                
            }
        }
    }
 
    func adjustTranslation(value:DragGesture.Value)->CGSize{
        let proposedX = clampedVisibleRect().origin.x + value.translation.width
        let proposedY = clampedVisibleRect().origin.y + value.translation.height
        let overdragX = max(0, -proposedX) + min(0, navigatorSize - (proposedX + clampedVisibleRect().width))
        let overdragY = max(0, -proposedY) + min(0, navigatorSize - (proposedY + clampedVisibleRect().height))
        let clampedTranslation = CGSize(
            width: value.translation.width - overdragX,
            height: value.translation.height - overdragY
        )
        return clampedTranslation
                    
    }
    
    /// Calcola il frame del riquadro rosso, gestendo i limiti e il caso "zoom to fit".
    private func clampedVisibleRect() -> CGRect {
        // Calcoliamo il fattore di zoom al quale l'intera tela è visibile
        let layer = model.layers.first
        let layerCanvasModel = layer as! LayerCanvasModel
    
        let fitScaleX = (layerCanvasModel.canvas?.bounds.width ?? navigatorSize) / model.contentSize.width
        let fitScaleY = (layerCanvasModel.canvas?.bounds.height ?? navigatorSize) / model.contentSize.height
        let fitScale = min(fitScaleX, fitScaleY)

        // --- Caso 1: L'intera tela è visibile ---
        // Se lo zoom attuale è minore o uguale a quello di "fit", i rettangoli devono coincidere.
        if model.zoomScale <= fitScale {
            return CGRect(origin: .zero, size: CGSize(width: navigatorSize, height: navigatorSize))
        }
        
        // --- Caso 2: L'utente ha zoomato ---
        // Calcoliamo la posizione e la dimensione del riquadro rosso
        let ratio = scaleRatio()
        var rect = CGRect(
            x: model.visibleRectInCanvas.origin.x * ratio,
            y: model.visibleRectInCanvas.origin.y * ratio,
            width: model.visibleRectInCanvas.width * ratio,
            height: model.visibleRectInCanvas.height * ratio
        )

        // Applichiamo il "clamping" per non farlo uscire dai bordi
        rect.origin.x = max(0, rect.origin.x)
        rect.origin.y = max(0, rect.origin.y)
        
        if rect.maxX > navigatorSize {
            rect.size.width = navigatorSize - rect.origin.x
        }
        if rect.maxY > navigatorSize {
            rect.size.height = navigatorSize - rect.origin.y
        }
        
        return rect
    }
    /// Calculates the ratio between the full content size and the navigator's display size.
    private func scaleRatio() -> CGFloat {
        guard model.contentSize.width > 0, model.contentSize.height > 0 else { return 1 }
        
        let widthRatio = navigatorSize / model.contentSize.width
        let heightRatio = navigatorSize / model.contentSize.height
        
        return min(widthRatio, heightRatio)
    }
    
    
    
}
