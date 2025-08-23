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



extension EditorModel {
    
  
    
    @MainActor
    func convertCtoV(contentSize: CGSize) -> CGSize? {
        // 1. Troviamo la PKCanvasView attiva per ottenere il suo zoomScale.
        /*guard let layerCanvasModel = layerCanvas(),
              let canvas = layerCanvasModel.canvas else {
            print("Errore di conversione: Canvas attiva non trovata.")
            return nil
        }*/
        guard let layer = activeLayer(),
              let canvas = layer.scrollView else {
            print("Errore di conversione: Canvas attiva non trovata.")
            return nil
        }
        // 2. Applichiamo il fattore di zoom.
        //    Moltiplichiamo la larghezza e l'altezza per lo zoomScale per
        //    ottenere la dimensione come appare nella vista.
        let viewSize = CGSize(width: contentSize.width * canvas.zoomScale,
                              height: contentSize.height * canvas.zoomScale)
                              
        return viewSize
    }

    /// Converte una dimensione (CGSize) dal sistema di coordinate della vista
    /// a quello della canvas.
    ///
    /// Questa funzione tiene conto solo del fattore di zoom, poiché l'offset
    /// di scorrimento non si applica a una dimensione.
    ///
    /// - Parameter viewSize: La dimensione nel sistema di coordinate della vista.
    /// - Returns: La dimensione corrispondente nel sistema di coordinate della canvas,
    ///            o nil se la canvas attiva non viene trovata o lo zoom è 0.
    @MainActor
    func convertVtoC(viewSize: CGSize) -> CGSize? {
        
        guard let layer = activeLayer(),
              let canvas = layer.scrollView else {
            print("Errore di conversione: Canvas attiva non trovata.")
            return nil
        }
        // Assicuriamoci di non dividere per zero.
        guard canvas.zoomScale > 0 else {
            print("Errore di conversione: zoomScale è 0.")
            return nil
        }
        
        // 2. Invertiamo il fattore di zoom.
        //    Dividiamo la larghezza e l'altezza per lo zoomScale per ottenere
        //    la dimensione reale nel disegno (scala 1:1).
        let canvasSize = CGSize(width: viewSize.width / canvas.zoomScale,
                                height: viewSize.height / canvas.zoomScale)
                                
        return canvasSize
    }

    
    @MainActor
    func convertCtoV(point: CGPoint) -> CGPoint? {
        // 1. Troviamo la PKCanvasView attiva.
        /*guard let activeLayer = layers.first(where: { $0.id == activeCanvasId }),let layerCanvasModel = activeLayer as? LayerCanvasModel,
              let canvas = layerCanvasModel.canvas else {
            print("Errore di conversione: Canvas attiva non trovata.")
            return nil
        }*/
        guard let layer = activeLayer(),
              let canvas = layer.scrollView else {
            print("Errore di conversione: Canvas attiva non trovata.")
            return nil
        }
        // 2. Teniamo conto dello zoom.
        //    Moltiplichiamo il punto per il fattore di zoom per trovare la sua
        //    posizione nel contenuto "zoomato".
        let scaledPoint = CGPoint(x: point.x * canvas.zoomScale,
                                  y: point.y * canvas.zoomScale)
                                  
        // 3. Teniamo conto dello scorrimento (contentOffset).
        //    Sottraiamo l'offset per trovare la posizione finale relativa
        //    all'angolo in alto a sinistra della cornice visibile della vista.
        let viewPoint = CGPoint(x: scaledPoint.x - canvas.contentOffset.x,
                                y: scaledPoint.y - canvas.contentOffset.y)
                                
        return viewPoint
    }
    
    @MainActor
    func convertVtoC(viewPoint: CGPoint) -> CGPoint? {
        // 1. Troviamo la PKCanvasView attiva, perché abbiamo bisogno del suo stato.
        /*guard let activeLayer = layers.first(where: { $0.id == activeCanvasId }),let layerCanvasModel = activeLayer as? LayerCanvasModel,
              let canvas = layerCanvasModel.canvas else {
            print("Errore di conversione: Canvas attiva non trovata.")
            return nil
        }*/
        guard let layer = activeLayer(),
              let canvas = layer.scrollView else {
            print("Errore di conversione: Canvas attiva non trovata.")
            return nil
        }
        // 2. Teniamo conto dello scorrimento (contentOffset).
        //    Aggiungiamo l'offset al punto della vista per trovare la sua posizione
        //    nel contenuto non zoomato.
        let pointWithOffset = CGPoint(x: viewPoint.x + canvas.contentOffset.x,
                                      y: viewPoint.y + canvas.contentOffset.y)
                                      
        // 3. Teniamo conto dello zoom.
        //    Dividiamo per il fattore di zoom per "restringere" il punto e trovare
        //    la sua coordinata reale nel disegno originale (scala 1:1).
        guard canvas.zoomScale > 0 else { return nil }
        let pointInDrawing = CGPoint(x: pointWithOffset.x / canvas.zoomScale,
                                     y: pointWithOffset.y / canvas.zoomScale)
                                     
        return pointInDrawing
    }
    
  
    /// Directly sets the contentOffset on all other canvases.
    func propagateScrollOffset(_ offset: CGPoint, from sourceLayerID: Int) {
        // We iterate through our main source of truth: the layers array.
        for layer in layers {
            // We only update the canvases that are NOT the source of the scroll.
            if layer.id != sourceLayerID {
                // Access the canvas directly from the layer model.
                //if let layer = layer as? LayerCanvasModel{
                    layer.scrollView?.contentOffset = offset
                //}
            }
        }
    }
    
    /// Directly sets the zoomScale on all other canvases.
    func propagateZoomScale(_ scale: CGFloat, from sourceLayerID: Int) {
        print(" propagateZoomScale \(scale) ")
        for layer in layers {
            if layer.id != sourceLayerID {
                layer.scrollView?.zoomScale = scale
            
                if let layer = layer as? LayerImageModel{
                    print("LayerImageModel propagateZoomScale \(layer.scrollView?.zoomScale ?? 0) ")
                }
                if let layer = layer as? LayerCanvasModel{
                    print("LayerCanvasModel propagateZoomScale \(layer.scrollView?.zoomScale ?? 0) ")
                }
            }
        }
    }
    
    
    func propagateTransform(_ transform: CGAffineTransform, from sourceLayerID: Int) {
        for layer in layers {
            if layer.id != sourceLayerID {
                // Applichiamo la stessa identica transform
                layer.scrollView?.transform = transform
            }
        }
    }
    
    
    func scaleTransform(anchorPoint:CGPoint,scaleX:CGFloat,scaleY:CGFloat) -> CGAffineTransform{
        var finalTransform = CGAffineTransform.identity
   
        finalTransform = finalTransform.translatedBy(x: anchorPoint.x, y: anchorPoint.y)
        finalTransform = finalTransform.scaledBy(x: scaleX, y: scaleY)
        finalTransform = finalTransform.translatedBy(x: -anchorPoint.x, y: -anchorPoint.y)
        return finalTransform
    }
    
    func createPointReflection(around point: CGPoint) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        // 1. Sposta il punto all'origine
        transform = transform.translatedBy(x: point.x, y: point.y)
        // 2. Ruota di 180 gradi
        transform = transform.rotated(by: .pi)
        // 3. Riporta il punto alla sua posizione originale
        transform = transform.translatedBy(x: -point.x, y: -point.y)
        return transform
    }
    
    func createVerticalReflection(aroundX x: CGFloat) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        // 1. Sposta l'asse all'origine
        transform = transform.translatedBy(x: x, y: 0)
        // 2. Inverti la scala sull'asse X (la riflessione vera e propria)
        transform = transform.scaledBy(x: -1, y: 1)
        // 3. Riporta l'asse alla sua posizione originale
        transform = transform.translatedBy(x: -x, y: 0)
        return transform
    }
    
    func createHorizontalReflection(aroundY y: CGFloat) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        // 1. Sposta l'asse all'origine
        transform = transform.translatedBy(x: 0, y: y)
        // 2. Inverti la scala sull'asse Y
        transform = transform.scaledBy(x: 1, y: -1)
        // 3. Riporta l'asse alla sua posizione originale
        transform = transform.translatedBy(x: 0, y: -y)
        return transform
    }
}


extension EditorModel {
    func removeFilterToBackgroundImage() {
        if self.originalBackgroundImage != nil {
            self.backgroundImage = self.originalBackgroundImage
            self.originalBackgroundImage = nil
            self.activeFilter = nil
        }
    }
    func applyFilterToBackgroundImage(filter:PKFilterType) {
            // 1. Make sure there is a background image to filter.
            guard let originalImage = self.backgroundImage else {
                print("No background image to apply a filter to.")
                return
            }
            
            self.activeFilter = filter
 
            // 2. Make sure there is a filter selected.
            guard let filter = self.activeFilter else {
                print("No active filter selected.")
                // Optionally, you could revert to the original image if the filter is nil
                return
            }
           
            
            // 3. Call our existing helper function to perform the Core Image filtering.
            if let filteredImage = applyFilter(to: originalImage, filterType: filter) {
                if self.originalBackgroundImage == nil {
                    self.originalBackgroundImage = self.backgroundImage
                }
                // 4. Update the backgroundImage property with the new, filtered image.
                //    Because it's @Published, any view using it will update automatically.
                self.backgroundImage = filteredImage
                print("✅ Filter successfully applied to the background image.")
                
            } else {
                print("❌ Failed to apply the filter to the background image.")
            }
        }

        // This is our existing helper function that does the actual Core Image work.
        // Make sure it's present in your model or an extension.
        func applyFilter(to inputImage: UIImage, filterType: PKFilterType) -> UIImage? {
            let originalOrientation = inputImage.imageOrientation
            let originalScale = inputImage.scale
          
            guard let ciImage = CIImage(image: inputImage) else { return nil }
            
            // Use your FilterType enum to get the configured CIFilter
            let filter = filterType.coreImageFilter
            //filter.inputImage = ciImage
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            
            guard let outputImage = filter.outputImage else { return nil }
            
            let context = CIContext()
            guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
            
            return UIImage(cgImage: cgImage, scale: originalScale, orientation: originalOrientation)
            //return UIImage(cgImage: cgImage)
        }
}
