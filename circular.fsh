#define PI 3.1415926535897932384626433832795

//when mixProgress is at 0.0 it returns the startCol
float mixColor(float startCol, float endCol, float mixProgress)
{
    return startCol + ((endCol - startCol) * mixProgress);
}

//returns new radius depending where on the circle the fragCoord is
float squashCircle(vec2 center, vec2 fragCoord, float radius, float squashFactor)
{
    vec2 topLeft = vec2(center.x - radius, center.y + radius);
    vec2 bottomRight = vec2(center.x + radius, center.y - radius);
    
    if (length(fragCoord - topLeft) < length(fragCoord - bottomRight))
    {
        return (radius - squashFactor) + (squashFactor * 
        length(fragCoord - topLeft) / length(vec2(center.x + radius * 
        sqrt(2.0) / 2.0, center.y + radius * sqrt(2.0) / 2.0) - topLeft));
    }
    else
    {
        return (radius - squashFactor) + (squashFactor * 
        length(fragCoord - bottomRight) / length(vec2(center.x + radius * 
        sqrt(2.0) / 2.0, center.y + radius * sqrt(2.0) / 2.0) - bottomRight));
    }
}

vec4 drawCircleTrail(vec2 center, vec2 fragCoord, float radius, float squashFactor, 
vec4 bgColor, vec4 color, float shadeSize, float shadeWeight, bool shadowMode, 
float shadowWeight)
{
    float xCir = center.x - fragCoord.x;
    float yCir = center.y - fragCoord.y;
    float distFromCenter = sqrt((xCir * xCir) + (yCir * yCir));

    float x = fragCoord.x;
    float y = fragCoord.y;
    bool shouldRender = false;
    float newRadius;
    
    for (float f = 0.0; f < (shadeSize); ++f)
    {   
        x -= 1.0;
        y += 1.0;

        newRadius = squashCircle(center, vec2(x, y), radius, squashFactor);

        if (length(center - vec2(x, y)) <= newRadius)
        {
            shouldRender = true;
            break;
        }
    }

    vec2 parallelPoint = vec2(x, y);
    float x1 = parallelPoint.x - fragCoord.x;
    float y1 = parallelPoint.y - fragCoord.y;
    float distFromParallelPoint = sqrt((x1 * x1) + (y1 * y1));

    if (shouldRender && distFromParallelPoint <= shadeSize)
    {
        float shadeValue = shadeWeight * ((shadeSize - distFromParallelPoint) / shadeSize);

        vec4 trailColor = vec4(
        mixColor(bgColor.x, color.x, shadeValue),
        mixColor(bgColor.y, color.y, shadeValue),
        mixColor(bgColor.z, color.z, shadeValue),
        1.0);

        if (shadowMode)
        {
            trailColor = vec4(
            mixColor(bgColor.x, trailColor.x - shadowWeight, shadeValue),
            mixColor(bgColor.y, trailColor.y - shadowWeight, shadeValue),
            mixColor(bgColor.z, trailColor.z - shadowWeight, shadeValue),
            1.0);
        }

        return trailColor;
    }
    else
    {
        return bgColor;
    }
}

vec4 drawCircle(vec2 center, vec2 fragCoord, float radius, float squashFactor, 
vec4 bgColor, vec4 color, float shadeSize, float shadeWeight)
{
    float x = fragCoord.x - center.x;
    float y = fragCoord.y - center.y;
    float dist = sqrt((x * x) + (y * y));
    float newRadius = squashCircle(center, fragCoord, radius, squashFactor);
    
    if (dist <= newRadius)
    {
        float angleFromBottomRight = acos(clamp(dot(vec2(x, y), vec2(-1, 1)) / 
        (dist * sqrt(2.0)), -1.0, 1.0));
        float angleShadeFactor = 1.0;
        
        if (angleFromBottomRight < PI / 2.0)
        {
            angleShadeFactor = 2.0 * (angleFromBottomRight / PI);
        }
    
        float shadeValue = shadeWeight * (shadeSize / (shadeSize + newRadius - dist));
        
        shadeValue = mixColor(shadeWeight * (shadeSize / (shadeSize + newRadius))
        , shadeValue, angleShadeFactor);
        
        return vec4(
        color.x - shadeValue,
        color.y - shadeValue,
        color.z - shadeValue,
        1.0);
    }
    else
    {
        return bgColor;
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    vec4 col = vec4(0.5 + 0.5*cos(iTime * 0.9 + uv.xyx + vec3(0,2,4)), 1.0);
    
    vec4 circleCol = vec4(0.9 + 0.5*sin(iTime * 0.9 + uv.xyx + vec3(0,2,4)), 1.0);
    
    vec2 center = vec2(iResolution.x / 2.0, iResolution / 3.0);

    vec4 outputColor;
    
    outputColor = drawCircleTrail(center, fragCoord, 100.0, 50.0, col, circleCol,
    300.0, 1.0, true, 0.7);
    
    outputColor = drawCircle(center, fragCoord, 100.0, 50.0, outputColor, circleCol,
    25.0, 0.7);

    fragColor = outputColor;
}