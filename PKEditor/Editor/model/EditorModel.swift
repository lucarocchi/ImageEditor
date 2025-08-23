//
//  EditorModel.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//

import Foundation
import Combine
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
@preconcurrency import PencilKit


// 1. Definiamo i diversi stati in cui si può trovare il nostro editor.
enum LayerType : String, Codable{
    case canvas 
    case image
}

enum DrawingMode {
    case standard // Disegno normale con gli strumenti di PencilKit
    case creatingPath // La nostra nuova modalità per creare tracciati
}

extension UIImage {
    func addCIFilter(filter : CIFilterType) -> UIImage {
        let filter = CIFilter(name: filter.rawValue)
        // convert UIImage to CIImage and set as inputlet
        let ciInput = CIImage(image: self)
        filter?.setValue(ciInput, forKey: "inputImage")
        // get output CIImage, render as CGImage first to retain properUIImage scale
        let ciOutput = filter?.outputImage
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
        //Return the image
        return UIImage(cgImage: cgImage!)
    }
}

enum CIFilterType : String {
    case Chrome = "CIPhotoEffectChrome"
    case Fade = "CIPhotoEffectFade"
    case Instant = "CIPhotoEffectInstant"
    case Mono = "CIPhotoEffectMono"
    case Noir = "CIPhotoEffectNoir"
    case Process = "CIPhotoEffectProcess"
    case Tonal = "CIPhotoEffectTonal"
    case Transfer =  "CIPhotoEffectTransfer"}

enum PKFilterType {
    case sepia(intensity: Double)
    case noir
    case gaussianBlur(radius: Double)
    case chrome
   
    // Una proprietà calcolata che restituisce il filtro Core Image configurato.
    var coreImageFilter: CIFilter {
        switch self {
        case .sepia(let intensity):
            let filter = CIFilter.sepiaTone()
            filter.intensity = Float(intensity)
            return filter
            
        case .noir:
            return CIFilter.photoEffectNoir()
            
        case .gaussianBlur(let radius):
            let filter = CIFilter.gaussianBlur()
            filter.radius = Float(radius)
            return filter
        case .chrome:
            let filter = CIFilter(name: "CIPhotoEffectChrome")!
            return filter
        
        }
   
    }
}


@MainActor
class EditorModel: NSObject,ObservableObject {
    static let shared = EditorModel()
    let defProjectName: String = "drawingProject"
    
    @Published var layers: [LayerModel] = []
   
    var shapeStampWrapper = ShapeStampWrapper()
    var textStampWrapper  = TextStampWrapper()
    
    @Published var projectId = UUID()
    @Published var projectName: String = ""
    
    @Published var showPhotoPicker = false
    @Published var showCamera = false
    @Published var showGallery = false
    @Published var showDocPicker = false
    @Published var showTextInput = false
    @Published var saveProjectAs: Bool = false
    @Published var showLayers: Bool = false
    @Published var showFontPicker:Bool = false
    @Published var showFontSheet = false
    @Published var showProjects = false
    @Published var showDeleteProject = false
    @Published var showRenameProject = false
  
    @Published var activeCanvasId: Int = 1
    //@Published var contentSize: CGSize = CGSize(width: 1024, height: 1024)
    @Published var currentFont: UIFont = UIFont.systemFont(ofSize: 64, weight: .regular){
        didSet {
            saveFontToUserDefaults()
        }
    }
    //@Published
    var selectedStroke: PKStroke? = nil {
        didSet {
            if selectedStroke == nil {
                NotificationCenter.default.post(name: Notification.UnselectStroke, object: nil, userInfo: [:])
            }else{
                NotificationCenter.default.post(name: Notification.SelectStroke, object: nil, userInfo: [:])
           }
        }
    }
   
    
    var selectedImageLayerID: Int? = nil {
       didSet {
           if selectedImageLayerID == nil {
               // To avoid conflicts, only post if a stroke isn't selected either
               if selectedStroke == nil {
                   NotificationCenter.default.post(name: Notification.UnselectStroke, object: nil)
               }
           } else {
               self.selectedStroke = nil // Deselect stroke if an image is selected
               NotificationCenter.default.post(name: Notification.SelectStroke, object: nil)
          }
       }
    }
    var originalImageTransform: CGAffineTransform?
    
    var originalBackgroundImage: UIImage?
    var originalBackgroundColor = UIColor.white
    @Published var backgroundImage: UIImage?
    @Published var backgroundColor = UIColor.white
    @Published var edgeColor = UIColor.systemGray  //UIColor.white
 
    
    
    //@Published
    var contentSize: CGSize = .zero
    var contentOffset: CGPoint = .zero
    var edgeInset: UIEdgeInsets = .zero
    var zoomScale: CGFloat = 1.0
    let minimumZoomScale = 0.1
    let maximumZoomScale = 10.0
 
    private let fontNameKey = "EditorCurrentFontName"
    private let fontSizeKey = "EditorCurrentFontSize"
  
    var recentProjects:[ProjectItem] = []
    
    var toolPicker: PKToolPicker?
    var mainMenu:UIMenu!
    var menuButton:UIButton? = nil

    var onPublish: ((_ image:UIImage) -> Void)? = nil
    var onExit: (() -> Void)? = nil
 
    var locationInDrawing : CGPoint = .zero
    var lastTranslation : CGSize = .zero
  
    var inputPosition: CGPoint {
     
        let scaledX = locationInDrawing.x * zoomScale
        let scaledY = locationInDrawing.y * zoomScale

        let finalX = scaledX - contentOffset.x
        let finalY = scaledY - contentOffset.y

        // 3. Ritorna la coordinata finale per lo schermo
        return CGPoint(x: finalX, y: finalY)
    }
    
    var originalStroke: PKStroke?
    var originalDrawing: PKDrawing?
   
    @Published var activeFilter: PKFilterType? = nil
    
    @Published var drawingMode: DrawingMode = .standard
    @Published var currentPathPoints: [CGPoint] = []
    
    @Published var isShowingNavigator: Bool = false
    //@Published
    var navigatorImage: UIImage? = nil
    //@Published
    var visibleRectInCanvas: CGRect = .zero
    @Published var isProgrammaticScroll: Bool = false
    
    var aspectRatio:Double {
        contentSize.width / contentSize.height
    }
    
    enum BackgroundStyle {
        case solid
        case grid(spacing: CGFloat)
    }
    @Published var backgroundStyle:BackgroundStyle = .grid(spacing: 20)
    
    @Published var isPanEnabled: Bool = true
    @Published var isZoomEnabled: Bool = true
    @Published var isRotationEnabled: Bool = false
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        projectName = defProjectName
        addLayer()
        activeCanvasId = 1
        recentProjects = getRecentProjects()
        loadFontFromUserDefaults()
        
        $isPanEnabled
            .merge(with: $isZoomEnabled)
            .merge(with: $isRotationEnabled)
        
            .sink { [weak self] _ in
                DispatchQueue.main.async{
                    self?.createPopupMenu()
                }
                
            }
            .store(in: &cancellables)

    }
    
    func addLayer() {
        let canvasId = layers.count + 1
        let layer = LayerCanvasModel(currentCanvasId: canvasId)
        layers.append(layer)
        activeCanvasId = canvasId
        
    }
    
    func addImageLayer(image:UIImage) {
        let canvasId = layers.count + 1
        let layer = LayerImageModel(currentCanvasId: canvasId)
        layer.image = image
        layers.append(layer)
        activeCanvasId = canvasId
    }
    
    func broadcastChanged(){
        DispatchQueue.main.async{
            NotificationCenter.default.post(name: Notification.CanvasTransformed,
                                            object: nil, userInfo: [:])
        }
    }
    
    func findLayer(by id: Int) -> LayerModel? {
        // 'layers' è l'array dove tieni tutti i tuoi LayerCanvasModel
        return self.layers.first { $0.id == id }
    }
    
    
    func findCanvasLayer(by id: Int) -> LayerCanvasModel? {
        // 'layers' è l'array dove tieni tutti i tuoi LayerCanvasModel
        return self.layers.first { $0.id == id } as? LayerCanvasModel
    }
    func activeLayer() -> LayerModel? {
        // 'layers' è l'array dove tieni tutti i tuoi LayerCanvasModel
        return self.layers.first { $0.id == activeCanvasId }
    }
    
    func zoomToFit() {
       
        let totalBounds = CGRect(x: 0,y: 0,width: contentSize.width,height: contentSize.height)
        
        
        guard let layer = layers.first(where: { $0.id == activeCanvasId }) else {
            print("Errore: Nessun layer attivo trovato per aggiungere il testo.")
            return
        }
        //if layer.type == .canvas {
            //let layerCanvasModel = layer as! LayerCanvasModel
            
            /*guard let activeCanvas = layerCanvasModel.canvas, // Usa il dizionario corretto
                  !totalBounds.isNull, totalBounds.width > 0, totalBounds.height > 0 else {
                print("Impossibile calcolare lo zoom.")
                return
            }*/
            let activeCanvas = layer.scrollView!
            // --- LOGICA DI ZOOM (invariata) ---
            let canvasFrame = activeCanvas.bounds // Usiamo .bounds per la dimensione visibile effettiva
            let widthScale = canvasFrame.width / totalBounds.width
            let heightScale = canvasFrame.height / totalBounds.height
            let fitScale = min(widthScale, heightScale) * 1 // Aggiungiamo un
            let scaledContentWidth = totalBounds.width * fitScale
            let scaledContentHeight = totalBounds.height * fitScale
            
            var offsetX = (canvasFrame.width - scaledContentWidth) / 2.0
            var offsetY = (canvasFrame.height - scaledContentHeight) / 2.0
            
            offsetX = max(0, offsetX)
            offsetY = max(0, offsetY)
            
            contentOffset = .zero
        
            for layer in layers {
                //if layer.type == .canvas {
                    //let layerCanvasModel = layer as! LayerCanvasModel
                //let canvas = layerCanvasModel.canvas!
                let canvas = layer.scrollView!
                
                canvas.minimumZoomScale = minimumZoomScale
                canvas.maximumZoomScale = maximumZoomScale
                
                canvas.setZoomScale(fitScale, animated: false) // Prima imposta lo zoom senza animazione
                canvas.setContentOffset(contentOffset, animated: false) // Poi centra con una lieve animazione
                
                if !isZoomEnabled {
                    canvas.minimumZoomScale = fitScale
                    canvas.maximumZoomScale = fitScale
                }
                //}
            }
        //}
        print("Eseguito Zoom to Fit con centratura.")
    }
    
    func zoomTo1of1() {
        zoomScale = 1
        contentOffset = .zero
        for layer in layers {
            //if layer.type == .canvas {
                //let layerCanvasModel = layer as! LayerCanvasModel
                
                let canvas = layer.scrollView! // layerCanvasModel.canvas!
                canvas.setZoomScale(zoomScale, animated: false) // Prima imposta lo zoom senza animazione
                canvas.setContentOffset(contentOffset, animated: false) // Poi centra con una lieve animazione
            }
        //}
    }
    
    @MainActor
    func updateEdgeInsets(geometrySize:CGSize, contentSize:CGSize){
        
        let horizontalPadding = (geometrySize.width - contentSize.width)/2
        let verticalPadding = (geometrySize.height - contentSize.height)/2

        // Gli insets non possono essere negativi
        let topInset = max(0, verticalPadding)
        let leftInset = max(0, horizontalPadding)

        self.edgeInset = UIEdgeInsets(top: topInset, left: leftInset, bottom: topInset, right: leftInset)
        
        layers.forEach(){layer in
            if let scrollView = layer.scrollView {
                scrollView.contentInset = edgeInset
            }
        }
    }
    
    func updateContentOffset() {
        zoomScale = 1
        
        for layer in layers {
            if layer.type == .canvas {
                let layerCanvasModel = layer as! LayerCanvasModel
                let canvas = layerCanvasModel.canvas!
                canvas.setZoomScale(zoomScale, animated: false) // Prima imposta lo zoom senza animazione
                canvas.setContentOffset(contentOffset, animated: false) // Poi centra con una lieve animazione
            }
        }
    }
    
    func saveFontToUserDefaults() {
        let fontToSave = self.currentFont
        
        // Otteniamo e salviamo le due proprietà semplici
        let fontName = fontToSave.fontName
        let fontSize = fontToSave.pointSize
        
        let defaults = UserDefaults.standard
        defaults.set(fontName, forKey: fontNameKey)
        defaults.set(fontSize, forKey: fontSizeKey)
        
        print("✅ Font salvato: \(fontName) @ \(fontSize)pt")
    }
    
    // --- NUOVA FUNZIONE PER CARICARE IL FONT ---
    
    /// Carica il nome e la dimensione del font da UserDefaults e aggiorna la proprietà 'currentFont'.
    func loadFontFromUserDefaults() {
        let defaults = UserDefaults.standard
        
        // Leggiamo il nome, usando un font di sistema come valore di default se non c'è nulla
        let savedName = defaults.string(forKey: fontNameKey) ?? UIFont.systemFont(ofSize: 48).fontName
        
        // Leggiamo la dimensione. Se la chiave non esiste, .double(forKey:) restituisce 0.
        // Quindi controlliamo prima se esiste, altrimenti usiamo un default.
        var savedSize: CGFloat
        if defaults.object(forKey: fontSizeKey) != nil {
            savedSize = defaults.double(forKey: fontSizeKey)
        } else {
            savedSize = 48.0
        }
     
        self.currentFont = UIFont(name: savedName, size: savedSize) ?? .systemFont(ofSize: savedSize)
        
    }
    
}


extension Notification {
    static let CanvasTransformed = Notification.Name.init("CanvasTransformed")
    static let SelectStroke = Notification.Name.init("SelectStroke")
    static let UnselectStroke = Notification.Name.init("UnselectStroke")
    static let UpdateNavigator = Notification.Name.init("UpdateNavigator")
    
    static let SelectImage = Notification.Name.init("SelectImage")
    static let UnselectImage = Notification.Name.init("UnselectImage")

}
