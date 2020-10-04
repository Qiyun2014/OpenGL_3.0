precision mediump float;
varying highp vec2 textureCoordinate;
uniform sampler2D inputImageTexture;

uniform float mTime;
uniform float chatrlet;
varying vec2 imagesize;
varying float transitionType;
uniform float indensity;
varying float pixelRatio;


vec4 multiScreen(sampler2D inputImageTexture, vec2 textureCoordinate)
{
    // 2 row and 3 cols
    vec2 range = vec2(2.0, 3.0);
    mediump vec2 p = mod(range  * textureCoordinate - vec2( 1.0 ), 1.0);
    lowp vec4 outputColor = texture2D(inputImageTexture, p);
    return outputColor;
}


vec4 cornerBolder(vec4 textureColor, float corner)
{
    // Corner circle on crop
    float radius = 0.5;
    // full screen radius size
    float fullRadius = sqrt(radius);
    // corner size of radius scale
    float cornerRadius = corner / imagesize.x / radius;
    // last radius size
    radius = fullRadius - cornerRadius;
    // center circle of point
    vec2 centerCircle = vec2(0.5, 0.5);
    // the top half part
    if (textureCoordinate.y <= centerCircle.y)
    {
        // R^2 = X^2 + Y^2 (formula)
        float y1 = sqrt(radius * radius - (textureCoordinate.x - centerCircle.x) * (textureCoordinate.x - centerCircle.x)) + centerCircle.y;
        if (textureCoordinate.y <= (1.0 - y1) / pixelRatio)
        {
            textureColor = vec4(1.0, 1.0, 1.0, 0.0);
        }
    }
    // the down half part
    else
    {
        float y2 = -sqrt(radius * radius - (textureCoordinate.x - centerCircle.x) * (textureCoordinate.x - centerCircle.x)) + centerCircle.y;
        if (textureCoordinate.y >= (1.0 - y2 / pixelRatio))
        {
            textureColor = vec4(1.0, 1.0, 1.0, 0.0);
        }
    }
    return textureColor;
}



// 9x9
vec4 blur13(sampler2D image, vec2 uv, vec2 resolution, vec2 direction)
{
    vec4 sum = vec4(0.0);
    vec2 size = vec2(0.0, indensity) / resolution;
        
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
       if (transitionType == 1.0)
       {
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
        if (indensity > 0.0)
        {
            vec2 uv = textureCoordinate.xy;
            vec2 radius = vec2(1.0, 1.0);
            textureColor = blur13(inputImageTexture, uv, imagesize, radius);
        }
        
        if (mTime > 0.0) {
            textureColor = cornerBolder(textureColor, mTime * 10.0);
        }
    }
    gl_FragColor = textureColor;
}
