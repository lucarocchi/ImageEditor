//
//  HandleAnchor.swift
//  PKEditor
//
//  Created by Luca Rocchi on 25/06/25.
//



import SwiftUI
import PencilKit

/// Un punto di ancoraggio per le maniglie di controllo.
enum HandleAnchor {
    case topLeft, top, topRight
    case left, center, right
    case bottomLeft, bottom, bottomRight
}



struct EditingHandlesView: View {
    @State var frame: CGRect
    //@State var offset: CGSize
    @State var bounds: CGRect
    
    
    @ObservedObject var model = EditorModel.shared
    @GestureState private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    private let handleSize: CGFloat = 16
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    @State  private var editId = UUID()
    init(){
        frame = .zero
        //offset = .zero
        bounds = .zero
    }
    
    func strokeBoundsToFrame() -> CGRect{
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: model.zoomScale, y: model.zoomScale)
        let frame0 = bounds.applying(transform)
        let frame = frame0.offsetBy(dx: -model.contentOffset.x, dy: -model.contentOffset.y)
        return frame
    }
    
    
    func updateHandle(anchor: HandleAnchor, translation: CGSize) -> CGRect {
        var newFrame = self.frame
        let dx = translation.width  - model.lastTranslation.width
        let dy = translation.height - model.lastTranslation.height
        
        switch anchor {
        case .bottomRight:
            newFrame.size.width += dx //translation.width
            newFrame.size.height += dy //translation.height
        case .right:
            newFrame.size.width += dx
        case .bottom:
            newFrame.size.height += dy
        case .center:
            newFrame.origin.x += translation.width
            newFrame.origin.y += translation.height
        case .bottomLeft:
            newFrame.origin.x += translation.width
            newFrame.size.width -= translation.width
            newFrame.size.height += dy //translation.height
        case .topRight:
            newFrame.size.width += dx
            newFrame.size.height -= translation.height
            newFrame.origin.y += translation.height
            
        case .topLeft:
            newFrame.origin.x += translation.width
            newFrame.origin.y += translation.height
            newFrame.size.width -= translation.width
            newFrame.size.height -= translation.height
        case .top:
            newFrame.origin.y += translation.height
            newFrame.size.height -= translation.height
        case .left:
            newFrame.origin.x += translation.width
            newFrame.size.width -= translation.width
        }
        
        return newFrame
        
    }
    
    func frameToBounds(frame: CGRect) -> CGRect {
        
        let frameWithoutOffset = frame.offsetBy(dx: model.contentOffset.x, dy: model.contentOffset.y)
        
        guard model.zoomScale != 0 else {
            print("Errore: Impossibile invertire la trasformazione con uno zoomScale di 0.")
            return .zero
        }
        
        let inverseZoom = 1.0 / model.zoomScale
        var inverseTransform = CGAffineTransform.identity
        inverseTransform = inverseTransform.scaledBy(x: inverseZoom, y: inverseZoom)
        
        let originalBounds = frameWithoutOffset.applying(inverseTransform)
        return originalBounds
    }
    
    func applyTransform(){
        
        if let selectedStroke = EditorModel.shared.selectedStroke {
            bounds = selectedStroke.renderBounds
            frame = strokeBoundsToFrame()
        }
        
        if let selectedImageLayerID = EditorModel.shared.selectedImageLayerID,
           let layer = model.findLayer(by: selectedImageLayerID) as? LayerImageModel {
            if let scrollView = layer.scrollView as? CustomUIScrollView {
                bounds = scrollView.imageView.frame
                frame = strokeBoundsToFrame()
            }
        }
    }
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            ZStack {
                // Contorno blu
                Rectangle().stroke(Color.blue, lineWidth: 1.5)
                handleView(for: .topLeft)
                handleView(for: .top)
                handleView(for: .topRight)
                handleView(for: .left)
                handleView(for: .bottomLeft)
                handleView(for: .right)
                handleView(for: .bottom)
                handleView(for: .bottomRight)
                handleView(for: .center)
            }
            Menu {
                // Aggiungi qui le opzioni del tuo menu
                
                if let _ = EditorModel.shared.selectedStroke{
                    
                    Menu{
                        Button() {
                            model.rotate( byDegrees: -15)
                        } label:{
                            Label("left", systemImage: "rotate.left")
                        }
                        Button() {
                            model.rotate( byDegrees: 15)
                        } label:{
                            Label("right", systemImage: "rotate.right")
                        }
                        
                    }label: {
                        Text("Rotate")
                    }
                    
                    
                    
                    
                    Menu{
                        Button(action: {
                            model.flipHorizontal()
                        }) {
                            Label("horizontally", systemImage: "rectangle.bottomhalf.filled")
                        }
                        
                        
                        Button(action: {
                            model.flipVertical()
                        }) {
                            Label("vertically", systemImage: "rectangle.trailinghalf.filled")
                        }
                        
                    }label: {
                        // Questa è l'icona che funge da bottone
                        Text("Flip")
                    }
                    
                    Button(action: {
                        model.duplicateToNewLayer()
                    }) {
                        Label("Duplicate to new layer", systemImage: "square.2.layers.3d.fill")
                    }
                    
                    Button(action: {
                        model.bringStrokeToFront()
                    }) {
                        Label("Bring to front", systemImage: "square.2.layers.3d.top.filled")
                    }
                    
                    Button(action: {
                        model.sendStrokeToBack()
                    }) {
                        Label("Send to back", systemImage: "square.2.layers.3d.bottom.filled")
                    }
                    
                    Button(role: .destructive, action: {
                        print("Azione: Elimina")
                        model.deleteStroke()
                        // Aggiungi qui la logica per eliminare lo stroke
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
                if let selectedImageLayerID = EditorModel.shared.selectedImageLayerID
                    ,let layer = model.findLayer(by: selectedImageLayerID) as? LayerImageModel,let view = layer.scrollView as? CustomUIScrollView {
                    Menu() {
                        Button() {
                            layer.applyFilter(filter: .sepia(intensity: 4))
                            
                        } label:{
                            Text("Sepia")
                        }
                        
                        Button() {
                            layer.applyFilter(filter: .noir)
                        } label:{
                            Text("Noir")
                        }
                        Button() {
                            layer.applyFilter(filter: .chrome)
                        } label:{
                            Text("Chrome")
                        }
                        Button() {
                            layer.applyFilter(filter: .gaussianBlur(radius: 5))
                        } label:{
                            Text("Gaussian Blur")
                        }
                        
                        Button() {
                            layer.removeFilter()
                        } label:{
                            Text("Original")
                        }
                        
                    } label: {
                        Label("Image filters", systemImage: "camera.filters")
                    }
                    Menu() {
                        Button() {
                            layer.contentMode = .scaleAspectFit
                            view.imageView.contentMode = layer.contentMode
                        } label:{
                            Text("Aspect fit")
                        }
                        
                        Button() {
                            layer.contentMode = .scaleAspectFill
                            view.imageView.contentMode = layer.contentMode
                         } label:{
                            Text("Aspect fill")
                        }
                       
                        
                    } label: {
                        Label("Scale mode", systemImage: "photo.artframe")
                    }
                }
                
            } label: {
                // Questa è l'icona che funge da bottone
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .background(Circle().fill(.white)) // Sfondo bianco per visibilità
                    .shadow(radius: 2)
            }
            .offset(x: 0, y: 50)
            
        }
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
        //.offset(x: offset.width, y: offset.height)
        .onReceive(NotificationCenter.default.publisher(for: Notification.CanvasTransformed))
        { obj in
            print("EditingHandlesView CanvasTransformed")
            self.applyTransform()
        }.onAppear(){
            print("EditingHandlesView onAppear")
            applyTransform()
            
        }.id(editId)
            .zIndex(1000)
    }
    
    
    @ViewBuilder
    private func handleView(for anchor: HandleAnchor) -> some View {
        
        Circle()
            .fill(Color.blue)
            .frame(width: handleSize, height: handleSize)
            .padding(10)
            .contentShape(Circle())
            .overlay(Circle().stroke(Color.clear, lineWidth: 1.0))
            .position(position(for: anchor))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragOffset) { value, state, _ in
                        print("DragGesture y \(value.translation.height)")
                        
                        let frame = updateHandle(anchor:anchor ,translation: value.translation)
                        self.frame = frame
                        model.lastTranslation = value.translation
                        
                        let newBounds = frameToBounds(frame: self.frame)
                        model.onDragUpdate(newBounds: newBounds, anchor: anchor)
                    }
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            model.onDragChanged()
                            hapticGenerator.impactOccurred()
                        }
                    }
                    .onEnded { value in
                        print("DragGesture onEnded")
                        isDragging = false
                        model.onDragEnd()
                        bounds = model.getSelectedBounds()
                        model.lastTranslation = .zero
                    }
            )
    }
    
    private func position(for anchor: HandleAnchor) -> CGPoint {
        switch anchor {
        case .topLeft:      return CGPoint(x: 0, y: 0)
        case .top:          return CGPoint(x: frame.width / 2, y: 0)
        case .topRight:     return CGPoint(x: frame.width, y: 0)
        case .left:         return CGPoint(x: 0, y: frame.height / 2)
        case .center:       return CGPoint(x: frame.width / 2, y: frame.height / 2)
        case .right:        return CGPoint(x: frame.width, y: frame.height / 2)
        case .bottomLeft:   return CGPoint(x: 0, y: frame.height)
        case .bottom:       return CGPoint(x: frame.width / 2, y: frame.height)
        case .bottomRight:  return CGPoint(x: frame.width, y: frame.height)
        }
    }
}
