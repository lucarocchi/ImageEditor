//
//  EditorModel.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//

import Foundation
import Combine
import UIKit
import PencilKit

struct ProjectItem: Identifiable {
    let id = UUID() // Aggiunto per conformità a Identifiable
    let name: String
    let url: URL
    let image: URL
}

// Struct per il salvataggio dei dati del progetto
struct ProjectData: Codable {
    let layers: [LayerModel]
    let contentSize: CGSize
    let contentOffset: CGPoint
    let backgroundColor:UIColor
    let backgroundImage:UIImage?
    let gestureMap:UInt8
    // Chiavi per la codifica/decodifica
    enum CodingKeys: String, CodingKey {
        case contentSize
        case contentOffset
        case backgroundColorData // Salveremo il colore come Data
        case backgroundImageData
        case layers
        case gesture
    }
    
    // Un "contenitore" intermedio per la codifica/decodifica dei layer
    private enum LayerCodingKeys: String, CodingKey {
        case type, payload
    }
    
    // --- DECODIFICA MANUALE ---
    // Sostituisci il tuo init(from:) con questo
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // --- GESTIONE RETROCOMPATIBILE DELLE PROPRIETÀ ---
        // Usiamo decodeIfPresent e forniamo un valore di default con '??'
        // nel caso in cui la chiave manchi in un vecchio file di progetto.
        
        contentSize = try container.decodeIfPresent(CGSize.self, forKey: .contentSize) ?? CGSize(width: 1000, height: 1000)
        contentOffset = try container.decodeIfPresent(CGPoint.self, forKey: .contentOffset) ?? .zero

        if let colorData = try container.decodeIfPresent(Data.self, forKey: .backgroundColorData) {
            backgroundColor = UIColor.decode(from: colorData) ?? .white
        } else {
            backgroundColor = .white // Default per i file vecchi
        }

        if let imageData = try container.decodeIfPresent(Data.self, forKey: .backgroundImageData) {
            self.backgroundImage = UIImage(data: imageData)
        } else {
            self.backgroundImage = nil // Default per i file vecchi
        }
        
        if let gesture = try container.decodeIfPresent(UInt8.self, forKey: .gesture) {
            self.gestureMap = gesture
        } else {
            self.gestureMap = 0
        }
        
        
        // --- LOGICA PER I LAYER (la tua, che è corretta) ---
        // Usiamo decodeIfPresent anche qui per i file che potrebbero non avere layer
        if var layersContainer = try? container.nestedUnkeyedContainer(forKey: .layers) {
            var tempLayers: [LayerModel] = []
            while !layersContainer.isAtEnd {
                do {
                    let layerWrapper = try layersContainer.nestedContainer(keyedBy: LayerCodingKeys.self)
                    
                    var type = LayerType.canvas
                    if let type0 = try layerWrapper.decodeIfPresent(LayerType.self, forKey: .type) {
                        type = type0
                    }
                   
                    
                    switch type {
                    case .canvas:
                        let pencilLayer = try layerWrapper.decode(LayerCanvasModel.self, forKey: .payload)
                        
                        tempLayers.append(pencilLayer)
                    case .image:
                        let imageLayer = try layerWrapper.decode(LayerImageModel.self, forKey: .payload)
                        
                        tempLayers.append(imageLayer)
                        break
                    }
                } catch {
                    // Se un singolo layer non può essere decodificato, lo saltiamo invece di far crashare tutto
                    print("Attenzione: impossibile decodificare un layer. Lo salto. Errore: \(error)")
                    continue
                }
            }
            self.layers = tempLayers
        } else {
            // Se la chiave 'layers' non esiste, iniziamo con un array vuoto
            self.layers = []
            
            
        }
    }
     
    /*
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // --- DECODING WITH DEFAULTS ---

        // For each property, we now use decodeIfPresent and provide a default value
        // with '??' in case the key is missing from an old project file.
        
        contentSize = try container.decodeIfPresent(CGSize.self, forKey: .contentSize) ?? CGSize(width: 1000, height: 1000)
        
        contentOffset = try container.decodeIfPresent(CGPoint.self, forKey: .contentOffset) ?? .zero
        
        layers = try container.decodeIfPresent([LayerPencilCanvasModel].self, forKey: .layers) ?? []

        if let colorData = try container.decodeIfPresent(Data.self, forKey: .backgroundColorData) {
            backgroundColor = UIColor.decode(from: colorData) ?? .white
        } else {
            // Default color for very old files
            backgroundColor = .white
        }

        if let imageData = try container.decodeIfPresent(Data.self, forKey: .backgroundImageData) {
            backgroundImage = UIImage(data: imageData)
        } else {
            // Default background image
            backgroundImage = nil
        }
    }
    */
    
    // --- CODIFICA MANUALE ---
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Codifica le proprietà standard
        try container.encode(contentSize, forKey: .contentSize)
        try container.encode(contentOffset, forKey: .contentOffset)
        try container.encode(gestureMap, forKey: .gesture)
    
        // Codifica il colore
        if let colorData = backgroundColor.encode() {
            try container.encode(colorData, forKey: .backgroundColorData)
        }
        
        // Codifica l'immagine opzionale
        if let imageData = backgroundImage?.pngData() {
            try container.encode(imageData, forKey: .backgroundImageData)
        }
        
        // Codifica l'array di layer eterogeneo
        var layersContainer = container.nestedUnkeyedContainer(forKey: .layers)
        for layer in layers {
            var layerWrapper = layersContainer.nestedContainer(keyedBy: LayerCodingKeys.self)
            switch layer.type {
            case .canvas:
                try layerWrapper.encode(layer.type, forKey: .type)
                try layerWrapper.encode(layer as? LayerCanvasModel, forKey: .payload)
            case .image:
                try layerWrapper.encode(layer.type, forKey: .type)
                 // Encode the layer object itself, cast to its concrete type
                 try layerWrapper.encode(layer as? LayerImageModel, forKey: .payload)
      
                break
            }
        }
    }
        
        // Init personalizzato completo
    init(contentSize: CGSize, contentOffset: CGPoint, backgroundColor: UIColor, backgroundImage: UIImage?, layers: [LayerModel],gesture:UInt8) {
            self.contentSize = contentSize
            self.contentOffset = contentOffset
            self.backgroundColor = backgroundColor
            self.backgroundImage = backgroundImage
            self.layers = layers
            self.gestureMap = gesture
        }
}


extension EditorModel {
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func checkIfProjectExists(name:String) -> Bool {
        let filename = "\(name).json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let filePath = url.path
        let fileManager = FileManager.default
        let exists = fileManager.fileExists(atPath: filePath)
        return exists
    }
    
    func saveProject(name:String? = nil) {
        let newName = name ?? projectName
        
        let filename = "\(newName).json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        
        let thumbFilename = "\(newName).png"
        let thumbUrl = getDocumentsDirectory().appendingPathComponent(thumbFilename)
        
        var gestureMap:UInt8 = 0
        if isPanEnabled {
            gestureMap |= 1 << 0
        }
        if isZoomEnabled {
            gestureMap |= 1 << 1
        }
        if isRotationEnabled {
            gestureMap |= 1 << 2
        }
         
        let projectData = ProjectData(contentSize: self.contentSize, contentOffset: self.contentOffset,backgroundColor: backgroundColor,backgroundImage:self.backgroundImage,layers: self.layers,gesture:gestureMap)
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(projectData)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            print("✅ Progetto salvato con successo in: \(url.path)")
            projectName = newName
            
            
            if let image = renderLayers() , let pngData =  image.pngData() {
                // Ora puoi salvare questo 'pngData' su file
                
                try pngData.write(to: thumbUrl, options: [
                    .atomic
                ])
            }
            
            
            if let jsonString = EditorModel.shared.exportFullProjectAsJSON() {
                print(jsonString)
                let jsonFilename = "\(newName).data"
                let jsonUrl = getDocumentsDirectory().appendingPathComponent(jsonFilename)
                if let jsonData = jsonString.data(using: .utf8){
                    try jsonData.write(to: jsonUrl, options: [
                        .atomic
                    ])
                }
                // Qui potresti salvare la stringa su un file o copiarla negli appunti
            }
        } catch {
            print("❌ Errore durante il salvataggio del progetto: \(error.localizedDescription)")
        }
        
        if name != nil {
            self.recentProjects = getRecentProjects()
            DispatchQueue.main.async{
                self.createPopupMenu()
            }
            
        }
    }
    
    func newProject(){
        //canvasViews.removeAll()
        layers.removeAll()
        projectName = defProjectName
        addLayer()
        activeCanvasId = 1
        backgroundImage = nil
        projectId = UUID()
        contentOffset = .zero
        contentSize = CGSize(width: 800, height: 800)
        showTextInput = false
        backgroundColor = .white
        selectedStroke = nil
        broadcastChanged()
    }
    
    func renameProject(to newName:String){
        let project = self.recentProjects.first { $0.name == projectName }
        if let project = project {
            let fileManager = FileManager.default
            
            // Array delle URL da cancellare
            let urlsToRename = [project.url, project.image]
            
            for url in urlsToRename {
                do {
                    let directory = url.deletingLastPathComponent()
                    let fileExtension = url.pathExtension
                    
                    // 2. Create the new URL by combining the directory, new name, and old extension
                    let destinationURL = directory
                        .appendingPathComponent(newName)
                        .appendingPathExtension(fileExtension)
                    
                    // 3. Perform the move/rename operation
                    try fileManager.moveItem(at: url, to: destinationURL)
                    print("✅ File renamed to: \(destinationURL.lastPathComponent)")
                    
                       
                } catch {
                    // Gestisci l'errore se la cancellazione fallisce
                    print("🛑 Errore durante il rename del file \(url.lastPathComponent): \(error.localizedDescription)")
                    return
                }
            }
            recentProjects = getRecentProjects()
            projectName = newName
        }
        
    }
  
    func deleteProject(){
        let project = self.recentProjects.first { $0.name == projectName }
        if let project = project {
            let fileManager = FileManager.default
            
            // Array delle URL da cancellare
            let urlsToDelete = [project.url, project.image]
            
            for url in urlsToDelete {
                do {
                    // Tenta di rimuovere il file all'URL specificato
                    try fileManager.removeItem(at: url)
                    print("✅ File eliminato con successo: \(url.lastPathComponent)")
                } catch {
                    // Gestisci l'errore se la cancellazione fallisce
                    print("🛑 Errore durante l'eliminazione del file \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
            recentProjects = getRecentProjects()
            newProject()
        }
    }
    
    /// Carica un progetto da un file JSON e sostituisce i layer correnti.
    func loadProject(_ name: String = "drawingProject") {
        let filename = "\(name).json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        loadProject(from: url)
        
        
    }
    
    func loadProject(from url: URL) {
        if url.pathExtension == "pdf" {
            if  let image = drawPDFfromURL(url: url){
                newProjectFromImage(image)
             
            }
            broadcastChanged()
            DispatchQueue.main.async{
                self.zoomToFit()
            }
            return
        }
        
        guard url.pathExtension == "json" else {
            return
        }
        
        let name = url.deletingPathExtension().lastPathComponent
        //canvasViews.removeAll()
        
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: url)
            
            let loadedProject = try decoder.decode(ProjectData.self, from: data)
            self.contentSize = loadedProject.contentSize
            self.contentOffset = loadedProject.contentOffset
            self.layers = loadedProject.layers
            self.backgroundColor = loadedProject.backgroundColor
            self.backgroundImage = loadedProject.backgroundImage
            
            let gesture = loadedProject.gestureMap
            self.isPanEnabled = (gesture & (1 << 0)) != 0
            self.isZoomEnabled = (gesture & (1 << 1)) != 0
            self.isRotationEnabled = (gesture & (1 << 2)) != 0
            
            contentOffset = .zero
            
            
            activeCanvasId = layers.first?.id ?? 1
         
            projectName = name
            self.projectId = UUID()
            showTextInput = false
            broadcastChanged()
            DispatchQueue.main.async{
                self.zoomToFit()
            }
            print("✅ Progetto caricato con successo.")
        } catch {
            print("❌ Errore durante il caricamento del progetto: \(error.localizedDescription)")
        }
        if layers.count == 0 {
            print("❌ Errore durante il caricamento del progetto...")
            addLayer()
        }
    }
    
    func exportToGallery()  {
        if let compositeImage = renderLayers() {
            UIImageWriteToSavedPhotosAlbum(compositeImage, self, #selector(imageSaveCompletion), nil)
            EditorModel.shared.showGallery = true
        }
    }
    
    
    func renderLayers() -> UIImage? {
        
        let renderFrame = CGRect(origin: .zero, size: self.contentSize)
        
        // Controlliamo che la dimensione sia valida.
        guard renderFrame.width > 0, renderFrame.height > 0 else {
            print("Dimensioni del contentSize non valide per l'esportazione.")
            return nil
        }
        
        
        //let visibleLayers = self.layers.filter { $0.visible && !$0.drawing.bounds.isEmpty }
        
        /*guard !visibleLayers.isEmpty else {
         print("Nessun layer visibile con contenuto da esportare.")
         return nil
         }*/
        
        
        let renderer = UIGraphicsImageRenderer(size: contentSize)
        let compositeImage = renderer.image { context in
            // Disegniamo i layer uno sopra l'altro, dal basso verso l'alto
            
            if let bgImage = self.backgroundImage {
                bgImage.draw(in: renderFrame)
                //self.backgroundColor.setFill()
                //context.fill(renderFrame, blendMode: .normal) // La velatura si mescola
                
            } else {
                // 3. ALTRIMENTI, USA SOLO IL COLORE DI SFONDO
                self.backgroundColor.setFill()
                context.fill(renderFrame)
            }
            
            for layer in self.layers {
                // Se il layer non è visibile, lo saltiamo
                guard layer.visible else { continue }
                
                if layer.index == 0 {
                    //self.backgroundColor.setFill()
                    //context.fill(renderFrame)
                }
                if layer.type == .canvas{
                    // Generiamo l'immagine per questo singolo layer
                    let layerCanvasModel = layer as! LayerCanvasModel
                 
                    let layerImage = layerCanvasModel.drawing.image(from: renderFrame, scale: UIScreen.main.scale)
                    
                    // Disegniamo l'immagine nel contesto, rispettando la sua opacità
                    layerImage.draw(in: renderFrame, blendMode: .normal, alpha: layer.opacity)
                }
                if layer.type == .image {
                   
                    guard let layerImageModel = layer as? LayerImageModel,
                          let imageToDraw = layerImageModel.image,
                          let scrollView = layerImageModel.scrollView as? CustomUIScrollView else {
                        continue // Skip this layer if it's not configured correctly.
                    }

                    let containerView = scrollView.containerView
                    let imageView = scrollView.imageView

                    context.cgContext.saveGState()

                    context.cgContext.setAlpha(CGFloat(layer.opacity))

                    /*context.cgContext.concatenate(containerView.transform)
                    context.cgContext.translateBy(x: -scrollView.contentOffset.x, y: -scrollView.contentOffset.y)*/

                    imageToDraw.draw(in: imageView.frame)
                    print("imageFrame render \(imageView.frame)")
                    context.cgContext.restoreGState()
                }
            }
        }
        return compositeImage
        
    }
    
    @objc func imageSaveCompletion(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("❌ Errore nel salvataggio dell'immagine composita: \(error.localizedDescription)")
        } else {
            print("✅ Immagine composita salvata con successo nella galleria!")
        }
    }
    
    
    func getRecentProjects() -> [ProjectItem] {
        self.recentProjects.removeAll()
        
        // Otteniamo il percorso della nostra cartella Documents
        guard let documentsURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            print("❌ Impossibile accedere alla cartella Documents.")
            return []
        }
        
        do {
            // 1. Otteniamo gli URL di tutti i file nella cartella
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.contentModificationDateKey], options: [])
            
            // 2. Filtriamo per tenere solo i file .json e otteniamo la loro data di modifica
            let jsonFiles = try fileURLs.compactMap { url -> (url: URL, modDate: Date)? in
                // Filtra per estensione .json
                guard url.pathExtension == "json" else {
                    return nil
                }
                // Ottieni le proprietà del file, inclusa la data di modifica
                let resources = try url.resourceValues(forKeys: [.contentModificationDateKey])
                guard let modificationDate = resources.contentModificationDate else {
                    return nil
                }
                return (url: url, modDate: modificationDate)
            }
            
            // 3. Ordiniamo l'array per data, dalla più recente alla più vecchia
            let sortedFiles = jsonFiles.sorted { $0.modDate > $1.modDate }
            
            // 4. Estraiamo solo i nomi dei file, rimuovendo l'estensione .json
            
            
            var projectItems:[ProjectItem] = sortedFiles.map {
                
                let deletedExt = $0.url.deletingPathExtension()
                let projectItem =  ProjectItem(name:deletedExt.lastPathComponent,url: $0.url,image: deletedExt.appendingPathExtension("png"))
                return projectItem
            }
            
            print("✅ Trovati progetti recenti: \(projectItems)")
            projectItems = Array(projectItems.prefix(10))
            return projectItems
            
        } catch {
            print("❌ Errore durante la lettura dei file: \(error.localizedDescription)")
            return []
        }
    }
    
    func publish(){
        if let image = renderLayers() {
            saveProject()
            onPublish?(image)
        }
    }
    
    func exit(){
        //hideTools()
        DispatchQueue.main.async {
            self.saveProject()
            self.layers.removeAll()
            self.onExit?()
        }
       
    }
    
    func newProjectFromImage(_ image: UIImage) {
        // Resetta lo stato del progetto
        layers.removeAll()
        contentOffset = .zero
        zoomScale = 1.0
        
        // Imposta la dimensione della tela sulla dimensione dell'immagine
        self.contentSize = image.size
        
        // Salva l'immagine nel modello. Le viste reagiranno a questo cambiamento.
        self.backgroundImage = image
        self.backgroundColor = .clear
        
        // Aggiunge il primo layer
        addLayer()
        activeCanvasId = layers.first?.id ?? 1
        selectedStroke = nil
        // Forza la ricostruzione della UI
        projectId = UUID()
        DispatchQueue.main.async{
            self.zoomToFit()
        }
    }
}


