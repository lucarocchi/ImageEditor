//
//  LayerModel.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//

import Foundation
//@MainActor
import PencilKit


class LayerCanvasModel:LayerModel, Codable {
     
    var canvas:CustomPKCanvasView?

    var drawing: PKDrawing = PKDrawing()
    //@Published
    var drawingPolicy: PKCanvasViewDrawingPolicy = .anyInput
  
    
    enum CodingKeys: String, CodingKey {
        case currentCanvasId
        case drawing
        case opacity
        case visible
        case name
        
    }
    
    init(currentCanvasId:Int){
        super.init(currentCanvasId:currentCanvasId, type: .canvas)
       
    }
    
    // 3. Aggiungiamo l'inizializzatore richiesto da Codable
    
    required init(from decoder: Decoder) throws {
           let container = try decoder.container(keyedBy: CodingKeys.self)
           let id = try container.decode(Int.self, forKey: .currentCanvasId)
           super.init(currentCanvasId: id, type: .canvas)
           
           self.drawing = try container.decode(PKDrawing.self, forKey: .drawing)
           self.opacity = try container.decode(Double.self, forKey: .opacity)
           self.visible = try container.decode(Bool.self, forKey: .visible)
        
            self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Layer \(id)"
       }
    
    
    // Nota: PKCanvasViewDrawingPolicy non è Codable, quindi l'ho escluso dal salvataggio.
    // Se necessario, dovremmo gestire la sua conversione manualmente (es. salvando il suo rawValue).
    // 4. Aggiungiamo la funzione di codifica richiesta da Codable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentCanvasId, forKey: .currentCanvasId)
        try container.encode(drawing, forKey: .drawing)
        try container.encode(opacity, forKey: .opacity)
        try container.encode(visible, forKey: .visible)
        try container.encode(name, forKey: .name)
    }
    
    
    
    /*
     if UIDevice.current.userInterfaceIdiom == .pad {
     // Su iPad, accettiamo solo l'Apple Pencil per disegnare
     // e usiamo le dita per scorrere/zoomare.
     canvasView.drawingPolicy = .pencilOnly
     } else {
     // Su iPhone, dobbiamo per forza accettare il dito per disegnare.
     canvasView.drawingPolicy = .anyInput
     }
     
     func saveImage () {
     let image = canvas.drawing.image (from:
     canvas. drawing.bounds, scale: 1.0)
     UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
     ｝
     */
    
    func setDrawPolicy(policy:PKCanvasViewDrawingPolicy){
        drawingPolicy = policy
    }
}
