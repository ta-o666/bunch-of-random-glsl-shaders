#version 140
uniform vec3 iResolution;
uniform float iTime;

vec4 drawCircleTrail(vec2 center, vec2 fragCoord, float radius, vec4 bgColor, vec4 color,
float shadeSize, float shadeWeight, bool shadowMode, float shadowWeight)
{
    float xCir = center.x - fragCoord.x;
    float yCir = center.y - fragCoord.y;
    float distFromCenter = sqrt((xCir * xCir) + (yCir * yCir));

    float x = fragCoord.x;
    float y = fragCoord.y;
    bool shouldRender = false;

    for (float f = 0.0; f < (shadeSize); ++f)
    {
        x -= 1.0;
        y += 1.0;

        if (sqrt(((center.x - x) * (center.x - x)) + ((center.y - y) * (center.y - y))) < radius)
        {
            shouldRender = true;
            break;
        }
    }

    vec2 parallelPoint = vec2(x, y);
    float x1 = parallelPoint.x - fragCoord.x;
    float y1 = parallelPoint.y - fragCoord.y;
    float distFromParallelPoint = sqrt((x1 * x1) + (y1 * y1));

    if (shouldRender && distFromCenter > radius && distFromParallelPoint <= shadeSize)
    {
        float shadeValue = shadeWeight * ((shadeSize - distFromParallelPoint) / shadeSize);

        vec4 trailColor = vec4(
        bgColor.x + ((color.x - bgColor.x) * shadeValue),
        bgColor.y + ((color.y - bgColor.y) * shadeValue),
        bgColor.z + ((color.z - bgColor.z) * shadeValue),
        1.0);

        if (shadowMode)
        {
            trailColor = vec4(
            bgColor.x + ((trailColor.x - shadowWeight - bgColor.x) * shadeValue),
            bgColor.y + ((trailColor.y - shadowWeight - bgColor.y) * shadeValue),
            bgColor.z + ((trailColor.z - shadowWeight - bgColor.z) * shadeValue),
            1.0);
        }

        return trailColor;
    }
    else
    {
        return bgColor;
    }
}

vec4 drawCircle(vec2 center, vec2 fragCoord, float radius, vec3 bgColor, vec4 color,
float shadeSize, float shadeWeight)
{
    float x = center.x - fragCoord.x;
    float y = center.y - fragCoord.y;
    float dist = sqrt((x * x) + (y * y));

    if (dist < radius)
    {
        float shadeValue = shadeWeight * (shadeSize / (shadeSize + radius - dist));

        return vec4(
        color.x - shadeValue,
        color.y - shadeValue,
        color.z - shadeValue,
        1.0);
    }
    else
    {
        return vec4(bgColor, 1.0);
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    vec3 col = 0.5 + 0.5*cos(iTime * 0.9 + uv.xyx + vec3(0,2,4));
    vec4 circleCol = vec4(0.9 + 0.5*sin(iTime * 0.9 + uv.xyx + vec3(0,2,4)), 1.0);
    vec2 center = vec2(iResolution.x / 2.0, iResolution / 3.0);

    vec4 outputColor = drawCircle(center, fragCoord, 100.0, col, circleCol,
    25.0, 0.7);

    fragColor = drawCircleTrail(center, fragCoord, 100.0, outputColor, circleCol,
    300.0, 1.0, true, 0.7);
}
