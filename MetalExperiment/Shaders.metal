//
//  Shaders.metal
//  MetalExperiment
//
//  Created by Marcos Chevis on 16/02/24.
//

#include <metal_stdlib>
#include <metal_math>
using namespace metal;

#include "definitions.h"

struct Fragment {
    simd_float4 position [[position]];
    simd_float4 color;
};

vertex Fragment vertexShader(const device Vertex *vertexArray [[buffer(0)]],
                             unsigned int vid [[vertex_id]]) {
    Vertex input = vertexArray[vid];
    
    Fragment output;
    //x,y,z,w
    output.position = float4(input.position.x, input.position.y, 0, 1);
    output.color = input.color;
    
    return output;
}

fragment float4 fragmentShader(Fragment input [[stage_in]]) {
    return input.color;
}


kernel void triangulateRegularPoly(constant RegularPolygon *polygonsArr [[buffer(0)]],
                                   device uint32_t *indicesArray [[buffer(1)]],
                                   device Vertex *vertices [[buffer(2)]],
                                   uint currentPolyIndex [[thread_position_in_grid]]) {
    
    float deltaAngle = 2.0 * M_PI_F / polygonsArr[currentPolyIndex].amountOfSides;
    float currentAngle = polygonsArr[currentPolyIndex].rotationAngle;
    
    simd_float2 center = polygonsArr[currentPolyIndex].center;
    float radius = polygonsArr[currentPolyIndex].radius;
    simd_float4 color = polygonsArr[currentPolyIndex].color;
    
    int bufferStart = polygonsArr[currentPolyIndex].bufferStart;
    
    //center vertex
    Vertex c;
    c.position = center;
    c.color = color;
    
    vertices[bufferStart] = c;
    
    for (int i = 0; i < polygonsArr[currentPolyIndex].amountOfSides; ++i) {
        simd_float2 currentPoint = vector_float2(radius * cos(currentAngle), radius * sin(currentAngle)) + center;
        
        //current vertex
        Vertex v1;
        v1.position = currentPoint;
        v1.color = color;
        vertices[bufferStart + 1 + i] = v1;
        
        // creating triangle from indices
        int indicesStart = ((bufferStart + i - currentPolyIndex) * 3) ;
        //calculated vertex index
        indicesArray[indicesStart] = bufferStart + i + 1;
        //center vertex index
        indicesArray[indicesStart + 1] = bufferStart;
        
        // vertex to be calculated next or first calculated
        int32_t lastVertexIndex;
        
        // if there is no more to be calculated, connect to the first that is not the center.
        if (i == polygonsArr[currentPolyIndex].amountOfSides - 1) {
            lastVertexIndex = bufferStart + 1;
        } else {
        // if there is at least one more, get the index for the next vertex.
        //                  | initial index for this poly: center   | + 1 + i for current vertex index, + 1 for next vertex index.
            lastVertexIndex =               bufferStart             +    2 + i;
        }
        //last vertex of triangle for i side
        indicesArray[indicesStart + 2] = lastVertexIndex;
        
        //update angle
        currentAngle += deltaAngle;
    }
}
