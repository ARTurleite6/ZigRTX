const Ray = @This();

const math = @import("math.zig");
const Vec3 = math.Vec3;
const Material = @import("Sphere.zig").Material;

pub const HitRecord = struct {
    point: Vec3,
    normal: Vec3,
    t: f64,
    front_face: bool,
    material: Material,

    pub fn init(point: Vec3, outward_normal: Vec3, t: f64, material: Material, ray: Ray) HitRecord {
        const front_face = math.dot(ray.direction, outward_normal) < 0.0;
        const normal = if (front_face) outward_normal else -outward_normal;

        return .{
            .point = point,
            .normal = normal,
            .t = t,
            .front_face = front_face,
            .material = material,
        };
    }
};

origin: Vec3,
direction: Vec3,

pub fn init(origin: Vec3, direction: Vec3) Ray {
    return .{
        .origin = origin,
        .direction = direction,
    };
}

pub fn at(self: Ray, t: f64) Vec3 {
    return @mulAdd(Vec3, @splat(t), self.direction, self.origin);
}
