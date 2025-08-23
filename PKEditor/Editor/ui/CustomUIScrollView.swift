//
//  CustomPKCanvasView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 01/07/25.
//


import PencilKit

class CustomUIScrollView: UIScrollView {
    var imageView : UIImageView = UIImageView()
    let containerView = UIView()
      
    var onLayout: (() -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        //setupBackground()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //setupBackground()
        self.addSubview(containerView)
                // E poi l'immagine al container
        containerView.addSubview(imageView)
        containerView.clipsToBounds = true
        imageView.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    
    override var contentSize: CGSize {
        didSet {
            // Quando il contentSize cambia, aggiorna il background
            updateBackSize()
        }
    }
    
    private func updateBackSize() {
        let rect = CGRect(origin: .zero, size: contentSize)
       
        containerView.frame = rect
       
       
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBackSize()
        
        onLayout?()
    }
    
}

