precision mediump float;
varying highp vec2 textureCoordinate;
uniform sampler2D inputImageTexture;

uniform sampler2D inputImageTexture2;
uniform float mTime;

uniform float chatrlet;

/*
void main()
{
   lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
    
    float duration = 1.0;
    float progress = mod(mTime, duration) / duration;
    float seg = 8.0;
    
    for (float i = 0.0; i < seg; i ++) {
        if (textureCoordinate.x >= (i + progress) / seg && textureCoordinate.x < ((i + 1.0) / seg)) {
            textureColor2 = vec4(0.0, 0.0, 0.0, 0.0);
        }
    }

    gl_FragColor = vec4((textureColor + textureColor2 / 2.0).rgb, 1.0);
}
*/

void main()
{
   lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    if (chatrlet == 1.0)
    {
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
                textureColor = vec4(1.0, 1.0, 1.0, 0.0);
            }
        }
    }

    gl_FragColor = textureColor;
}
