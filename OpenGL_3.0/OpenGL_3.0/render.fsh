precision mediump float;
varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

varying float offset_x;
varying float offset_y;
varying vec2 imagesize;
varying float mType;

uniform float intensity;


 vec4 vagueAlogrithum(vec2 textureCoordinate, float block)
 {
    float delta = 1.0 / block;
    vec4 color = vec4(0.0);
    
    float factor[9];
    factor[0] = 0.0947416; factor[1] = 0.118318; factor[2] = 0.0947416;
    factor[3] = 0.118318; factor[4] = 0.147761; factor[5] = 0.118318;
    factor[6] = 0.0947416; factor[7] = 0.118318; factor[8] = 0.0947416;
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            float x = max(0.0, textureCoordinate.x + float(i) * delta);
            float y = max(0.0, textureCoordinate.y + float(i) * delta);
            color += texture2D(inputImageTexture, vec2(x, y)) * factor[(i + 1) * 3+( j + 1)];
        }
    }
    return vec4(vec3(color), 1.0);
 }
 
 
 vec4 zoomBlurForSize(float blurSize) {
    vec2 centerPoint = vec2(0.5);
    vec2 samplingOffset = 1.0 / 100.0 * (centerPoint - textureCoordinate) * blurSize * 2.0;
    vec4 fragmentColor = texture2D(inputImageTexture, textureCoordinate) * 0.18;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate + samplingOffset) * 0.15 ;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate + (2.0 * samplingOffset)) *  0.12;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate + (3.0 * samplingOffset)) * 0.09;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate + (4.0 * samplingOffset)) * 0.05;
    
    fragmentColor += texture2D(inputImageTexture, textureCoordinate - samplingOffset) * 0.15;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate - (2.0 * samplingOffset)) *  0.12;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate - (3.0 * samplingOffset)) * 0.09;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate - (4.0 * samplingOffset)) * 0.05;
    return clamp(fragmentColor, 0.0, 1.0);
}

void main()
{
   lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
   
   if (22.0 == mType)
   {
       if (textureCoordinate.y < max(0.0, (0.5 - offset_y)) || textureCoordinate.y > min(1.0, 0.5 + offset_y)) {
           textureColor = vec4(0.0, 0.0, 0.0, 1.0);
       }
       gl_FragColor = textureColor;

   }
   else if (23.0 == mType)
   {
       lowp vec4 cloneColor;
       if (offset_x - textureCoordinate.x < .0)
       {
           textureColor = vec4(1.0, 1.0, 1.0, 0.0);
           cloneColor = texture2D(inputImageTexture2, vec2(textureCoordinate.x, textureCoordinate.y));
       }
       else
       {
           textureColor = texture2D(inputImageTexture, vec2(offset_x - textureCoordinate.x, textureCoordinate.y));
           cloneColor = vec4(1.0, 1.0, 1.0, 0.0);
       }
       gl_FragColor = textureColor * cloneColor;
   }
   else if (24.0 == mType)
   {
       // 3x2
       float row = 1.0 / 3.0;
       float rols = 1.0 / 2.0;
       vec2 coord = textureCoordinate.xy;
       vec2 pos;
       if (coord.y < rols) {
          if (coord.x <= row) {
              pos = vec2(row - coord.x, rols - coord.y);
          }
          else if ((coord.x > row) && (coord.x < row * 2.0)) {
              pos = vec2(coord.x - row, rols - coord.y);
          }
          else if (coord.x > row * 2.0 && (coord.x <= 1.0)) {
              pos = vec2(row - (coord.x - row * 2.0), rols - coord.y);
          }
       } else if (coord.y > rols) {
          if (coord.x <= row) {
              pos = vec2(row - coord.x, (coord.y - rols));
          }
          else if ((coord.x > row) && (coord.x < row * 2.0)) {
              pos = vec2(coord.x - row, (coord.y - rols));
          }
          else if (coord.x > row * 2.0 && coord.x <= 1.0) {
              pos = vec2(row - (coord.x - row * 2.0), (coord.y - rols));
          }
       }
       textureColor = vagueAlogrithum(vec2(pos.x * 3.0, pos.y * 2.0), 60.0);
       gl_FragColor = textureColor;
   }
   else if (25.0 == mType)
   {
       gl_FragColor = zoomBlurForSize(intensity);
   }
   else if (26.0 == mType)
   {
       gl_FragColor = textureColor;
       //gl_FragColor = vagueAlogrithum(textureCoordinate.xy, 120.0);
   }
   else
   {
       gl_FragColor = textureColor;
   }
}
