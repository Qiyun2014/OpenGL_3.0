precision mediump float;
varying highp vec2 textureCoordinate;
uniform sampler2D inputImageTexture;

uniform float mTime;
uniform float chatrlet;
varying vec2 imagesize;
varying float transitionType;

uniform float intensity;

// 11x11
vec4 blur13(sampler2D image, vec2 uv, vec2 resolution, vec2 direction)
{
  vec4 color = vec4(0.0);
  vec2 off1 = vec2(1.411764705882353) * direction;
  vec2 off2 = vec2(3.2941176470588234) * direction;
  vec2 off3 = vec2(5.176470588235294) * direction;
  vec2 off4 = vec2(7.086470588235294) * direction;
  vec2 off5 = vec2(9.086470588235294) * direction;

  color += texture2D(image, uv) * 0.1947348383;
  color += texture2D(image, uv + (off1 / resolution)) * 0.2969069646728344;
  color += texture2D(image, uv - (off1 / resolution)) * 0.2969069646728344;
  color += texture2D(image, uv + (off2 / resolution)) * 0.15447039785044732;
  color += texture2D(image, uv - (off2 / resolution)) * 0.15447039785044732;
  color += texture2D(image, uv + (off3 / resolution)) * 0.080381362401148057;
  color += texture2D(image, uv - (off3 / resolution)) * 0.080381362401148057;
  color += texture2D(image, uv + (off4 / resolution)) * 0.010381362401148057;
  color += texture2D(image, uv - (off4 / resolution)) * 0.010381362401148057;
  return color;
}


void main()
{
   lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    if (chatrlet == 1.0)
    {
        if (transitionType == 0.0) {
            
        }
        else if (transitionType == 1.0) {
            float duration = 1.0;
            float progress = mod(mTime, duration) / duration * 2.0;
            float seg = 8.0;
            float y = (1.0 - textureCoordinate.y);
            
            for (float i = 0.0; i < seg; i ++)
            {
                float min_x = (i + progress) / seg;
                float max_x = (i + 1.0) / seg;
                if (y >= min_x && y < max_x)
                {
                    textureColor = vec4(0.0, 0.0, 0.0, 0.0);
                }
            }
        }
        else if (transitionType == 2.0) {
            float duration = 1.0;
            float progress = mod(mTime, duration) / duration * 2.0;
            float seg = 8.0;
            
            for (float i = 0.0; i < seg; i ++)
            {
                float min_x = (i + progress) / seg;
                float max_x = (i + 1.0) / seg;
                if (textureCoordinate.x >= min_x && textureCoordinate.x < max_x)
                {
                    textureColor = vec4(0.0, 0.0, 0.0, 0.0);
                }
            }
        }
        else if (transitionType == 3.0) {
            float duration = 1.0;
            float progress = mod(mTime, duration) / duration * 2.0;
            float seg = 8.0;
            float y = (1.0 - textureCoordinate.y);
            
            for (float i = 0.0; i < seg; i ++)
            {
                float min_x = (i + progress) / seg;
                float max_x = (i + 1.0) / seg;
                if (textureCoordinate.x >= min_x && textureCoordinate.x < max_x || (y >= min_x && y < max_x))
                {
                    textureColor = vec4(0.0, 0.0, 0.0, 0.0);
                }
            }
        }
        else if (transitionType == 4.0) {
            float duration = 2.0;
            float progress = mod(mTime, duration) / duration;
            
            float radius = 0.5;
            float rangle = progress * 180.0;
            vec2 xy = textureCoordinate.xy;
            vec2 dxy = xy - vec2(0.5);
            float r = length(dxy);
            float beta = atan(dxy.y, dxy.x) + radians(rangle) * 2.0 * (1.0 - (r / radius) * (r / radius));
            if (r <= radius) {
                xy = 0.5 + r * vec2(cos(beta), sin(beta));
            }
            textureColor = vec4(texture2D(inputImageTexture, xy).rgb, 1.0 - progress);
        }
    }
    else {
        vec2 uv = textureCoordinate.xy;
        vec2 radius = vec2(intensity, intensity);
        textureColor = blur13(inputImageTexture, uv, imagesize, radius);
    }

    gl_FragColor = textureColor;
}
