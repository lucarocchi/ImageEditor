//
//  MenuImageFilter.swift
//  PKEditor
//
//  Created by Luca Rocchi on 14/08/25.
//

import SwiftUI

struct MenuImageFilter: View {
    @ObservedObject var model = EditorModel.shared
 
    var body: some View {
        Menu() {
            Button() {
                model.applyFilterToBackgroundImage(filter: .sepia(intensity: 4))
                
            } label:{
                Text("Sepia")
            }
            
            Button() {
                model.applyFilterToBackgroundImage(filter: .noir)
            } label:{
                Text("Noir")
            }
            Button() {
                model.applyFilterToBackgroundImage(filter: .chrome)
            } label:{
                Text("Chrome")
            }
            Button() {
                model.applyFilterToBackgroundImage(filter: .gaussianBlur(radius: 5))
            } label:{
                Text("Gaussian Blur")
            }
            
            Button() {
                model.removeFilterToBackgroundImage()
            } label:{
                Text("Original")
            }
            
        } label: {
            Image(systemName: "camera.filters")
        }
        
    }
}

#Preview {
    MenuImageFilter()
}
