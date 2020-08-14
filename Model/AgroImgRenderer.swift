//
//  AgroImgRenderer.swift
//  AgroDonkey
//
//  Created by Ringo Wathelet on 2020/08/05.
//

import Foundation
import MapKit

class AgroImgRenderer: MKOverlayRenderer {
    
    var image: UIImage?
    
    init(satImg: SatImage) {
        if let satim = satImg.image {
            self.image = satim
        } else {
            self.image = nil
        }
        super.init(overlay: satImg)
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        if image != nil {
            guard let imageReference = image!.cgImage else { return }
            
            let rect = self.rect(for: overlay.boundingMapRect)
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0.0, y: -rect.size.height)
            context.draw(imageReference, in: rect)
        }
    }
    
}
