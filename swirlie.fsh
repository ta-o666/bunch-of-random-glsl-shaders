//original shader from https://www.shadertoy.com/view/tdG3Rd

const bool vignette = true;
const float vignetteWeight = 0.1;

//lightbursts only work if hueCycleMode is false
const bool lightBursts = true;
const float lightBurstDura = 3.5;
//range: [0.0, 3.0]
const float lightBurstFactor = 2.0;

//range: [0.1, 1.0]
const float contrast = 0.8;
//range: [1.0, 1000.0]
const float swirlFactor = 2.0;

const bool hueCycleMode = false;
const bool huePearlescent = true;
const float huePearlescentRainbowSpeed = 0.2;
//range: [-1.0, 1.0]
const float huePearlescentValleySat = -1.0;
//range: [-1.0, 1.0]
const float huePearlescentValleyBright = 1.0;
const float huePearlescentLayers = 3.0;
const float huePearlescentSat = 0.5;
const float huePearlescentBright = 0.9;
const float speed = 0.3;
const float scale = 1.5;

const bool color1Rainbow = false;
const float color1RainbowSpeed = 0.2;
const float color1RainbowSat = 1.0;
const float color1RainbowBright = 1.0;
const vec3 color1 = vec3(1.0, 1.0, 0.0);

const bool color2Rainbow = false;
const float color2RainbowSpeed = 0.2;
const float color2RainbowSat = 1.0;
const float color2RainbowBright = 1.0;
const vec3 color2 = vec3(1.0, 0.0, 0.0);

const mat2 mtx = mat2(0.8, -0.6, 0.6, 0.8);

#define PI 3.1415926535897932384626433832795

//from https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float kindaRand(vec2 inVec2) 
{ 
    return contrast * fract(sin(dot(inVec2, vec2(inVec2.x / swirlFactor * 0.01, 
    inVec2.y * swirlFactor * 0.01))) * 5.0);
}

float noise(vec2 inVec2)
{
    vec2 flooredinVec2 = floor(inVec2);
    vec2 u = fract(inVec2);
    u = u * (3.0 - 2.0 * u);

    float outFactor = mix(
    mix(kindaRand(flooredinVec2),kindaRand(flooredinVec2 + vec2(1.0,0.0)), u.x),
    mix(kindaRand(flooredinVec2 + vec2(0.0,1.0)), 
    kindaRand(flooredinVec2 + vec2(1.0,1.0)), u.x),
    u.y);
    
    return outFactor * outFactor;
}

float fbm(vec2 inVec2)
{
    float f = 0.0;
    
    f += 0.5 * noise(inVec2 + iTime * speed); 
    inVec2 *= mtx * 2.05;
    
    f += 0.03 * noise(inVec2); 
    inVec2 *= mtx * 2.04;
    
    f += 0.25 * noise(inVec2); 
    inVec2 *= mtx * 2.03;
    
    f += 0.125 * noise(inVec2); 
    inVec2 *= mtx * 2.02;
    
    f += 0.06 * noise(inVec2); 
    inVec2 *= mtx * 2.01;
    
    return f;
}

float pattern(vec2 inVec2) 
{
    vec2 r = vec2(fbm(inVec2 + 4.0 + vec2(1.7, 9.2)));
    r += iTime * speed * 0.5;
    return fbm(inVec2 + 1.76 * r);
}

vec4 vig(vec2 uv, vec4 bgColor)
{
    uv *= (1.0 - uv.yx);
    return bgColor * pow(uv.x * uv.y * 15.0, vignetteWeight);
}


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    if (hueCycleMode)
    {   
        if (huePearlescent)
        {
            float colorInitHue = mod(iTime * huePearlescentRainbowSpeed, 1.0);
            
            float colorSat = mix(huePearlescentSat, huePearlescentValleySat
            , pattern(uv * scale));
            
            float colorVal = mix(huePearlescentBright, huePearlescentValleyBright
            , pattern(uv * scale));
            
            if (lightBursts && pattern(uv * scale) > 0.25 * cos(iTime * 2.0 * PI / lightBurstDura) + 0.5)
            {
                colorSat = mix(colorSat, -lightBurstFactor, (pattern(uv * scale) - 
                (0.25 * cos(iTime * 2.0 * PI / lightBurstDura) + 0.5)) / (0.25 * cos(iTime * 2.0) + 0.5));
            }
            
            vec3 color = hsv2rgb(vec3(colorInitHue + pattern(uv * scale) * 
            huePearlescentLayers, colorSat, colorVal));
            
            fragColor = vec4(color, 1.0);
        }
        else
        {
            float colorHue = mix(rgb2hsv(color1).x, rgb2hsv(color2).x, pattern(uv * 
            scale));
            
            float colorSat = mix(rgb2hsv(color1).y, rgb2hsv(color2).y, pattern(uv * 
            scale));
           
            float colorVal = mix(rgb2hsv(color1).z, rgb2hsv(color2).z, pattern(uv * 
            scale));
            
            if (lightBursts && pattern(uv * scale) > 0.25 * cos(iTime * 2.0 * PI / lightBurstDura) + 0.5)
            {
                colorSat = mix(colorSat, -lightBurstFactor, (pattern(uv * scale) - 
                (0.25 * cos(iTime * 2.0 * PI / lightBurstDura) + 0.5)) / (0.25 * cos(iTime * 2.0) + 0.5));
            }
            
            fragColor = vec4(hsv2rgb(vec3(colorHue, colorSat, colorVal)), 1.0);
        }
    }
    else
    {
        vec4 colorOne = vec4(color1, 1.0);
        vec4 colorTwo = vec4(color2, 1.0);
        
        if (color1Rainbow)
        {
            colorOne = vec4(hsv2rgb(vec3(iTime * color1RainbowSpeed, color1RainbowSat, 
            color1RainbowBright)), 1.0);
        }
        
        if (color2Rainbow)
        {
            colorTwo = vec4(hsv2rgb(vec3(iTime * color2RainbowSpeed, color2RainbowSat, 
            color2RainbowBright)), 1.0);
        }
        
        if (lightBursts && pattern(uv * scale) > 0.25 * cos(iTime * 2.0 * PI / lightBurstDura) + 0.5)
        {
            vec3 r = rgb2hsv(vec3(colorTwo.x, colorTwo.y, colorTwo.z));
            colorTwo = vec4(hsv2rgb(vec3(r.x, mix(r.y, -lightBurstFactor, (pattern(uv * scale) - 
            (0.25 * cos(iTime * 2.0 * PI / lightBurstDura) + 0.5)) / (0.25 * cos(iTime * 2.0) + 0.5)), 
            r.z)), 1.0);
        }
        
        fragColor = mix(colorOne, colorTwo, pattern(uv * scale));
    }
    
    if (vignette)
    {
        fragColor = vig(uv, fragColor);
    }
}