#version 450
// Track F batching renderer: GS texture function, alpha test and fog in byte arithmetic.
// Targets are RGBA16F holding r,g,b / 255 and a / 128, so blend factors As/Ad/FIX are exact.
layout(location = 0) noperspective in vec4 vColor;
layout(location = 1) noperspective in vec3 vStq;
layout(location = 2) noperspective in float vFog;

layout(set = 0, binding = 0) uniform sampler2D tex;
layout(set = 1, binding = 0) uniform usampler2D mapTex; // texel -> target pixel and byte (flag 1024)
layout(set = 1, binding = 1) uniform sampler2D palTex;
layout(set = 1, binding = 2) uniform sampler2D dstTex;    // target before the primitive (DATE, flag 8192)   // 256 x 1 palette of a mapped read

layout(push_constant) uniform PC
{
    vec2 targetSize;
    vec2 texSize;
    uint flags;     // 1 tme, 2 fst, 4 linear, 8 fge, 16 texture is a surface, 32 fba, 64 invert alpha test, 128 depth surface,
                    // 1024 mapped read of a target (palette or reshaped), 4096 4-bit index
    uint tfxTcc;    // tfx | tcc << 2
    uint alphaTest; // atst | aref << 8
    uint fogColor;  // r | g << 8 | b << 16
    uint wrap;      // wms | wmt << 2
    uint clampU;    // minu | maxu << 16
    uint clampV;    // minv | maxv << 16
    float scale;
    vec2 texOffset;
    float depthScale;
    uint texa; // ta0 | aem << 8 | 512 = 24-bit texture (alpha from TEXA)
    uint mip;  // flag 32768: mxl | mmin << 3 | mmag << 6 | L << 7 | LCM << 9 | K (12 bits, 1/16) << 12
    uint pad0, pad1, pad2;
} pc;

layout(location = 0, index = 0) out vec4 outColor;
layout(location = 0, index = 1) out vec4 outFactor; // .a = As / 128 for the blend

int wrapCoord(int c, int size, uint mode, uint minv, uint maxv)
{
    if (mode == 0u) return c & (size - 1);
    if (mode == 1u) return clamp(c, 0, size - 1);
    if (mode == 2u) return clamp(c, int(minv), int(maxv));
    return int((uint(c) & minv) | maxv);
}

vec4 fetchTexel(ivec2 c)
{
    ivec2 size = ivec2(pc.texSize);
    c.x = wrapCoord(c.x, size.x, pc.wrap & 3u, pc.clampU & 0xFFFFu, pc.clampU >> 16);
    c.y = wrapCoord(c.y, size.y, (pc.wrap >> 2) & 3u, pc.clampV & 0xFFFFu, pc.clampV >> 16);
    // Never fetch outside the image: an out-of-bounds fetch can fault the GPU channel.
    ivec2 limit = textureSize(tex, 0) - 1;
    if ((pc.flags & 1024u) != 0u)
    {
        uvec2 m = texelFetch(mapTex, clamp(c, ivec2(0), textureSize(mapTex, 0) - 1), 0).rg;
        ivec2 p = clamp(ivec2((vec2(float(m.r & 0xFFFu), float(m.g)) + 0.5) * pc.scale), ivec2(0), limit);
        vec4 v = texelFetch(tex, p, 0);
        vec4 b;
        if ((pc.flags & 128u) != 0u)
        {
            uint z = uint(clamp(v.r, 0.0, 1.0) * pc.depthScale);
            b = vec4(float(z & 0xFFu), float((z >> 8) & 0xFFu), float((z >> 16) & 0xFFu), float(z >> 24));
        }
        else
            b = floor(vec4(clamp(v.rgb, 0.0, 1.0) * 255.0, clamp(v.a * 128.0, 0.0, 255.0)) + 0.5);
        if ((m.r & 0x8000u) != 0u) // whole 32-bit pixel (a reshaped read)
        {
            if ((pc.texa & 512u) != 0u)
                b.a = ((pc.texa & 256u) != 0u && all(lessThan(b.rgb, vec3(0.5)))) ? 0.0 : float(pc.texa & 0xFFu);
            return b;
        }
        uint byteValue = uint(b[int((m.r >> 12) & 3u)]);
        uint index = (pc.flags & 4096u) != 0u ? ((((m.r >> 14) & 1u) != 0u) ? (byteValue >> 4) : (byteValue & 15u)) : byteValue;
        return texelFetch(palTex, ivec2(int(index), 0), 0) * 255.0;
    }
    if ((pc.flags & 16u) == 0u)
        return texelFetch(tex, clamp(c, ivec2(0), limit), 0) * 255.0;
    ivec2 p = clamp(ivec2((vec2(c) + pc.texOffset + 0.5) * pc.scale), ivec2(0), limit);
    vec4 v = texelFetch(tex, p, 0);
    if ((pc.flags & 128u) != 0u)
    {
        uint z = uint(clamp(v.r, 0.0, 1.0) * pc.depthScale);
        return vec4(float(z & 0xFFu), float((z >> 8) & 0xFFu), float((z >> 16) & 0xFFu), float(z >> 24));
    }
    vec4 t = vec4(clamp(v.rgb, 0.0, 1.0) * 255.0, clamp(v.a * 128.0, 0.0, 255.0));
    if ((pc.texa & 512u) != 0u) // 24-bit read of a surface: alpha from TEXA
        t.a = ((pc.texa & 256u) != 0u && all(lessThan(t.rgb, vec3(0.5)))) ? 0.0 : float(pc.texa & 0xFFu);
    return t;
}

// Mip level n of a decoded texture: an atlas with level 0 on top and levels 1..n in a row below
// it. Half the size per level, region bounds scaled the same way (as gs_tiles.comp).
vec4 fetchLevel(ivec2 c, uint level)
{
    ivec2 size0 = ivec2(pc.texSize);
    ivec2 size = max(size0 >> int(level), ivec2(1));
    ivec2 origin = ivec2(0, level > 0u ? size0.y : 0);
    for (uint i = 1u; i < level; ++i)
        origin.x += max(size0.x >> int(i), 1);
    c.x = wrapCoord(c.x, size.x, pc.wrap & 3u, (pc.clampU & 0xFFFFu) >> level, (pc.clampU >> 16) >> level);
    c.y = wrapCoord(c.y, size.y, (pc.wrap >> 2) & 3u, (pc.clampV & 0xFFFFu) >> level, (pc.clampV >> 16) >> level);
    ivec2 limit = textureSize(tex, 0) - 1;
    return texelFetch(tex, clamp(origin + clamp(c, ivec2(0), size - 1), ivec2(0), limit), 0) * 255.0;
}

vec4 sampleLevel(vec2 uv, uint level, bool bilinear)
{
    vec2 luv = uv / float(1u << level);
    if (!bilinear)
        return floor(fetchLevel(ivec2(floor(luv)), level));
    vec2 f = luv - 0.5;
    ivec2 c = ivec2(floor(f));
    vec2 w = floor((f - floor(f)) * 256.0) / 256.0;
    vec4 top = mix(floor(fetchLevel(c, level)), floor(fetchLevel(c + ivec2(1, 0), level)), w.x);
    vec4 bottom = mix(floor(fetchLevel(c + ivec2(0, 1), level)), floor(fetchLevel(c + ivec2(1, 1), level)), w.x);
    return floor(mix(top, bottom, w.y));
}

vec4 sampleTexture()
{
    vec2 uv = (pc.flags & 2u) != 0u ? vStq.xy : vStq.xy / abs(vStq.z) * pc.texSize;
    // Mipmap per pixel: the GS LOD is (log2(1/|Q|) << L) + K, or K with LCM. MMIN 4/5 filter
    // inside a level, 3/5 blend two (weights in 1/256).
    if ((pc.flags & 32768u) != 0u && (pc.flags & 2u) == 0u)
    {
        uint mxl = pc.mip & 7u, mmin = (pc.mip >> 3) & 7u, mmag = (pc.mip >> 6) & 1u, lshift = (pc.mip >> 7) & 3u;
        float k = float(int(pc.mip << 8) >> 20) / 16.0;
        float aq = max(abs(vStq.z), 1e-30);
        float lod = ((pc.mip >> 9) & 1u) != 0u ? k : log2(1.0 / aq) * float(1u << lshift) + k;
        if (lod <= 0.0)
            return sampleLevel(uv, 0u, mmag != 0u);
        bool inLevelLinear = mmin >= 4u;
        float maxLevel = float(mxl);
        if (mmin == 2u || mmin == 4u)
            return sampleLevel(uv, uint(clamp(floor(lod + 0.5), 0.0, maxLevel)), inLevelLinear);
        float l0 = min(floor(lod), maxLevel);
        uint a = uint(l0), b = uint(min(l0 + 1.0, maxLevel));
        float weight = floor(clamp((lod - l0) * 256.0, 0.0, 255.0)) / 256.0;
        return floor(mix(sampleLevel(uv, a, inLevelLinear), sampleLevel(uv, b, inLevelLinear), weight));
    }
    if ((pc.flags & 4u) == 0u)
        return floor(fetchTexel(ivec2(floor(uv))));
    vec2 f = uv - 0.5;
    ivec2 c = ivec2(floor(f));
    vec2 w = floor((f - floor(f)) * 256.0) / 256.0;
    vec4 top = mix(floor(fetchTexel(c)), floor(fetchTexel(c + ivec2(1, 0))), w.x);
    vec4 bottom = mix(floor(fetchTexel(c + ivec2(0, 1))), floor(fetchTexel(c + ivec2(1, 1))), w.x);
    return floor(mix(top, bottom, w.y));
}

void main()
{
    if ((pc.flags & 8192u) != 0u) // DATE: destination alpha bit 7 must equal DATM (16384)
    {
        bool bit7 = texelFetch(dstTex, ivec2(gl_FragCoord.xy), 0).a * 128.0 >= 127.5;
        if (bit7 != ((pc.flags & 16384u) != 0u))
            discard;
    }
    vec4 c = floor(vColor + 0.5); // Gouraud rounds (PLANO_DESEMPENHO E1)
    if ((pc.flags & 1u) != 0u)
    {
        vec4 t = sampleTexture();
        uint tfx = pc.tfxTcc & 3u;
        bool tcc = (pc.tfxTcc & 4u) != 0u;
        vec4 r;
        if (tfx == 0u)      { r.rgb = floor(t.rgb * c.rgb / 128.0); r.a = tcc ? floor(t.a * c.a / 128.0) : c.a; }
        else if (tfx == 1u) { r.rgb = t.rgb; r.a = tcc ? t.a : c.a; }
        else if (tfx == 2u) { r.rgb = floor(t.rgb * c.rgb / 128.0) + c.a; r.a = tcc ? t.a + c.a : c.a; }
        else                { r.rgb = floor(t.rgb * c.rgb / 128.0) + c.a; r.a = tcc ? t.a : c.a; }
        c = clamp(r, 0.0, 255.0);
    }

    uint atst = pc.alphaTest & 7u;
    float aref = float((pc.alphaTest >> 8) & 0xFFu);
    bool pass = true;
    if (atst == 0u) pass = false;
    else if (atst == 2u) pass = c.a < aref;
    else if (atst == 3u) pass = c.a <= aref;
    else if (atst == 4u) pass = c.a == aref;
    else if (atst == 5u) pass = c.a >= aref;
    else if (atst == 6u) pass = c.a > aref;
    else if (atst == 7u) pass = c.a != aref;
    if ((pc.flags & 64u) != 0u) pass = !pass;
    if (!pass)
        discard;

    if ((pc.flags & 8u) != 0u)
    {
        float fog = floor(vFog + 0.5);
        vec3 fc = vec3(float(pc.fogColor & 0xFFu), float((pc.fogColor >> 8) & 0xFFu), float((pc.fogColor >> 16) & 0xFFu));
        c.rgb = floor(fog * c.rgb / 256.0) + floor((255.0 - fog) * fc / 256.0);
    }

    outFactor = vec4(0.0, 0.0, 0.0, c.a / 128.0);
    float stored = c.a;
    if ((pc.flags & 32u) != 0u && stored < 128.0)
        stored += 128.0;
    outColor = vec4(c.rgb / 255.0, stored / 128.0);
}
