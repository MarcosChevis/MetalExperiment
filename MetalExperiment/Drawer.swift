//
//  Drawer.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 09/03/24.
//

import Foundation
import MetalKit

final class Drawer {
    var renderer: Renderer?
    var update: ((Double) -> Void)? {
        didSet {
            renderer?.update = update
        }
    }
    var frame = Int.zero
    
    func addPolygon(poly: RegularPolygon) {
        renderer?.polygons.append(poly)
    }
    
    func setClearColor(color: (red: Double, green: Double, blue: Double, opacity: Double)) {
        renderer?.clearColor = MTLClearColorMake(color.red, color.green, color.blue, color.opacity)
    }
}
