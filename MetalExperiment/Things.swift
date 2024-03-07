//
//  Things.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 06/03/24.
//

import MetalKit

final class Things {
    
    static let shared = Things()
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let library: MTLLibrary
    
    private init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary() else {
            preconditionFailure("Metal objects not properly initialized")
        }
        self.device = device
        self.commandQueue = commandQueue
        self.library = library
    }
    
    func makePolygonRenderPipelineState() -> MTLRenderPipelineState {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        guard let pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor) else {
            preconditionFailure("could not get pipeline state")
        }
        return pipelineState
    }
    
    func makePolygonTriangulationComputePipelineState() -> MTLComputePipelineState {
        let triangulatePolygonsGPUFunc = library.makeFunction(name: "triangulateRegularPoly")
        guard let pipelineState = try? device.makeComputePipelineState(function: triangulatePolygonsGPUFunc!) else {
            preconditionFailure("could not get pipeline state")
        }
        return pipelineState
    }
}
