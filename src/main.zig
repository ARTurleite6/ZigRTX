const std = @import("std");

const Camera = @import("Camera.zig");
const math = @import("math.zig");
const Vec3 = math.Vec3;
const Sphere = @import("Sphere.zig");
const Material = Sphere.Material;
const World = @import("World.zig");

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();
    var world = try World.init(gpa);
    defer world.deinit();

    const material_ground = Material{ .lambertian = .{ .albedo = .{ 0.8, 0.8, 0.0 } } };
    const material_center = Material{
        .lambertian = .{ .albedo = .{ 0.1, 0.2, 0.5 } },
    };
    const material_left = Material{
        .metal = .{ .albedo = .{ 0.8, 0.8, 0.8 } },
    };
    const material_right = Material{
        .metal = .{ .albedo = .{ 0.8, 0.6, 0.2 } },
    };

    try world.addSphere(Sphere.init(
        .{ 0.0, -100.5, -1.0 },
        100.0,
        material_ground,
    ));
    try world.addSphere(Sphere.init(.{ 0.0, 0.0, -1.2 }, 0.5, material_center));
    try world.addSphere(Sphere.init(.{ -1.0, 0.0, -1.0 }, 0.5, material_left));
    try world.addSphere(Sphere.init(.{ 1.0, 0.0, -1.0 }, 0.5, material_right));

    const camera = Camera.init(1.0, 800);
    try camera.render(gpa, world, 100);
}
