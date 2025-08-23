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


// Il contenitore di più alto livello per il nostro export
struct ExportedProject: Codable {
    let projectName: String
    let contentSize: CGSize
    let backgroundColorHex: String // Salviamo il colore come stringa esadecimale
    let layers: [ExportedLayer]
    // Aggiungi qui altre proprietà del modello che vuoi esportare
}

// Rappresenta un singolo layer
struct ExportedLayer: Codable {
    let layerID: Int
    let opacity: Double
    let isVisible: Bool
    let drawing: ExportedDrawing
}

// Rappresenta un PKDrawing
struct ExportedDrawing: Codable {
    let bounds: CGRect
    let strokes: [ExportedStroke]
}

// Rappresenta un PKStroke
struct ExportedStroke: Codable {
    let inkType: String // "pen", "pencil", "marker"
    let colorHex: String
    //let width: CGFloat
    let transform: CGAffineTransform
    let path: ExportedStrokePath
}

// Rappresenta un PKStrokePath
struct ExportedStrokePath: Codable {
    let creationDate: Date
    let points: [ExportedStrokePoint]
}

struct ExportedStrokePoint: Codable {
    let location: CGPoint
    let timeOffset: TimeInterval
    let size: CGSize // Dimensione del punto
    let opacity: CGFloat
    let force: CGFloat
    let azimuth: CGFloat // Angolo di azimut della Apple Pencil
    let altitude: CGFloat // Angolo di altitudine (inclinazione) della Apple Pencil
}

extension EditorModel {

    /// Esporta l'intero progetto in un formato JSON dettagliato.
    /// - Returns: Una stringa JSON formattata o nil in caso di errore.
    func exportFullProjectAsJSON() -> String? {
        
        // --- 1. Raccogliamo i dati e li mappiamo sulle nostre strutture ---
        
        var exportedLayers: [ExportedLayer] = []
        
        for layer in self.layers {
            if let layer = layer as? LayerCanvasModel {
                var exportedStrokes: [ExportedStroke] = []
                
                for stroke in layer.drawing.strokes {
                    var exportedPoints: [ExportedStrokePoint] = []
                    
                    // Itera su ogni punto nel tracciato
                    stroke.path.forEach { point in
                        
                        // --- QUESTA È LA PARTE CORRETTA E COMPLETA ---
                        let exportedPoint = ExportedStrokePoint(
                            location: point.location,
                            timeOffset: point.timeOffset,
                            size: point.size,
                            opacity: point.opacity,
                            force: point.force,
                            azimuth: point.azimuth,
                            altitude: point.altitude
                        )
                        exportedPoints.append(exportedPoint)
                    }
                    
                    let exportedPath = ExportedStrokePath(
                        creationDate: stroke.path.creationDate,
                        points: exportedPoints
                    )
                    
                    let exportedStroke = ExportedStroke(
                        inkType: stroke.ink.inkType.description, // Otteniamo una descrizione
                        colorHex: stroke.ink.color.toHexString(), // Convertiamo il colore in esadecimale
                        //width: stroke.ink.width,
                        transform: stroke.transform,
                        path: exportedPath
                    )
                    exportedStrokes.append(exportedStroke)
                }
                
                let exportedDrawing = ExportedDrawing(
                    bounds: layer.drawing.bounds,
                    strokes: exportedStrokes
                )
                
                let exportedLayer = ExportedLayer(
                    layerID: layer.id,
                    opacity: layer.opacity,
                    isVisible: layer.visible,
                    drawing: exportedDrawing
                )
                exportedLayers.append(exportedLayer)
            }
        }
        
        let project = ExportedProject(
            projectName: self.projectName,
            contentSize: self.contentSize,
            backgroundColorHex: self.backgroundColor.toHexString(),
            layers: exportedLayers
        )
        
        // --- 2. Codifichiamo l'oggetto in JSON ---
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // Per una stringa JSON leggibile

        do {
            let data = try encoder.encode(project)
            return String(data: data, encoding: .utf8)
        } catch {
            print("❌ Errore durante l'esportazione in JSON: \(error)")
            return nil
        }
    }
}

// Aggiungi queste estensioni helper per convertire i tipi non-Codable

extension PKInk.InkType {
    var description: String {
        switch self {
        case .pen: return "pen"
        case .pencil: return "pencil"
        case .marker: return "marker"
        case .monoline: return "monoline"
        case .fountainPen: return "fountainPen"
        case .watercolor: return "watercolor"
        case .crayon:return "crayon"
        @unknown default: return "unknown"
        }
    }
}

extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
    }
}
