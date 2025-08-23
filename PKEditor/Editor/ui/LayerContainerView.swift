//
//  LayerContainerView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//


import SwiftUI
import PencilKit

struct LayerContainerView: View {
    let index:Int
    @ObservedObject var layer: LayerModel // Osserva direttamente il layer
    @Binding var activeCanvas: Int
    //@Binding var toolPickerState: ToolPickerState
    @Binding var sharedOffset: CGPoint
    var body: some View {
        Group {
            if layer.type == .image {
                LayerImageView(
                    index:index,
                    model: layer,
                    activeCanvasId: $activeCanvas//,sharedOffset : $sharedOffset
                )
            }else{
                LayerCanvasView(
                    index:index,
                    model: layer,
                    activeCanvasId: $activeCanvas,
                    sharedOffset : $sharedOffset
                    
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(layer.visible ? layer.opacity : 0.0) 
        
    }
}
