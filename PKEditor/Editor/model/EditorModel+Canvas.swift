//
//  EditorModel+Canvas.swift
//  PKEditor
//
//  Created by Luca Rocchi on 22/06/25.
//


import Foundation
import Combine
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

@preconcurrency import PencilKit


extension EditorModel {
    
    func layerCanvas() -> LayerCanvasModel?{
        
        guard let activeLayer = layers.first(where: { $0.id == activeCanvasId }),let layerCanvasModel = activeLayer as? LayerCanvasModel else {
            print("Errore di conversione: Canvas attiva non trovata.")
            return nil
        }
        return layerCanvasModel
    }
    
    
    func addTextStroke(text: String, center: CGPoint) {
        // 1. Trova l'indice del layer attivo.
        guard let layer = layerCanvas() else {
            print("Errore: Nessun layer attivo trovato per aggiungere il testo.")
            return
        }
        //let layer = layers[layerIndex]
        // 2. Definisci i parametri per il tuo testo.
        //    In futuro potrai renderli personalizzabili dall'utente.
        //let font = UIFont.systemFont(ofSize: 80, weight: .bold)
        let font = currentFont
        //let font = UIFont(name: "Verdana", size: 19)!
        
        let color = textStampWrapper.toolItem.color
        let width: CGFloat = 3.0
        let scale: CGFloat = 1.0
        
        // 3. Convertiamo la posizione (che è un offset) in un punto centrale.
        //    NOTA: Questo assume che la posizione iniziale della TextInput sia (0,0)
        //    rispetto alla canvas. Potrebbe essere necessario un aggiustamento.
        //let center = CGPoint(x: position.width, y: position.height)
        //let center = CGPoint(x: 200, y: 130)
        
        // 4. Chiama il nostro convertitore per creare gli stroke.
        let newStrokes = FontStrokeConverter.createStrokes(
            fromText: text,
            font: font,
            at: center,
            color: color,
            width: width,
            scale: scale
        )
        
        guard !newStrokes.isEmpty else {
            print("Conversione del testo in stroke non ha prodotto risultati.")
            return
        }
        
        if let canvas = layer.canvas {
            let drawing1 = PKDrawing(strokes: newStrokes)
            let newDrawing1 = canvas.drawing.appending(drawing1)
            Task { @MainActor in
                
                registerDrawing(
                    newDrawing1,
                    on:layer.id,
                    actionName: "AddTextStroke"
                )
            }
        }
    }
    
    func undo(){
        let layer = layerCanvas()!
        //let layer = findLayer(by: activeCanvasId)!
        if let undoManager = layer.canvas?.undoManager{
            undoManager.undo()
        }
        
    }
    
    func redo(){
        let layer = layerCanvas()!
        //let layer = findLayer(by: activeCanvasId)!
        if let undoManager = layer.canvas?.undoManager{
            undoManager.redo()
        }
        
    }
    
    @MainActor
    func registerDrawing(
        _ newDrawing: PKDrawing,
        on layerId: Int,
        actionName: String // Es. "Aggiungi Forma" o "Disegno"
    ) {
        //let layer = findLayer(by: layerId)!
        let layer = layerCanvas()!
        //let oldDrawing = self.updateDrawingAtomically(to: newDrawing, on: layer)
        
        let oldDrawing = originalDrawing ?? layer.drawing
        
        guard oldDrawing.dataRepresentation() != newDrawing.dataRepresentation() else {
            return
        }
        
        layer.drawing = newDrawing
        layer.canvas?.drawing = newDrawing
        
        
        layer.canvas?.undoManager?.registerUndo(withTarget: self) { target in
            //Task { @MainActor in
            MainActor.assumeIsolated{
                self.selectedStroke = nil
                
                target.registerDrawing(oldDrawing, on: layerId, actionName: actionName)
            }
            //}
        }
        
        if let undoManager = layer.canvas?.undoManager, !undoManager.isUndoing, !undoManager.isRedoing {
            undoManager.setActionName(actionName)
        }
        
        originalDrawing = nil
        
        NotificationCenter.default.post(name: Notification.UpdateNavigator, object: nil, userInfo: [:])
    }
    
    //func setBackgroundColor(){
    /*for layer in self.layers {
     if let canvas = layer.canvas {
     canvas.backgroundColor = .clear
     canvas.isOpaque = false
     }
     }*/
    /*
     //check
     if layers.count > 0 && backgroundColor != .clear{
     let layer = layers[0]
     if let canvas = layer.canvas {
     canvas.backgroundColor = backgroundColor
     canvas.isOpaque = backgroundColor != .clear
     }
     
     }*/
    //}
    
    /*
     func updateBackgroundStyle() {
     // First, reset all layers to be transparent.
     for layer in self.layers {
     layer.canvas?.backgroundColor = .clear
     layer.canvas?.isOpaque = false
     }
     
     // Get the bottom-most layer.
     guard let bottomLayer = self.layers.first,
     let canvas = bottomLayer.canvas else {
     return
     }
     
     // Now, determine which background to apply.
     switch self.backgroundStyle {
     case .solid:
     // Set a simple solid color.
     canvas.backgroundColor = self.backgroundColor
     canvas.isOpaque = self.backgroundColor.cgColor.alpha == 1.0
     
     case .grid(let spacing):
     // 1. Create the small tile image for our pattern.
     let gridTileImage = createGridPatternImage(color: self.backgroundColor, spacing: spacing)
     
     // 2. Create a new UIColor from this pattern.
     let patternColor = UIColor(patternImage: gridTileImage)
     
     // 3. Set this pattern color as the background.
     backgroundColor = patternColor
     //canvas.isOpaque = self.backgroundColor.cgColor.alpha == 1.0
     }
     }
     */
    
    private func createGridPatternImage(color: UIColor, spacing: CGFloat) -> UIImage {
        let size = CGSize(width: spacing, height: spacing)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // 1. The image background is the main color.
            color.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // 2. Calculate a slightly darker/lighter color for the dot.
            var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            
            let dotColor = UIColor(hue: hue, saturation: saturation, brightness: brightness * (brightness > 0.5 ? 0.95 : 1.2), alpha: alpha)
            dotColor.setFill()
            
            // 3. Draw a single 1x1 dot at the top-left corner of the tile.
            //    When tiled, this will create the grid effect.
            cgContext.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
    
    
    
    func changeStrokeColor(on canvasView: PKCanvasView, to newColor: UIColor) {
        // 1. Ottieni il disegno e assicurati che non sia vuoto
        var drawing = canvasView.drawing
        guard let selectedStroke = selectedStroke else {
            print("Non ci sono tratti da modificare.")
            return
        }
        
        
        
        guard let strokeIndex = drawing.strokes.firstIndex(where:{$0.randomSeed == selectedStroke.randomSeed}) else {
            print("Non ci sono tratti da modificare.")
            return
        }
        
        // 2. Crea un nuovo inchiostro con il nuovo colore,
        //    mantenendo il tipo di inchiostro originale (es. .pen, .pencil).
        let newInk = PKInk(selectedStroke.ink.inkType, color: newColor)
        
        // 3. Crea un nuovo stroke che è una copia del vecchio,
        //    ma con l'inchiostro nuovo. È importante copiare anche
        //    transform e mask per una copia perfetta.
        let newStroke = PKStroke(
            ink: newInk,
            path: selectedStroke.path,
            transform: selectedStroke.transform,
            mask: selectedStroke.mask
        )
        
        // 4. Sostituisci il vecchio stroke con quello nuovo
        drawing.strokes[strokeIndex] = newStroke
        
        // 5. Aggiorna il disegno sulla canvas per rendere visibile la modifica
        canvasView.drawing = drawing
    }
    
}

extension EditorModel {
    func getSelectedBounds() -> CGRect{
        if let layer = activeLayer(){
            if layer.type == .canvas{
                if let selectedStroke = selectedStroke
                {
                    return selectedStroke.renderBounds
                }
            }
        }
        return .zero
    }
    
    func onDragEnd(){
        if let layer = activeLayer(){
            if layer.type == .canvas{
                registerDrawing(layerCanvas()!.drawing, on: activeCanvasId, actionName: "dragging")
                originalStroke = nil
            }
            if layer.type == .image{
                originalImageTransform = nil
            }
        }
        
    }
    
    func onDragChanged(){
        originalStroke = selectedStroke
        originalDrawing = layerCanvas()?.drawing
        
        // --- AGGIUNGI QUESTA LOGICA ---
        if let imageLayer = activeLayer() as? LayerImageModel,
           let scrollView = imageLayer.scrollView as? CustomUIScrollView {
            originalImageTransform = scrollView.imageView.transform
        }
    }
    
    func onDragUpdateCanvas(newBounds:CGRect, anchor: HandleAnchor) {
        let newWidth = newBounds.width
        let newHeight = newBounds.height
        guard let originalStroke = originalStroke,
              let activeLayer = layerCanvas(),
              let canvas = activeLayer.canvas,
              let strokeIndex = activeLayer.drawing.strokes.firstIndex(where: { $0.randomSeed == originalStroke.randomSeed })
        else { return }
        
        let originalBounds = originalStroke.renderBounds
        guard originalBounds.width > 0, originalBounds.height > 0 else { return }
        
        let scaleX = newWidth / originalBounds.width
        let scaleY = newHeight / originalBounds.height
        
        var finalTransform = CGAffineTransform.identity
        
        let anchorPoint = anchorToPoint(bounds: originalBounds, anchor: anchor)
        
        if anchor == .center {
            let offsetX = newBounds.minX - originalBounds.minX
            let offsetY = newBounds.minY - originalBounds.minY
            finalTransform = finalTransform.translatedBy(x: offsetX, y: offsetY)
        }else{
            finalTransform = scaleTransform(anchorPoint: anchorPoint, scaleX: scaleX, scaleY: scaleY)
        }
        
        
        var previewStroke = originalStroke
        previewStroke.transform = originalStroke.transform.concatenating(finalTransform)
        
        // 5. Aggiorniamo il modello e la selezione per la preview
        var newStrokes = activeLayer.drawing.strokes
        newStrokes[strokeIndex] = previewStroke
        
        // Assegniamo un nuovo PKDrawing per forzare l'aggiornamento
        let drawing = PKDrawing(strokes: newStrokes)
        canvas.drawing = drawing
        activeLayer.drawing = drawing
        self.selectedStroke = activeLayer.drawing.strokes[strokeIndex]
    }
    
    func onDragUpdateImage(newBounds:CGRect, anchor: HandleAnchor) {
        
        guard let selectedImageLayerID = EditorModel.shared.selectedImageLayerID,
              let layer = findLayer(by: selectedImageLayerID)! as? LayerImageModel,
              let scrollView = layer.scrollView as? CustomUIScrollView
        else { return }
        layer.imageFrame = newBounds
        scrollView.imageView.frame = newBounds
        
    }
    
    func onDragUpdate(newBounds:CGRect, anchor: HandleAnchor) {
        
        if let layer = activeLayer(){
            if layer.type == .canvas{
                onDragUpdateCanvas(newBounds:newBounds, anchor: anchor)
            }
            if layer.type == .image{
                onDragUpdateImage(newBounds:newBounds, anchor: anchor)
            }
        }
    }
    
    func anchorToPoint(bounds:CGRect, anchor: HandleAnchor) -> CGPoint{
        var anchorPoint = CGPoint.zero
        switch anchor {
        case .bottomRight:
            anchorPoint = CGPoint(x: bounds.minX, y: bounds.minY)
        case .right:
            anchorPoint = CGPoint(x: bounds.minX, y: bounds.maxY)
        case .bottom:
            anchorPoint = CGPoint(x: bounds.minX, y: bounds.minY)
        case .center:
            anchorPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        case .bottomLeft:
            anchorPoint = CGPoint(x: bounds.maxX, y: bounds.minY)
        case .topRight:
            anchorPoint = CGPoint(x: bounds.minX, y: bounds.maxY)
        case .topLeft:
            anchorPoint = CGPoint(x: bounds.maxX, y: bounds.maxY)
        case .top:
            anchorPoint = CGPoint(x: bounds.midX, y: bounds.maxY)
        case .left:
            anchorPoint = CGPoint(x: bounds.maxX, y: bounds.midY)
        }
        return anchorPoint
    }
    
    
    
    func rotate(byDegrees degrees: Double){
        if let _ = selectedStroke {
            rotateStroke(byDegrees: degrees)
        }else{
            rotateDrawing(byDegrees: degrees)
        }
    }
    
    
    func rotateStroke(byDegrees degrees: Double){
        let rotation = CGFloat(degrees) * .pi / 180.0
        rotateStroke(rotation,state: UIRotationGestureRecognizer.State.ended)
    }
    
    func rotateStroke(_ rotation: CGFloat,state:UIRotationGestureRecognizer.State?){
        
        
        guard let layer = layerCanvas() , let canvasView = layer.canvas else { return }
        guard let selectedStroke = selectedStroke else { return }
        
        //if state == .began {
        //}
        
        print("rotateStroke")
        guard let strokeIndex = canvasView.drawing.strokes.firstIndex(where: { $0.randomSeed == selectedStroke.randomSeed }) else { return }
        
        // 2. Calcoliamo la rotazione attorno al centro dello stroke.
        let bounds = selectedStroke.renderBounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.rotated(by: rotation)
        transform = transform.translatedBy(x: -center.x, y: -center.y)
        
        // 3. Applichiamo la trasformazione allo stroke.
        var modifiedStroke = selectedStroke
        modifiedStroke.transform = selectedStroke.transform.concatenating(transform)
        
        // 4. Creiamo un nuovo disegno SOSTITUENDO lo stroke.
        var newStrokes = canvasView.drawing.strokes
        newStrokes.remove(at: strokeIndex) // Rimuoviamo il vecchio
        newStrokes.insert(modifiedStroke, at: strokeIndex) // Inseriamo quello nuovo
        
        let newDrawing = PKDrawing(strokes: newStrokes)
        
        // 5. Usiamo il nostro metodo di undo/redo che è già robusto.
        //EditorModel.shared.setNewDrawingUndoable(newDrawing, to: canvasView)
        //EditorModel.shared.setNewDrawingUndoable(newDrawing, to: layer)
        
        //if state == .ended {
        registerDrawing(
            newDrawing,
            on:layer.id,
            actionName: "rotateStroke"
        )
        
        
        EditorModel.shared.selectedStroke =  canvasView.drawing.strokes[strokeIndex]
        
        /*Task {
         if let canvas = layer.canvas, let coordinator = canvas.delegate as? LayerCanvasView.Coordinator {
         
         }
         }*/
        
        
        
    }
    
    
    func rotateDrawing(_ rotation: CGFloat,state:UIRotationGestureRecognizer.State?){
        
        guard let layer = layerCanvas() , let canvasView = layer.canvas else { return }
        
        let drawingBounds = canvasView.drawing.bounds
        guard !drawingBounds.isEmpty else { return }
        
        let center = CGPoint(x: drawingBounds.midX, y: drawingBounds.midY)
        
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.rotated(by: rotation)
        transform = transform.translatedBy(x: -center.x, y: -center.y)
        
        let newDrawing = canvasView.drawing.transformed(using: transform)
        
        
        //if state == .ended {
        registerDrawing(
            newDrawing,
            on:layer.id,
            actionName: "handleRotation"
        )
        
        //}else{
        //    layer.canvas?.drawing = newDrawing
        //}
        //if sender.state == .cancelled || sender.state == .failed {
        //}
    }
    
    func rotateDrawing(byDegrees degrees: Double) {
        let rotation = CGFloat(degrees) * .pi / 180.0
        rotateDrawing(rotation,state: UIRotationGestureRecognizer.State.ended)
    }
    
    
    
    func flipHorizontal(){
        guard let stroke = selectedStroke,let activeLayer = layerCanvas(),
              let canvas = activeLayer.canvas
        else { return }
        
        let centerPoint = CGPoint(x: stroke.renderBounds.midX, y: stroke.renderBounds.maxY)
        
        // 2. Crea la trasformazione di simmetria desiderata
        // let reflectionTransform = createVerticalReflection(aroundX: centerPoint.x)
        let reflectionTransform = createHorizontalReflection(aroundY: centerPoint.y)
        //let reflectionTransform = model.createPointReflection(around: centerPoint)
        
        
        //var symmetricalStroke = PKStroke(ink: stroke.ink, path: stroke.path, transform: stroke.transform, mask: stroke.mask)
        let color = shapeStampWrapper.toolItem.color
        
        var symmetricalStroke = stroke.copyWith(color:color)
        
        symmetricalStroke.transform = stroke.transform.concatenating(reflectionTransform)
        
        
        // 4. Aggiungi il nuovo stroke al tuo disegno
        //canvas.drawing.strokes.append(symmetricalStroke)
        
        var newStrokes = canvas.drawing.strokes
        newStrokes.append(symmetricalStroke)
        
        let newDrawing = PKDrawing(strokes: newStrokes)
        
        self.registerDrawing(
            newDrawing,
            on:activeLayer.id,
            actionName: "duplicateToNewLayer"
        )
    }
    
    func flipVertical(){
        guard let stroke = selectedStroke,let activeLayer = layerCanvas(),
              let canvas = activeLayer.canvas
        else { return }
        
        let centerPoint = CGPoint(x: stroke.renderBounds.maxX, y: stroke.renderBounds.midY)
        
        // 2. Crea la trasformazione di simmetria desiderata
        let reflectionTransform = createVerticalReflection(aroundX: centerPoint.x)
        
        let color = shapeStampWrapper.toolItem.color
        
        var symmetricalStroke = stroke.copyWith(color:color)
        
        
        symmetricalStroke.transform = stroke.transform.concatenating(reflectionTransform)
        
        symmetricalStroke.transform = stroke.transform.concatenating(reflectionTransform)
        
        //canvas.drawing.strokes.append(symmetricalStroke)
        
        var newStrokes = canvas.drawing.strokes
        newStrokes.append(symmetricalStroke)
        
        let newDrawing = PKDrawing(strokes: newStrokes)
        
        self.registerDrawing(
            newDrawing,
            on:activeLayer.id,
            actionName: "duplicateToNewLayer"
        )
    }
    
    func duplicateToNewLayer(){
        guard let stroke = selectedStroke
        else { return }
        guard let activeLayer = self.activeLayer() as? LayerCanvasModel, let _ = activeLayer.canvas
        else { return }
        
        
        //let newStroke = stroke.copy()
        let color = shapeStampWrapper.toolItem.color
        let newStroke = stroke.copyWith(color:color)
        
        
        addLayer()
        
        DispatchQueue.main.async {
            guard let activeLayer = self.activeLayer() as? LayerCanvasModel, let canvas = activeLayer.canvas else { return }
            
            var newStrokes = canvas.drawing.strokes
            newStrokes.append(newStroke)
            
            //canvas.drawing.strokes.append(newStroke)
            let newDrawing = PKDrawing(strokes: newStrokes)
            
            self.registerDrawing(
                newDrawing,
                on:activeLayer.id,
                actionName: "duplicateToNewLayer"
            )
            
            self.selectedStroke = nil
        }
    }
    
    func sendStrokeToBack() {
        // Assicurati di avere un riferimento al disegno attivo
        guard let selectedStroke = self.selectedStroke,let activeLayer = self.activeLayer() as? LayerCanvasModel,
              let activeCanvas = activeLayer.canvas
        else { return }
        
        var newStrokes = activeCanvas.drawing.strokes
        
        if let index = newStrokes.firstIndex(where: { $0 as AnyObject === selectedStroke as AnyObject }) {
            let strokeToMove = newStrokes.remove(at: index)
            newStrokes.insert(strokeToMove, at: 0)
            
            //activeCanvas.drawing = PKDrawing(strokes: newStrokes)
            let newDrawing = PKDrawing(strokes: newStrokes)
            
            
            registerDrawing(
                newDrawing,
                on:activeLayer.id,
                actionName: "sendStrokeToBack"
            )
        }
    }
    
    func bringStrokeToFront() {
        //guard let selectedStroke = self.selectedStroke,  let activeCanvas = self.activeLayer()?.canvas else { return }
        guard let selectedStroke = self.selectedStroke,
              let activeLayer = self.activeLayer() as? LayerCanvasModel
        else { return }
        
        var newStrokes = activeLayer.canvas!.drawing.strokes
        
        if let index = newStrokes.firstIndex(where: { $0 as AnyObject === selectedStroke as AnyObject }) {
            let strokeToMove = newStrokes.remove(at: index)
            newStrokes.append(strokeToMove)
            
            
            
            //activeCanvas.drawing = PKDrawing(strokes: newStrokes)
            let newDrawing = PKDrawing(strokes: newStrokes)
            
            
            registerDrawing(
                newDrawing,
                on:activeLayer.id,
                actionName: "bringStrokeToFront"
            )
        }
    }
    
    func deleteStroke() {
        guard let selectedStroke = self.selectedStroke,
              let activeLayer = self.activeLayer() as? LayerCanvasModel
        else { return }
        
        var newStrokes = activeLayer.canvas!.drawing.strokes
        
        if let index = newStrokes.firstIndex(where: { $0 as AnyObject === selectedStroke as AnyObject }) {
            newStrokes.remove(at: index)
            let newDrawing = PKDrawing(strokes: newStrokes)
            
            registerDrawing(
                newDrawing,
                on:activeLayer.id,
                actionName: "deleteStroke"
            )
        }
        self.selectedStroke = nil
        broadcastChanged()
    }
}

