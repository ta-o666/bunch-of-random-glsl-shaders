const float offset = 75.0;
const float shadeWeight = 0.6;
const float trailHeight = 150.0;
const float shadeSegmentSize = 1.8;
const bool cameraMove = true;

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

vec4 drawCircleTrail(vec2 center, vec2 fragCoord, float radius, float distFromCenter, 
float squashFactor, vec4 bgColor, vec4 fadeColor, vec4 color, float shadeSize, 
bool shadowMode, float shadowWeight)
{
    vec2 parallelPoint = fragCoord;
    float newRadius;
    
    if (length(fragCoord - center) >= shadeSize + radius
    || dot(fragCoord - center, center - vec2(center.x + shadeSize, center.y - shadeSize
    )) > 0.0) return bgColor;


    for (float f = 0.0; f < shadeSize / shadeSegmentSize; f++)
    {   
        parallelPoint.x -= shadeSegmentSize;
        parallelPoint.y += shadeSegmentSize;
        
        newRadius = squashCircle(center, parallelPoint, radius, squashFactor);

        if (length(center - parallelPoint) <= newRadius) break;
    }

    float distFromParallelPoint = length(parallelPoint - fragCoord);

    if (distFromParallelPoint <= shadeSize)
    {
        float shadeValue = smoothstep(1.0, 0.0, distFromParallelPoint / shadeSize);

        vec4 trailColor = vec4(
        mixColor(fadeColor.x, color.x, shadeValue),
        mixColor(fadeColor.y, color.y, shadeValue),
        mixColor(fadeColor.z, color.z, shadeValue),
        1.0);

        if (shadowMode)
        {
            trailColor = vec4(
            mixColor(fadeColor.x, trailColor.x - shadowWeight, shadeValue),
            mixColor(fadeColor.y, trailColor.y - shadowWeight, shadeValue),
            mixColor(fadeColor.z, trailColor.z - shadowWeight, shadeValue),
            1.0);
        }

        return trailColor;
    }
    else
    {
        return bgColor;
    }
}

vec4 drawCircle(vec2 center, vec2 fragCoord, float radius, vec2 distCenterVec, 
float distFromCenter, float squashFactor, vec4 bgColor, vec4 color, float shadeSize, 
float shadeWeight)
{
    float newRadius = squashCircle(center, fragCoord, radius, squashFactor);
    
    if (distFromCenter <= newRadius)
    {
        float angleFromBottomRight = acos(clamp(dot(distCenterVec, vec2(-1, 1)) / 
        (distFromCenter * sqrt(2.0)), -1.0, 1.0));
        float angleShadeFactor = 1.0;
        
        if (angleFromBottomRight < PI / 2.0)
        {
            angleShadeFactor = 2.0 * (angleFromBottomRight / PI);
        }
    
        float shadeValue = shadeWeight * (shadeSize / 
        (shadeSize + newRadius - distFromCenter));

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

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord/iResolution.xy;

    vec4 col = vec4(0.5 + 0.5*cos(iTime * 0.9 + uv.xyx + vec3(0,2,4)), 1.0);
    
    vec4 circleCol = vec4(0.9 + 0.5*sin(iTime * 0.9 + uv.xyx + vec3(0,2,4)), 1.0);
    vec2 center;
    vec4 outputColor = col;
    float maxRadius = iResolution.x * (100.0 / 768.0);

    for (float j = 0.0; j < 21.0; j++)
    {   
        float i = iResolution.x * mod(j, 5.0) / 3.5;
        float k = iResolution.y;
        
        if (j < 5.0)
        {
            i -= iResolution.x / 7.0;
            k *= 1.41;
        }

        if (j >= 5.0 && j < 10.0)
        {
            k *= 0.94;
        }
        
        if (j >= 10.0 && j < 15.0)
        {
            i -= iResolution.x / 7.0;
            k *= 0.47;
        }
        
        if (j >= 15.0 && j <= 20.0)
        {
            k *= 0.0;
        }
        
        
        float centerx = i + (((150.0 * sin(((iTime - 75.0) 
        * PI))) + 150.0) * (iResolution.x * (offset / 768.0) / 300.0));
        
        float centery = k - (((150.0 * sin(((iTime - 75.0) 
        * PI))) + 150.0) * (iResolution.y * (offset / 432.0) / 300.0));
        
        float centerx1 = centerx;
        float centery1 = centery;
        
        if (cameraMove)
        {
            float camOffset = mod(iTime * 2.0, 1.0);
            centerx1 -= camOffset * iResolution.x * 0.143;
            centery1 -= camOffset * iResolution.y * 0.47;
        }

        vec2 center1 = vec2(centerx1, centery1);
        vec2 center = vec2(centerx, centery);
        vec2 originalCenter = vec2(i, k);
        
        float x = fragCoord.x - center1.x;
        float y = fragCoord.y - center1.y;
        float distFromCenter = sqrt((x * x) + (y * y));
    
        outputColor = drawCircleTrail(center1, fragCoord, maxRadius, distFromCenter, 
        maxRadius / 2.0, outputColor, col, circleCol, iResolution.x * ((trailHeight - 
        (768.0 * length(originalCenter - center) / iResolution.x)) / 768.0), true, 
        shadeWeight);
    
        outputColor = drawCircle(center1, fragCoord, maxRadius, vec2(x, y), 
        distFromCenter, maxRadius / 2.0, outputColor, circleCol, maxRadius * 0.4, 
        shadeWeight);   
    }

    fragColor = outputColor;
}