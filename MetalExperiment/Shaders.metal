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

vertex Fragment vertexShader(const device Vertex *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]]) {
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
                                   device Vertex *resultArr [[buffer(1)]],
                                   uint index [[thread_position_in_grid]]) {
    
    float deltaAngle = 2.0 * M_PI_F / polygonsArr[index].amountOfSides; // Angle increment for each vertex
    int i = 0;
    float currentAngle = 0;
    
    simd_float2 center = polygonsArr[index].center;
    float radius = polygonsArr[index].radius;
    
    // Iterate over each vertex of the polygon
    while (i < polygonsArr[index].amountOfSides) {
        // Calculate the position of the current vertex
        simd_float2 currentPoint = vector_float2(radius * cos(currentAngle) + center.x,
                                                 radius * sin(currentAngle) + center.y);
        
        // Create vertices for the triangle
        Vertex v1, v2, v3;
        v1.position = currentPoint;
        v1.color = polygonsArr[index].color;
        
        v2.position = center;
        v2.color = polygonsArr[index].color;
        
        currentAngle += deltaAngle; // Move to the next angle
        
        // Calculate the position of the next vertex
        simd_float2 nextPoint = vector_float2(radius * cos(currentAngle) + center.x,
                                              radius * sin(currentAngle) + center.y);
        
        v3.position = nextPoint;
        v3.color = polygonsArr[index].color;
        
        // Assign the vertices to the result array
        resultArr[polygonsArr[index].bufferStart + (i * 3)] = v1;
        resultArr[polygonsArr[index].bufferStart + (i * 3) + 1] = v2;
        resultArr[polygonsArr[index].bufferStart + (i * 3) + 2] = v3;
        
        i += 1; // Move to the next vertex
    }
}
