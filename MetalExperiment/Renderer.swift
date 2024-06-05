//
//  Renderer.swift
//  MetalExperiment
//
//  Created by Marcos Chevis on 22/02/24.
//
import MetalKit

final class Renderer: NSObject, MTKViewDelegate {
    
    private let resourceMenager = MetalResourceManager.shared
    
    private let polygonRenderPipelineState: MTLRenderPipelineState
    private let polygonTriangulationComputePipelineState: MTLComputePipelineState
    
    var clearColor: MTLClearColor  = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
    
    var update: ((Double) -> [RegularPolygon])?
    var frame = Double.zero
    
    override init() {
        self.polygonRenderPipelineState = resourceMenager.makePolygonRenderPipelineState()
        self.polygonTriangulationComputePipelineState = resourceMenager.makePolygonTriangulationComputePipelineState()
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        let polygons = update?(frame) ?? []
        if !polygons.isEmpty { drawPolygons(in: view, polygons: polygons) }
        frame += 1
    }
    
    
    private func drawPolygons(in view: MTKView, polygons: [RegularPolygon]) {
        var polygons = polygons
        
        var vertexCount = Int32.zero
        var indexCount = Int32.zero
        for i in 0..<polygons.count {
            polygons[i].bufferStart = vertexCount
            vertexCount += polygons[i].amountOfSides + 1
            indexCount += polygons[i].amountOfSides * 3
        }
        
        guard let polygonsBuffer = createPolygonsBuffer(polygons: polygons),
              let verticesArrayBuffer = createVerticesArrayBuffer(vertexCount: vertexCount),
              let indicesArrayBuffer = createIndexBuffer(indexCount: indexCount),
              let commandBuffer = resourceMenager.commandQueue.makeCommandBuffer()
        
        else {
            preconditionFailure("Buffer could not be created")
        }
        triangulatePolygons(
            polygons: polygons,
            polygonsBuffer: polygonsBuffer,
            indicesArrayBuffer: indicesArrayBuffer,
            verticesArrayBuffer: verticesArrayBuffer,
            commandBuffer: commandBuffer
        )
        
        renderPolygons(
            verticesArrayBuffer: verticesArrayBuffer,
            indicesArrayBuffer: indicesArrayBuffer,
            indexCount: indexCount,
            renderPassDescriptor: view.currentRenderPassDescriptor,
            commandBuffer: commandBuffer
        )
        guard let drawable = view.currentDrawable else { preconditionFailure() }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        polygons = []
    }

    private func triangulatePolygons(
        polygons: [RegularPolygon],
        polygonsBuffer: MTLBuffer,
        indicesArrayBuffer: MTLBuffer,
        verticesArrayBuffer: MTLBuffer,
        commandBuffer: MTLCommandBuffer
    ) {
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            preconditionFailure("Failed to create command buffer or command encoder")
        }
        commandEncoder.setComputePipelineState(polygonTriangulationComputePipelineState)
        commandEncoder.setBuffer(polygonsBuffer, offset: 0, index: 0)
        commandEncoder.setBuffer(indicesArrayBuffer, offset: 0, index: 1)
        commandEncoder.setBuffer(verticesArrayBuffer, offset: 0, index: 2)
        
        let threadsPerGrid = MTLSize(width: polygons.count, height: 1, depth: 1)
        let maxThreadsPerThreadgroup = polygonTriangulationComputePipelineState.maxTotalThreadsPerThreadgroup
        let threadsPerThreadgroup = MTLSize(width: maxThreadsPerThreadgroup, height: 1, depth: 1)
        commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()
    }
    
    private func renderPolygons(
        verticesArrayBuffer: MTLBuffer,
        indicesArrayBuffer: MTLBuffer,
        indexCount: Int32,
        renderPassDescriptor: MTLRenderPassDescriptor?,
        commandBuffer: MTLCommandBuffer
    ) {
        guard let renderPassDescriptor else {
            preconditionFailure("Failed to create render command encoder")
        }
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            preconditionFailure("Failed to create render command encoder")
        }
        
        renderEncoder.setRenderPipelineState(polygonRenderPipelineState)
        
        renderEncoder.setVertexBuffer(verticesArrayBuffer, offset: 0, index: 0)
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: Int(indexCount), indexType: .uint32, indexBuffer: indicesArrayBuffer, indexBufferOffset: 0)
        renderEncoder.endEncoding()
    }
}

// MARK: Create Buffers
extension Renderer {
    private func createPolygonsBuffer(polygons: [RegularPolygon]) -> MTLBuffer? {
        return resourceMenager.device.makeBuffer(bytes: polygons, length: MemoryLayout<RegularPolygon>.stride * polygons.count)
    }
    private func createIndexBuffer(indexCount: Int32) -> MTLBuffer? {
        return resourceMenager.device.makeBuffer(length: MemoryLayout<UInt32>.stride * Int(indexCount))
    }
    
    private func createVerticesArrayBuffer(vertexCount: Int32) -> MTLBuffer? {
        let verticesArrayLength =  Int(vertexCount) * MemoryLayout<Vertex>.stride
        return resourceMenager.device.makeBuffer(length: verticesArrayLength)
    }
}
