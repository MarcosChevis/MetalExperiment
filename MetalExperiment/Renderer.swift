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
    var library: MTLLibrary?
    
    var vertices: [Vertex] = []
    private var clearColor: MTLClearColor  = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
    
    init(metalDevice: MTLDevice?) {
        self.metalDevice = metalDevice
        super.init()
        self.metalCommandQueue = metalDevice?.makeCommandQueue()
        self.pipelineState = makePipelineState()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    var polygons: [RegularPolygon] =  {
        var pols = [RegularPolygon]()
        var currentStart: Int64 = 0
        for i in -0...1 {
            pols.append(.init(center: [0, 0], radius: 1, amountOfSides: 4, color: [1, 0, 0, 1], bufferStart: currentStart))
            print(currentStart)
            currentStart = pols.last!.bufferStart + Int64(pols.last!.amountOfSides)*3
        }
        return pols
    }()
    
    func draw(in view: MTKView) {

        let commandBuffer = metalCommandQueue!.makeCommandBuffer()
        

        

//        vertices = polygons.reduce([], { partialResult, pol in
//            partialResult + pol.triangulated()
//        })
        let triangulatePolygonsGPUFunc = library?.makeFunction(name: "triangulateregularPoly")
        let triangulateState: MTLComputePipelineState = try! metalDevice!.makeComputePipelineState(function: triangulatePolygonsGPUFunc!)
        
        let arrBuffer = metalDevice!.makeBuffer(bytes: polygons, length: polygons.getStride(), options: .storageModeShared)
        let resultLenBuff = (polygons.reduce(0, { partialResult, pol in
            partialResult + Int(pol.amountOfSides)
        }) * MemoryLayout<Vertex>.stride) * 3
        let resultArrBuffer = metalDevice!.makeBuffer(length: resultLenBuff, options: .storageModeShared)
        let commandBufferCalc = metalCommandQueue?.makeCommandBuffer()
        let commandEncoder = commandBufferCalc?.makeComputeCommandEncoder()
        commandEncoder?.setComputePipelineState(triangulateState)
        commandEncoder?.setBuffer(arrBuffer, offset: 0, index: 0)
        commandEncoder?.setBuffer(resultArrBuffer, offset: 0, index: 1)
        let threadsPerGrid = MTLSize(width: polygons.count, height: 1, depth: 1)
        let maxThredsPerThreadGroup = triangulateState.maxTotalThreadsPerThreadgroup
        let threadsPerGroup = MTLSize(width: maxThredsPerThreadGroup, height: 1, depth: 1)
        commandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        commandEncoder?.endEncoding()
        commandBuffer!.commit()
        commandBuffer!.waitUntilCompleted()
        var resultBuffPointer = (resultArrBuffer?.contents().bindMemory(to: Vertex.self, capacity: resultLenBuff))!
        
        
        guard let metalDevice,
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = metalCommandQueue?.makeCommandBuffer(),
              let pipelineState else {
            preconditionFailure("Could not draw")
        }
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            preconditionFailure("could not get renderer encoder")
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        // MARK: Isso aqui deve ajudar na otimização, não entendi 100%
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        
        let vertexBuffer = metalDevice.makeBuffer(bytes: resultBuffPointer, length: resultLenBuff, options: [])
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: resultLenBuff/MemoryLayout<Vertex>.stride)
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
//        var i = 0
//        while i < polygons.count {
//            polygons[i].center[1] = polygons[i].center[1] - 0.001
//            if polygons[i].center[1] < -1 - polygons[i].radius { polygons[i].center[1] = 1 + polygons[i].radius }
//            i += 1
//        }
       
    }
    
    
}

// MARK: Pipeline State
extension Renderer {
    
    private func makePipelineState() -> MTLRenderPipelineState? {
        guard let library = metalDevice?.makeDefaultLibrary() else { preconditionFailure("could not get default library") }
        self.library = library
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
