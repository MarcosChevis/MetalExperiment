//
//  ContentView.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 16/02/24.
//

import SwiftUI
import MetalKit

#if os(macOS)
typealias ViewRepresentable = NSViewRepresentable
typealias ViewRepresentableContext = NSViewRepresentableContext
typealias ViewType = NSView
#elseif os(iOS)
typealias ViewRepresentable = UIViewRepresentable
typealias ViewRepresentableContext = UIViewRepresentableContext
typealias ViewType = UIView
#endif

struct MetalViewRepresentable: ViewRepresentable {
    var renderer: Renderer
    
    func makeView(context: ViewRepresentableContext<MetalViewRepresentable>) -> MTKView {
        context.coordinator.metalView
    }
    
    func updateView(_ view: MTKView, context: ViewRepresentableContext<MetalViewRepresentable>) {}
    
    func makeCoordinator() -> MetalViewCoordinator {
        MetalViewCoordinator(renderer: renderer)
    }
}

extension MetalViewRepresentable {
#if os(macOS)
    func makeNSView(context: Context) -> MTKView {
        makeView(context: context)
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        updateView(nsView, context: context)
    }
    
#elseif os(iOS)
    
    func makeUIView(context: ViewRepresentableContext<MetalViewRepresentable>) -> MTKView {
        makeView(context: context)
    }
    
    func updateUIView(_ uiView: MTKView, context: ViewRepresentableContext<MetalViewRepresentable>) {
        updateView(uiView, context: context)
    }
#endif
}



#Preview {
    MetalViewRepresentable(renderer: Renderer())
}
