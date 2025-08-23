import SwiftUI

struct LayerImageView: UIViewRepresentable {
    @ObservedObject var editor = EditorModel.shared
    var model: LayerImageModel
    let index: Int
    @Binding var activeCanvasId: Int

    init(index:Int, model:LayerModel, activeCanvasId: Binding<Int>) {
        self.index = index
        self.model = model as! LayerImageModel
        self.model.index = index
        _activeCanvasId = activeCanvasId
    }

    func makeUIView(context: Context) -> CustomUIScrollView {
        let scrollView = CustomUIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.backgroundColor = .clear
        
       
        scrollView.contentSize = editor.contentSize
        scrollView.minimumZoomScale = editor.minimumZoomScale
        scrollView.maximumZoomScale = editor.maximumZoomScale
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        
        scrollView.zoomScale = editor.zoomScale
        scrollView.contentOffset = editor.contentOffset
        // --- IL CUORE DELLA SOLUZIONE ---
        
        // 1. Impostiamo l'immagine sulla nostra imageView
        scrollView.imageView.contentMode = model.contentMode
        // 2. L'immagine è centrata all'interno del container
        scrollView.imageView.image = model.image
       
        if let imageFrame = model.imageFrame {
            scrollView.imageView.frame = imageFrame
        }else{
            let imageSize = CGSize(width: 200, height: 200)
            let centerFrame = CGRect(
                x: (editor.contentSize.width - imageSize.width) / 2,
                y: (editor.contentSize.height - imageSize.height) / 2,
                width: imageSize.width,
                height: imageSize.height
            )
            scrollView.imageView.frame = centerFrame
        }
   
        model.scrollView = scrollView
        
        // Impostiamo i gesti (come la rotazione)
        context.coordinator.setUpGestureRecognizers(on: scrollView)
        
        return scrollView
    }
    
    func updateUIView(_ uiView: CustomUIScrollView, context: Context) {
        // La logica di sincronizzazione per i layer non attivi
        let shouldBeActive = (model.currentCanvasId == activeCanvasId)
        if !shouldBeActive {
            if uiView.zoomScale != editor.zoomScale {
                uiView.zoomScale = editor.zoomScale
            }
            if uiView.contentOffset != editor.contentOffset {
                uiView.setContentOffset(editor.contentOffset, animated: false)
            }
        }
        
        // Sincronizziamo sempre contentSize e edgeInset
        if uiView.contentSize != editor.contentSize {
            uiView.contentSize = editor.contentSize
        }
        if uiView.contentInset != editor.edgeInset {
            uiView.contentInset = editor.edgeInset
        }
        
        // Applichiamo gli stati di abilitazione dei gesti
        uiView.isScrollEnabled = editor.isPanEnabled
        context.coordinator.rotationGestureRecognizer?.isEnabled = editor.isRotationEnabled
        
        if editor.isZoomEnabled {
           uiView.minimumZoomScale = editor.minimumZoomScale
           uiView.maximumZoomScale = editor.maximumZoomScale
        } else {
           uiView.minimumZoomScale = uiView.zoomScale
           uiView.maximumZoomScale = uiView.zoomScale
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
        
    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var parent: LayerImageView
        var rotationGestureRecognizer: UIRotationGestureRecognizer?

        init(_ parent: LayerImageView) {
            self.parent = parent
        }
        
        // --- PASSAGGIO FONDAMENTALE PER LO ZOOM ---
        // Questo metodo dice alla scroll view quale delle sue subview deve essere scalata.
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            // Dobbiamo restituire la nostra UIImageView
            return (scrollView as? CustomUIScrollView)?.containerView
        }
        
        // --- LOGICA DI SINCRONIZZAZIONE (identica a quella della PKCanvasView) ---
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let isActive = parent.model.id == parent.activeCanvasId
            if isActive {
                EditorModel.shared.contentOffset = scrollView.contentOffset
                EditorModel.shared.propagateScrollOffset(scrollView.contentOffset, from: parent.model.id)
            }
        }
            
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
                    
            let isActive = parent.model.id == parent.activeCanvasId
            if isActive {
                EditorModel.shared.zoomScale = scrollView.zoomScale
                EditorModel.shared.propagateZoomScale(scrollView.zoomScale, from: parent.model.id)
                EditorModel.shared.broadcastChanged()
            }
            
        }
        
        func setUpGestureRecognizers(on view: UIView) {
            //let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
            //rotationGesture.delegate = self
            //view.addGestureRecognizer(rotationGesture)
            //self.rotationGestureRecognizer = rotationGesture
            
            let tapGesture = CanvasGestureRecognizer(target: self, action: #selector(handleTap(_:)))
              view.addGestureRecognizer(tapGesture)
    
        }

        @MainActor
        @objc func handleTap(_ sender: CanvasGestureRecognizer) {
            guard let scrollView = sender.view as? CustomUIScrollView else { return }
            let model = EditorModel.shared
            
            let location = sender.location(in: scrollView.imageView)
            let isActive = parent.model.id == parent.activeCanvasId
            if !isActive { return }
            if scrollView.imageView.bounds.contains(location) {
                // The user tapped inside the image
                print("✅ Image Layer Tapped: \(parent.model.id)")
                model.selectedImageLayerID = parent.model.id
                model.selectedStroke = nil // Deselect any stroke
            } else {
                // The user tapped outside the image on this layer
                if model.selectedImageLayerID == parent.model.id {
                    model.selectedImageLayerID = nil
                }
            }
        }

        
        @objc func handleRotation(_ sender: UIRotationGestureRecognizer) {
            // ... implementa la logica di rotazione qui, se necessaria per il layer immagine ...
        }

        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith og: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
