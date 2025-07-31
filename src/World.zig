const std = @import("std");

const Ray = @import("Ray.zig");
const Sphere = @import("Sphere.zig");
const Interval = @import("math.zig").Interval;
const HitRecord = Ray.HitRecord;

const World = @This();

spheres: std.ArrayList(Sphere),

pub fn init(gpa: std.mem.Allocator) !World {
    return .{
        .spheres = std.ArrayList(Sphere).init(gpa),
    };
}

pub fn deinit(self: World) void {
    self.spheres.deinit();
}

pub fn addSphere(self: *World, sphere: Sphere) !void {
    try self.spheres.append(sphere);
}

pub fn hit(self: World, ray: Ray, ray_t: Interval) ?HitRecord {
    var temp_rec: ?HitRecord = null;

    for (self.spheres.items) |sphere| {
        if (sphere.hit(ray, ray_t)) |hit_record| {
            if(temp_rec) |current_hit| {
                if (hit_record.t < current_hit.t) {
                    temp_rec = hit_record;
                }
            } else {
                temp_rec = hit_record;
            }
        }
    }
    return temp_rec;
}
