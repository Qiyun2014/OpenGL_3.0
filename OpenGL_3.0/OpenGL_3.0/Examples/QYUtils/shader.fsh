precision mediump float;
varying highp vec2 textureCoordinate;
uniform sampler2D inputImageTexture;

uniform float mTime;
uniform float chatrlet;
varying vec2 imagesize;
varying float transitionType;
uniform float intensity;

// 9x9
vec4 blur13(sampler2D image, vec2 uv, vec2 resolution, vec2 direction)
{
    vec4 sum = vec4(0.0);
    vec2 size = intensity / resolution;
        
    sum += texture2D(image, vec2(uv + 1.0 * size * direction)) * 0.125794;
    sum += texture2D(image, vec2(uv + 2.0 * size * direction)) * 0.106483;
    sum += texture2D(image, vec2(uv + 3.0 * size * direction)) * 0.080657;
    sum += texture2D(image, vec2(uv + 4.0 * size * direction)) * 0.054670;
    sum += texture2D(image, vec2(uv + 5.0 * size * direction)) * 0.033159;
    sum += texture2D(image, vec2(uv + 6.0 * size * direction)) * 0.017997;
    sum += texture2D(image, vec2(uv + 7.0 * size * direction)) * 0.008741;
    sum += texture2D(image, vec2(uv + 8.0 * size * direction)) * 0.003799;
    sum += texture2D(image, uv) * 0.137401;
    sum += texture2D(image, vec2(uv - 8.0 * size * direction)) * 0.003799;
    sum += texture2D(image, vec2(uv - 7.0 * size * direction)) * 0.008741;
    sum += texture2D(image, vec2(uv - 6.0 * size * direction)) * 0.017997;
    sum += texture2D(image, vec2(uv - 5.0 * size * direction)) * 0.033159;
    sum += texture2D(image, vec2(uv - 4.0 * size * direction)) * 0.054670;
    sum += texture2D(image, vec2(uv - 3.0 * size * direction)) * 0.080657;
    sum += texture2D(image, vec2(uv - 2.0 * size * direction)) * 0.106483;
    sum += texture2D(image, vec2(uv - 1.0 * size * direction)) * 0.125794;
    
    return sum;
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
        if (intensity > 0.0)
        {
            vec2 uv = textureCoordinate.xy;
            vec2 radius = vec2(1.0, 1.0);
            textureColor = blur13(inputImageTexture, uv, imagesize, radius);
        }
    }

    gl_FragColor = textureColor;
}
