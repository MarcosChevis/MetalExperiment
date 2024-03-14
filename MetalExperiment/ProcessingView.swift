//
//  ProcessingView.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 06/03/24.
//

import SwiftUI
import MetalKit

struct ProcessingView: View {
    
    @State private var drawer: Drawer = Drawer()
    @State private var renderer: Renderer = Renderer()
    var setup: (Drawer) -> Void
    var update: (Drawer, Double) -> Void
    

    
    var body: some View {
        MetalViewRepresentable(renderer: renderer)
            .onAppear {
                renderer.update = { frame in
                    update(drawer, frame)
                    return drawer.popPolygons()
                }
                setup(drawer)
            }
    }
}

//#Preview {
//    ProcessingView()
//}
