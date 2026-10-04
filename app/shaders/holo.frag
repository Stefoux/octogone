#version 460 core
// Effets holographiques des cartes Octogone (créations originales).
// Dessiné PAR-DESSUS la carte (mode de fusion choisi côté Dart).
//
// uMode :
//   0 refractor   reflets arc-en-ciel en bandes diagonales, teintés si uColor.a > 0
//   1 x-fractor   quadrillage scintillant
//   2 prism       éclats de prisme triangulaires
//   3 speckle     paillettes
//   4 wave        vagues
//   5 superfractor spirale dorée
//   6 acier       métal brossé + grillage de cage
//   8 onde        ondes de choc depuis un point d'impact (animé)
//   9 octogone    octogone holographique sur fond noir mat
//  10 or          feuille d'or / plaque dorée
//  11 chrome      reflet discret de carte chrome de base
//  12 tatami      tissage de tatami + étreinte qui se resserre (animé)
//  13 arene       projecteurs d'arène dans le noir
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;
uniform vec2 uTilt;      // inclinaison -1..1
uniform float uTime;     // secondes
uniform vec4 uColor;     // teinte rgb + force de la teinte (a)
uniform float uMode;
uniform float uIntensity;

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
             mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

vec3 hsv(float h, float s, float v) {
  vec3 k = clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
  return v * mix(vec3(1.0), k, s);
}

vec3 tinted(vec3 rainbow) {
  return mix(rainbow, uColor.rgb * (0.65 + 0.55 * dot(rainbow, vec3(0.33))), uColor.a);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  vec2 t = uTilt;
  float aspect = uSize.y / uSize.x;
  vec3 col = vec3(0.0);
  float a = 0.0;

  // Reflet principal : une bande lumineuse qui balaie la carte selon l'inclinaison.
  float diag = uv.x * 0.75 + uv.y * 0.55;
  float sweep = 1.0 - smoothstep(0.0, 0.32, abs(diag - (0.65 + t.x * 0.55 + t.y * 0.35)));

  if (uMode < 0.5) {
    float h = fract(diag * 1.4 + t.x * 0.45 + t.y * 0.3);
    float bands = 0.5 + 0.5 * sin((diag + t.x * 0.4) * 38.0);
    col = tinted(hsv(h, 0.55, 1.0));
    a = 0.18 + 0.32 * bands * (0.4 + sweep);
  } else if (uMode < 1.5) {
    vec2 g = abs(sin((uv + t * 0.05) * vec2(90.0, 90.0 * aspect)));
    float grid = pow(max(g.x, g.y), 18.0);
    col = tinted(hsv(fract(diag + t.x * 0.6), 0.5, 1.0));
    a = 0.04 + 0.35 * grid * (0.35 + sweep);
  } else if (uMode < 2.5) {
    vec2 p = uv * vec2(11.0, 11.0 * aspect);
    vec2 cell = floor(p + vec2(floor(p.y) * 0.5, 0.0));
    float tri = step(fract(p.x), fract(p.y));
    float r = hash(cell + tri * 7.1);
    float facet = 0.5 + 0.5 * sin(r * 6.2831 + t.x * 4.0 + t.y * 3.0);
    col = tinted(hsv(fract(r + t.x * 0.3), 0.6, 1.0));
    a = 0.05 + 0.28 * facet * facet * (0.5 + sweep);
  } else if (uMode < 3.5) {
    vec2 p = uv * vec2(70.0, 70.0 * aspect);
    float r = hash(floor(p));
    float tw = step(0.93, r) * (0.5 + 0.5 * sin(r * 40.0 + t.x * 9.0 + t.y * 7.0));
    col = tinted(hsv(fract(r * 3.0 + t.y), 0.4, 1.0));
    a = 0.1 + 0.15 * sweep + 0.85 * tw;
  } else if (uMode < 4.5) {
    float w = sin(uv.y * 22.0 * aspect + sin(uv.x * 7.0 + t.x * 3.0) * 2.4 + t.y * 5.0);
    col = tinted(hsv(fract(uv.y * 0.8 + t.x * 0.3), 0.5, 1.0));
    a = 0.12 + 0.38 * smoothstep(0.4, 1.0, w) + 0.2 * sweep;
  } else if (uMode < 5.5) {
    vec2 p = (uv - 0.5) * vec2(1.0, aspect);
    float ang = atan(p.y, p.x);
    float r = length(p);
    float s = 0.5 + 0.5 * sin(ang * 7.0 + r * 34.0 - t.x * 5.0 - t.y * 3.0 + uTime * 0.6);
    vec3 gold = mix(vec3(0.95, 0.68, 0.22), vec3(1.0, 0.95, 0.7), s);
    col = mix(gold, hsv(fract(ang / 6.2831 + t.x * 0.2), 0.4, 1.0), 0.25);
    a = 0.25 + 0.45 * s * (0.6 + sweep);
  } else if (uMode < 6.5) {
    float brushed = noise(vec2(uv.x * 2.0, uv.y * 260.0)) * 0.6 + noise(vec2(uv.x * 9.0, uv.y * 700.0)) * 0.4;
    vec2 d = uv * vec2(14.0, 14.0 * aspect);
    vec2 dd = vec2(d.x + d.y, d.x - d.y);
    vec2 f = abs(fract(dd) - 0.5);
    float wire = 1.0 - smoothstep(0.03, 0.07, min(f.x, f.y));
    col = vec3(0.78, 0.82, 0.88) * (0.55 + 0.45 * brushed) + vec3(1.0) * sweep * 0.5;
    a = 0.05 + 0.2 * sweep + 0.32 * wire * (0.6 + 0.4 * brushed);
  } else if (uMode < 8.5) {
    vec2 impact = vec2(0.5, 0.38);
    float r = length((uv - impact) * vec2(1.0, aspect));
    float wave = sin(r * 42.0 - uTime * 7.0);
    float ring = smoothstep(0.75, 1.0, wave) * exp(-r * 2.2);
    col = mix(vec3(0.35, 0.85, 1.0), vec3(1.0), ring);
    a = 0.05 + 0.8 * ring + 0.12 * sweep;
  } else if (uMode < 9.5) {
    vec2 p = (uv - vec2(0.5, 0.42)) * vec2(1.0, aspect);
    vec2 q = abs(p);
    float oct = max(max(q.x, q.y), (q.x + q.y) * 0.7071);
    float edge = 1.0 - smoothstep(0.0, 0.02, abs(oct - 0.33));
    float inner = 1.0 - smoothstep(0.0, 0.012, abs(oct - 0.29));
    float sparkle = step(0.985, hash(floor(uv * vec2(120.0, 120.0 * aspect)))) * (0.5 + 0.5 * sin(uTime * 3.0 + uv.x * 50.0));
    col = hsv(fract(atan(p.y, p.x) / 6.2831 + t.x * 0.5 + t.y * 0.3 + uTime * 0.05), 0.7, 1.0);
    a = 0.85 * max(edge, inner * 0.6) + 0.5 * sparkle;
  } else if (uMode < 10.5) {
    float r = hash(floor(uv * vec2(90.0, 90.0 * aspect)));
    float sparkle = step(0.94, r) * (0.5 + 0.5 * sin(r * 50.0 + t.x * 8.0 + t.y * 6.0 + uTime * 2.0));
    col = mix(vec3(0.95, 0.72, 0.28), vec3(1.0, 0.95, 0.72), sparkle);
    a = 0.04 + 0.18 * sweep + 0.8 * sparkle;
  } else if (uMode < 11.5) {
    col = vec3(1.0);
    a = 0.22 * sweep;
  } else if (uMode < 12.5) {
    vec2 p = uv * vec2(10.0, 10.0 * aspect);
    float weave = 0.5 + 0.5 * sin(p.x * 6.2831) * sin(p.y * 6.2831 * 4.0);
    float squeeze = 0.5 + 0.5 * sin(uTime * 1.6);
    vec2 c = (uv - 0.5) * vec2(1.0, aspect * 0.8);
    float vign = smoothstep(0.32 - 0.06 * squeeze, 0.62, length(c));
    col = mix(vec3(0.72, 0.66, 0.42), vec3(0.08, 0.05, 0.02), vign);
    a = 0.1 + 0.12 * weave + 0.6 * vign;
  } else {
    vec2 p = uv - vec2(0.5, -0.1);
    float cone1 = 1.0 - smoothstep(0.0, 0.18, abs(p.x + 0.2 - p.y * 0.25));
    float cone2 = 1.0 - smoothstep(0.0, 0.18, abs(p.x - 0.2 + p.y * 0.25));
    float dark = smoothstep(0.25, 0.8, length((uv - vec2(0.5, 0.45)) * vec2(1.0, aspect * 0.7)));
    col = mix(vec3(0.0), vec3(0.75, 0.85, 1.0), max(cone1, cone2) * (1.0 - uv.y));
    a = 0.32 * dark + 0.15 * max(cone1, cone2) * (1.0 - uv.y);
  }

  a = clamp(a * uIntensity, 0.0, 1.0);
  fragColor = vec4(col * a, a);
}
