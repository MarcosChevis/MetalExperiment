//
//  Renderer.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 22/02/24.
//

import MetalKit

final class Renderer: NSObject, MTKViewDelegate {
    
    var metalDevice: MTLDevice?
    var metalCommandQueue: MTLCommandQueue?
    var pipelineState: MTLRenderPipelineState?
    
    var vertices: [Vertex] = []
    private var clearColor: MTLClearColor  = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
    
    init(metalDevice: MTLDevice?) {
        self.metalDevice = metalDevice
        super.init()
        self.metalCommandQueue = metalDevice?.makeCommandQueue()
        self.pipelineState = makePipelineState()
        vertices = []/*RegularPolygon(center: [-0.5, 0.0], radius: 0.5, amountOfSides: 1000).triangulated() + RegularPolygon(center: [0.5, 0.0], radius: 0.5, amountOfSides: 1000).triangulated()*/
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let metalDevice,
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = metalCommandQueue?.makeCommandBuffer(),
              let pipelineState else {
            preconditionFailure("Could not draw")
        }
        
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        // MARK: Isso aqui deve ajudar na otimização, não entendi 100%
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            preconditionFailure("could not get renderer encoder")
        }
        renderEncoder.setRenderPipelineState(pipelineState)
        //                                                                                      Aqui tb otimizacao
        let vertices = RegularPolygon(center: [-0.5, 0.0], radius: 0.5, amountOfSides: 100).triangulated() + RegularPolygon(center: [0.5, 0.0], radius: 0.5, amountOfSides: 100).triangulated()
        let vertexBuffer = metalDevice.makeBuffer(bytes: vertices, length: vertices.getStride(), options: [])
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    
}

// MARK: Pipeline State
extension Renderer {
    
    private func makePipelineState() -> MTLRenderPipelineState? {
        guard let library = metalDevice?.makeDefaultLibrary() else { preconditionFailure("could not get default library") }
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        guard let pipelineState = try? metalDevice?.makeRenderPipelineState(descriptor: pipelineDescriptor) else {
            preconditionFailure("could not get pipeline state")
        }
        return pipelineState
    }
}
