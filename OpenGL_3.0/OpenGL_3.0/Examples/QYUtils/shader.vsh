attribute vec4 position;
attribute vec4 inputTextureCoordinate;

varying vec2 textureCoordinate;

uniform vec2 pixelsize;
uniform float type;
varying float transitionType;
varying vec2 imagesize;
varying float pixelRatio;

uniform float angle_x;
uniform float angle_y;
uniform float zoomValue;
uniform vec2 offset;
uniform float ratio;

void main()
{    
    mat4 rotationMatrix = mat4(cos(angle_x) , sin(angle_x) , 0.0, 0.0,
                               -sin(angle_x) * ratio, cos(angle_x) * ratio, 0.0, 0.0,
                               0.0, 0.0, 1.0, 0.0,
                               0.0, 0.0, 0.0, 1.0);
    
    mat4 rotationMatrix2 = mat4(cos(angle_y) , 0.0 , sin(angle_y), 0.0,
                               0.0, 1.0, 0.0, 0.0,
                               -sin(angle_y) * ratio, 0.0, cos(angle_y) * ratio, 0.0,
                               0.0, 0.0, 0.0, 1.0);

    mat4 zoomMatrix = mat4(zoomValue, 0.0, 0.0, 0.0,
                           0.0, zoomValue, 0.0, 0.0,
                           0.0, 0.0, 1.0, 0.0,
                           0.0, 0.0, 0.0, 1.0);

    mat4 offsetMatrix = mat4(1.0, 0.0, 0.0, offset.x,
                             0.0, 1.0, 0.0, offset.y,
                             0.0, 0.0, 1.0, 0.0,
                             0.0, 0.0, 0.0, 1.0);
    if (ratio > .0) {
        vec4 outPosition = vec4(position.r, position.g / ratio, position.b, position.a) * rotationMatrix * offsetMatrix * zoomMatrix * rotationMatrix2;
        gl_Position = outPosition;
    }
    else {
        gl_Position = position;
    }

    textureCoordinate   = inputTextureCoordinate.xy;
    transitionType      = type;
    imagesize           = pixelsize;
    pixelRatio          = ratio;
}
