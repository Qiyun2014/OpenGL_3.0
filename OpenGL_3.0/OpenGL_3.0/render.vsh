attribute vec4 position;
attribute vec4 inputTextureCoordinate;

varying vec2 textureCoordinate;

varying float offset_x;
varying float offset_y;
varying vec2 imagesize;
varying float mType;

uniform float angle_x;
uniform float angle_y;
uniform float zoomValue;
uniform vec2 offset;
uniform vec2 pixelsize;
uniform float ratio;
uniform float transitionType;

void main()
{
   // x
   mat4 rotationMatrix = mat4(cos(angle_x) , sin(angle_x) , 0.0, 0.0,
                              -sin(angle_x) * ratio, cos(angle_x) * ratio, 0.0, 0.0,
                              0.0, 0.0, 1.0, 0.0,
                              0.0, 0.0, 0.0, 1.0);
   
   // y
   mat4 rotationMatrix2 = mat4(cos(angle_y) , 0.0 , sin(angle_y), 0.0,
                              0.0, 1.0, 0.0, 0.0,
                              -sin(angle_y) * ratio, 0.0, cos(angle_y) * ratio, 0.0,
                              0.0, 0.0, 0.0, 1.0);

   mat4 ratioMatrix = mat4(zoomValue, 0.0, 0.0, 0.0,
                           0.0, zoomValue, 0.0, 0.0,
                           0.0, 0.0, zoomValue, 0.0,
                           0.0, 0.0, 0.0, 1.0);

   mat4 offsetMatrix = mat4(1.0, 0.0, 0.0, offset.x,
                            0.0, 1.0, 0.0, offset.y,
                            0.0, 0.0, 1.0, 0.0,
                            0.0, 0.0, 0.0, 1.0);
   
   if (transitionType == 22.0)
   {
       gl_Position = position;
   }
   else
   {
       if (ratio > .0) {
           vec4 outPosition = vec4(position.r, position.g / ratio, position.b, position.a) * rotationMatrix * offsetMatrix * ratioMatrix * rotationMatrix2;
           gl_Position = outPosition;
          
       } else {
           vec4 outPosition = position * offsetMatrix * ratioMatrix;
           gl_Position = outPosition;
       }
   }
   
   textureCoordinate = inputTextureCoordinate.xy;
   offset_x = offset.x;
   offset_y = offset.y;
   imagesize = pixelsize;
   mType = transitionType;
}
