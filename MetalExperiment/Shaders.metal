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
    float4 position [[position]];
    float4 color;
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

kernel void triangulateregularPoly(constant RegularPolygon *polygonsArr [[buffer(0)]],
                                   device Vertex *resultArr [[buffer(1)]],
                                            uint  index [[thread_position_in_grid]]) {
    
    float deltaAngle = 360 / polygonsArr[index].amountOfSides;
    int i = 0;
    float currentAngle = 0;
    
    vector_float2 currentPoint = vector_float2(polygonsArr[index].radius + polygonsArr[index].center[0], polygonsArr[index].center[1]);

    while (currentAngle < 360) {
        vector_float2 nextPoint = vector_float2(polygonsArr[index].radius * cos((currentAngle + deltaAngle) * M_PI_F / 180) + polygonsArr[index].center[0], polygonsArr[index].radius * sin((currentAngle + deltaAngle) * M_PI_F / 180) + polygonsArr[index].center[1]);
        
        // como eu faço esse retorno?? o buffer tem o tamanho certo, mas eu não sei onde cada poligono deve começar. acabar é começar + (lados*3)
        // fiz gambiarra
        Vertex v1 = Vertex();
        v1.position = currentPoint;
        v1.color = polygonsArr[index].color;
        resultArr[polygonsArr[index].bufferStart+i] = v1;
        
        Vertex v2 = Vertex();
        v2.position = polygonsArr[index].center;
        v2.color = polygonsArr[index].color;
        resultArr[polygonsArr[index].bufferStart+1+i] = v2;
        
        Vertex v3 = Vertex();
        v3.position = nextPoint;
        v3.color = polygonsArr[index].color;
        resultArr[polygonsArr[index].bufferStart+2+i] = v3;
        
        

        currentAngle += deltaAngle;
        i += 1;
    }
    
}
