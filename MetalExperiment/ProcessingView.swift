//
//  ProcessingView.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 06/03/24.
//

import SwiftUI
import MetalKit

extension ProcessingView {
    func setup() {
        setClearColor(color: .gray)
    }

    func update(_ frame: Double) {
        square(center: .init(x: cos(frame / 1000) / 2, y: sin(frame / 1000) / 2), sideSize: 0.5, color: .green, rotation: Float(frame / 100))
        square(center: .init(x: sin(frame / 1000) / 2, y: cos(frame / 1000) / 2), sideSize: 0.5, color: .blue, rotation: Float(-frame / 100))
    }
}

struct ProcessingView: View {
    @Environment(\.self) var environment
    
    @State var drawer: Drawer = Drawer()
    
    var body: some View {
        MetalViewRepresentable(drawer: $drawer)
//            .frame(width: 500, height: 500)
            .onAppear {
                setup()
                drawer.update = self.update
            }
    }
    
    func square(center: CGPoint, sideSize: Float, color: Color, rotation: Float) {
        drawer.addPolygon(poly: RegularPolygon(center: center.simdFloat2, radius: sqrt(sideSize)/2, amountOfSides: 4, color: color.toSimdFloat4(environment), rotationAngle: rotation, bufferStart: 0))
    }
    
    func setClearColor(color: Color) {
        let resolved = color.resolve(in: self.environment)
        drawer.setClearColor(color: (red: Double(resolved.red), green: Double(resolved.green), blue: Double(resolved.blue), opacity: Double(resolved.opacity)))
    }
}

//#Preview {
//    ProcessingView()
//}
