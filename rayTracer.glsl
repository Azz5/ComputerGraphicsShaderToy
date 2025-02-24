const float EPS = 1e-5;  // Epsilon offset to avoid self-intersections

// ---------------------------------------------------------------------------
// Simple RNG
float rand(inout vec2 seed) {
    float r = fract(sin(dot(seed, vec2(12.9898, 78.233))) * 43758.5453);
    seed += vec2(1.0, 1.0);
    return r;
}

// ---------------------------------------------------------------------------
// Structures

struct HitRecord {
    float t;
    vec3  p;
    vec3  normal;
    int   matType;   // 0: Lambertian, 1: Metal, 2: Dielectric
    vec3  albedo;
    float fuzz;
    float ref_idx;
    bool  hit;
};

// ---------------------------------------------------------------------------
// Sphere Intersection (assuming rd is normalized)
// Returns t (distance along ray) or -1.0 if no hit.
float intersectSphere(vec3 ro, vec3 rd, vec3 center, float radius) {
    vec3 oc = ro - center;
    float b  = dot(oc, rd);
    float c  = dot(oc, oc) - radius * radius;
    float disc = b * b - c;
    if (disc < 0.0) return -1.0;
    float sqrtDisc = sqrt(disc);
    float t = -b - sqrtDisc;  // The smaller root
    return t;
}

// ---------------------------------------------------------------------------
// Scene Description: Ground, Grid of Small Spheres, and Three Big Spheres
HitRecord hit_scene(vec3 ro, vec3 rd) {
    HitRecord rec;
    rec.t    = 1e9;
    rec.hit  = false;

    // Ground sphere
    {
        float t = intersectSphere(ro, rd, vec3(0.0, -1000.0, 0.0), 1000.0);
        if(t > EPS && t < rec.t) {
            rec.t       = t;
            rec.hit     = true;
            rec.p       = ro + t * rd;
            rec.normal  = normalize(rec.p - vec3(0.0, -1000.0, 0.0));
            rec.matType = 0; // Lambertian
            rec.albedo  = vec3(0.5);
            rec.fuzz    = 0.0;
            rec.ref_idx = 1.0;
        }
    }

    // Grid of small spheres
    for (int a = -11; a < 11; a++) {
        for (int b = -11; b < 11; b++) {
            // Give each grid position a unique random seed
            vec2 seed = vec2(float(a)*iTime, float(b)*iTime);

            float ra = rand(seed);
            float rb = rand(seed);

            vec3 center = vec3(float(a) + 0.9 * ra, 0.2, float(b) + 0.9 * rb);
            // Skip if too close to big sphere at (4, 0.2, 0)
            if(length(center - vec3(4.0, 0.2, 0.0)) > 0.9) {
                float t = intersectSphere(ro, rd, center, 0.2);
                if(t > EPS && t < rec.t) {
                    rec.t       = t;
                    rec.hit     = true;
                    rec.p       = ro + t * rd;
                    rec.normal  = normalize(rec.p - center);

                    float choose = rand(seed);
                    if(choose < 0.8) {
                        // Lambertian
                        rec.matType = 0;
                        rec.albedo  = vec3(rand(seed), rand(seed), rand(seed));
                        rec.albedo *= rec.albedo; // Darker tone
                        rec.fuzz    = 0.0;
                        rec.ref_idx = 1.0;
                    } 
                    else if(choose < 0.95) {
                        // Metal
                        rec.matType = 1;
                        rec.albedo  = vec3(0.5 + 0.5 * rand(seed),
                                           0.5 + 0.5 * rand(seed),
                                           0.5 + 0.5 * rand(seed));
                        rec.fuzz    = 0.0;
                        rec.ref_idx = 1.0;
                    }
                    else {
                        // Dielectric (glass)
                        rec.matType = 2;
                        rec.albedo  = vec3(1.0);
                        rec.fuzz    = 0.0;
                        rec.ref_idx = 1.5;
                    }
                }
            }
        }
    }

    // Three big spheres
    {
        // 1) Dielectric
        float t = intersectSphere(ro, rd, vec3(0.0, 1.0, 0.0), 1.0);
        if(t > EPS && t < rec.t) {
            rec.t       = t;
            rec.hit     = true;
            rec.p       = ro + t * rd;
            rec.normal  = normalize(rec.p - vec3(0.0, 1.0, 0.0));
            rec.matType = 2;
            rec.albedo  = vec3(1.0);
            rec.fuzz    = 0.0;
            rec.ref_idx = 1.5;
        }
        // 2) Lambertian
        t = intersectSphere(ro, rd, vec3(-4.0, 1.0, 0.0), 1.0);
        if(t > EPS && t < rec.t) {
            rec.t       = t;
            rec.hit     = true;
            rec.p       = ro + t * rd;
            rec.normal  = normalize(rec.p - vec3(-4.0, 1.0, 0.0));
            rec.matType = 0;
            rec.albedo  = vec3(0.4, 0.2, 0.1);
            rec.fuzz    = 0.0;
            rec.ref_idx = 1.0;
        }
        // 3) Metal
        t = intersectSphere(ro, rd, vec3(4.0, 1.0, 0.0), 1.0);
        if(t > EPS && t < rec.t) {
            rec.t       = t;
            rec.hit     = true;
            rec.p       = ro + t * rd;
            rec.normal  = normalize(rec.p - vec3(4.0, 1.0, 0.0));
            rec.matType = 1;
            rec.albedo  = vec3(0.7, 0.6, 0.5);
            rec.fuzz    = 0.0;
            rec.ref_idx = 1.0;
        }
    }
    
    return rec;
}

// ---------------------------------------------------------------------------
// Ray Color Function (Iterative Bounces)
vec3 ray_color(vec3 ro, vec3 rd) {
    // We'll do up to 50 bounces
    vec3 attenuation = vec3(1.0);
    for (int i = 0; i < 50; i++) {
        HitRecord rec = hit_scene(ro, rd);
        if (!rec.hit) {
            // Background gradient
            float t = 0.5 * (rd.y + 1.0);
            vec3 skyColor = mix(vec3(1.0), vec3(0.5, 0.7, 1.0), t);
            return attenuation * skyColor;
        }

        // Offset origin to avoid self-intersection
        vec3 offsetPos = rec.p + rec.normal * EPS;

        if(rec.matType == 0) {
            // Lambertian
            rd = normalize(rec.normal);
            ro = offsetPos;
            attenuation *= rec.albedo;
        }
        else if(rec.matType == 1) {
            // Perfect reflection (Metal)
            rd = reflect(rd, rec.normal);
            if(dot(rd, rec.normal) <= 0.0) {
                // Ray goes inside surface => black out
                return vec3(0.0);
            }
            ro = offsetPos;
            attenuation *= rec.albedo;
        }
        else {
            // Dielectric (Glass)
            float refractionRatio = (dot(rd, rec.normal) < 0.0) ? (1.0 / rec.ref_idx) : rec.ref_idx;
            float cosTheta = min(dot(-rd, rec.normal), 1.0);
            float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

            bool cannotRefract = refractionRatio * sinTheta > 1.0;
            if(cannotRefract) {
                rd = reflect(rd, rec.normal);
            } else {
                rd = refract(rd, rec.normal, refractionRatio);
            }
            // Offset along the normal or opposite normal
            ro = rec.p + (dot(rd, rec.normal) > 0.0 ? rec.normal : -rec.normal) * EPS;
        }
    }
    // If we exceed 50 bounces, return black
    return vec3(0.0);
}

// ---------------------------------------------------------------------------
// Main: Camera Setup, Supersampling, and Rendering
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Time-based angle for rotation
    float angle = iTime * 0.2;
    // Orbit radius
    float radius = 13.0;

    // Camera position rotating around Y-axis
    vec3 camPos = vec3(radius * cos(angle), 2.0, radius * sin(angle));

    // Target the origin
    vec3 camTarget = vec3(0.0, 0.0, 0.0);
    vec3 camUp     = vec3(0.0, 1.0, 0.0);

    // Vertical field-of-view and aspect ratio
    float vfov   = radians(20.0);
    float aspect = iResolution.x / iResolution.y;

    // Camera orientation
    vec3 w = normalize(camPos - camTarget);
    vec3 u = normalize(cross(camUp, w));
    vec3 v = cross(w, u);

    // Compute the viewport size
    float h = tan(vfov * 0.5);
    float viewportHeight = 2.0 * h;
    float viewportWidth  = aspect * viewportHeight;

    // Setup the screen plane
    vec3 horizontal       = viewportWidth  * u;
    vec3 vertical         = viewportHeight * v;
    vec3 lowerLeftCorner  = camPos - 0.5 * horizontal - 0.5 * vertical - w;

    // For simplicity, let's do only 1 sample per pixel here
    int samples = 1;
    vec3 finalColor = vec3(0.0);
    vec2 seed = fragCoord + iTime; // seed for RNG

    for(int s = 0; s < samples; s++) {
        // Random offset in [0, 1) for AA
        vec2 offset = vec2(rand(seed), rand(seed));

        float s_u = (fragCoord.x + offset.x) / iResolution.x;
        float s_v = (fragCoord.y + offset.y) / iResolution.y;

        // Build ray
        vec3 rd = lowerLeftCorner + s_u * horizontal + s_v * vertical - camPos;
        rd = normalize(rd);

        finalColor += ray_color(camPos, rd);
    }

    // Average color over the samples & simple gamma correction
    finalColor /= float(samples);
    finalColor  = sqrt(finalColor); 

    fragColor = vec4(finalColor, 1.0);
}
