//
//  LayerModel.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//

import Foundation
import UIKit
//@MainActor


class LayerImageModel:LayerModel, Codable {
    var originalImage:UIImage?
    var image:UIImage?
    var imageFrame:CGRect?
    var contentMode : UIView.ContentMode = .scaleAspectFit
    
    //@Published
    var activeFilter: PKFilterType? = nil
    
    enum CodingKeys: String, CodingKey {
        case currentCanvasId
        case drawing
        case opacity
        case visible
        case name
        case image
        case frame
        
    }
    
    init(currentCanvasId:Int){
        super.init(currentCanvasId:currentCanvasId, type: .image)
        
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(Int.self, forKey: .currentCanvasId)
        super.init(currentCanvasId: id, type: .image)
        
        self.opacity = try container.decode(Double.self, forKey: .opacity)
        self.visible = try container.decode(Bool.self, forKey: .visible)
        
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Layer \(id)"
        self.imageFrame = try container.decodeIfPresent(CGRect.self, forKey: .frame) ?? nil
        
        print("imageFrame init \(imageFrame)")

        if let imageData = try container.decodeIfPresent(Data.self, forKey: .image) {
            self.image = UIImage(data: imageData)
        } else {
            self.image = UIImage() // Default per i file vecchi
        }
        
    }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentCanvasId, forKey: .currentCanvasId)
        try container.encode(opacity, forKey: .opacity)
        try container.encode(visible, forKey: .visible)
        try container.encode(name, forKey: .name)
        if let imageData = self.image?.pngData() {
            try container.encode(imageData, forKey: .image)
        }
        try container.encode(imageFrame, forKey: .frame)
        print("imageFrame encode \(imageFrame)")

    }
    
}


extension LayerImageModel {
    func removeFilter() {
        if self.originalImage != nil {
            self.image = self.originalImage
            self.originalImage = nil
            self.activeFilter = nil
            if let cs = (scrollView as? CustomUIScrollView) {
                cs.imageView.image = self.image
            }
        }
    }
    
    func applyFilter(filter:PKFilterType) {
        // 1. Make sure there is a background image to filter.
        guard let _ = self.image else {
            print("No image to apply a filter to.")
            return
        }
        
        self.activeFilter = filter
        
        // 2. Make sure there is a filter selected.
        guard let filter = self.activeFilter else {
            print("No active filter selected.")
            // Optionally, you could revert to the original image if the filter is nil
            return
        }
        
       
        if let image = image , let filteredImage = applyFilter(to: image, filterType: filter) {
            if self.originalImage == nil {
                self.originalImage = self.image
            }
        
            self.image = filteredImage
            
            if let cs = (scrollView as? CustomUIScrollView) {
                cs.imageView.image = self.image
            }
            
            
            print("✅ Filter successfully applied to the image.")
            
        } else {
            print("❌ Failed to apply the filter to the image.")
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
