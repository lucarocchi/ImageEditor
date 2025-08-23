//
//  Editor+Path.swift
//  PKEditor
//
//  Created by Luca Rocchi on 20/07/25.
//

import Foundation
import Combine
import UIKit
import PencilKit

extension EditorModel {
    func startPathCreation() {
        // Deseleziona qualsiasi stroke per evitare confusione
        selectedStroke = nil
        
        // Pulisce i punti da una sessione precedente
        currentPathPoints.removeAll()
        
        // Imposta la nuova modalità
        drawingMode = .creatingPath
        
        print(" modalità Creazione Tracciato ATTIVATA.")
    }
    
    /// Aggiunge un nuovo punto al tracciato corrente.
    func addPointToCurrentPath(_ point: CGPoint) {
        currentPathPoints.append(point)
    }
    
    /// Finalizza il tracciato, lo converte in un PKStroke e torna alla modalità standard.
    func finalizeCurrentPath() {
        // Assicurati che ci siano almeno due punti per creare una linea
        guard currentPathPoints.count > 1,
              let activeLayer = layers.first(where: { $0.id == activeCanvasId }),
              let layerCanvasModel = activeLayer as? LayerCanvasModel,
              let canvas = layerCanvasModel.canvas else {
            // Se non ci sono abbastanza punti, semplicemente annulla l'operazione.
            cancelPathCreation()
            return
        }
        
        // Usiamo il nostro motore 'TessellateStroke' per creare lo stroke.
        // Possiamo usare il colore e lo spessore del tool di testo, per esempio.
        let ink = PKInk(.pen, color: textStampWrapper.toolItem.color)
        let width = textStampWrapper.toolItem.width
        
        if let newStroke = TessellateStroke.createStrokeFromSubpath(points: currentPathPoints, ink: ink, width: width) {
            
            // Aggiungiamo il nuovo stroke al disegno con la logica di undo
            let newDrawing = canvas.drawing.appending(PKDrawing(strokes: [newStroke]))
            registerDrawing(newDrawing, on: activeLayer.id,actionName: "path")
 
            
        }
        
        // Resettiamo lo stato per finire.
        cancelPathCreation()
    }
    
    /// Annulla la creazione del tracciato e torna alla modalità standard.
    func cancelPathCreation() {
        currentPathPoints.removeAll()
        drawingMode = .standard
        print(" modalità Creazione Tracciato DISATTIVATA.")
    }
}
