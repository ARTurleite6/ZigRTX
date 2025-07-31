const std = @import("std");

const math = @import("math.zig");
const Vec3 = math.Vec3;
const Color = math.Color;
const Ray = @import("Ray.zig");
const HitRecord = Ray.HitRecord;

const Sphere = @This();

pub const Material = union(enum) {
    lambertian: struct {
        albedo: Color,

        pub fn scatter(self: @This(), ray_in: Ray, rec: HitRecord) ?Scatter {
            _ = ray_in;
            var scatter_direction = rec.normal + math.randomUnitVector();
            if (math.nearZero(scatter_direction)) {
                scatter_direction = rec.normal;
            }
            const scattered = Ray.init(rec.point, scatter_direction);
            return .{ .scattered_ray = scattered, .attenuation = self.albedo };
        }
    },
    metal: struct {
        albedo: Color,

        pub fn scatter(self: @This(), ray_in: Ray, rec: HitRecord) ?Scatter {
            const reflected = math.reflect(ray_in.direction, rec.normal);
            return .{
                .scattered_ray = Ray.init(rec.point, reflected),
                .attenuation = self.albedo,
            };
        }
    },

    const Scatter = struct {
        scattered_ray: Ray,
        attenuation: Color,
    };

    pub fn scatter(self: Material, ray_in: Ray, rec: HitRecord) ?Scatter {
        return switch (self) {
            inline else => |mat| mat.scatter(ray_in, rec),
        };
    }
};

center: Vec3,
radius: f64,
material: Material,

pub fn init(center: Vec3, radius: f64, material: Material) Sphere {
    return .{
        .center = center,
        .radius = radius,
        .material = material,
    };
}

pub fn hit(self: Sphere, ray: Ray, ray_t: math.Interval) ?Ray.HitRecord {
    const oc = self.center - ray.origin;
    const a = math.lengthSquared(ray.direction);
    const h = math.dot(ray.direction, oc);
    const c = math.lengthSquared(oc) - self.radius * self.radius;

    const discriminant = h * h - a * c;
    if (discriminant < 0.0) {
        return null;
    }
    const sqrtd = std.math.sqrt(discriminant);

    var root = (h - sqrtd) / a;
    if (!ray_t.surrounds(root)) {
        root = (h + sqrtd) / a;
        if (!ray_t.surrounds(root)) {
            return null;
        }
    }

    const point = ray.at(root);
    return Ray.HitRecord.init(
        point,
        (point - self.center) / math.splat(self.radius),
        root,
        self.material,
        ray,
    );
}
