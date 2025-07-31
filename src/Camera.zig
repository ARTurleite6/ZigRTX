const std = @import("std");

const math = @import("math.zig");
const Interval = math.Interval;
const Vec3 = math.Vec3;
const Color = math.Color;
const Ray = @import("Ray.zig");
const World = @import("World.zig");

const Camera = @This();

image_width: usize,
image_height: usize,
center: Vec3,
pixel00_loc: Vec3,
pixel_delta_u: Vec3,
pixel_delta_v: Vec3,
max_depth: u32,

pub fn init(aspect_ratio: f64, image_width: usize) Camera {
    const image_height = blk: {
        const image_height: usize = @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio);
        break :blk (if (image_height < 1) 1 else image_height);
    };

    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width = viewport_height * (@as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height)));
    const center: Vec3 = .{ 0.0, 0.0, 0.0 };

    const viewport_u: Vec3 = .{ viewport_width, 0.0, 0.0 };
    const viewport_v: Vec3 = .{ 0.0, -viewport_height, 0.0 };
    const pixel_delta_u = viewport_u / math.splat(@as(f64, @floatFromInt(image_width)));
    const pixel_delta_v = viewport_v / math.splat(@as(f64, @floatFromInt(image_height)));

    const viewport_upper_left =
        center - Vec3{ 0.0, 0.0, focal_length } - viewport_u / math.splat(2.0) - viewport_v / math.splat(2.0);
    const pixel00_loc = viewport_upper_left + math.splat(0.5) * (pixel_delta_u + pixel_delta_v);

    return .{
        .image_width = image_width,
        .image_height = image_height,
        .center = center,
        .pixel00_loc = pixel00_loc,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
        .max_depth = 50,
    };
}

pub fn render(self: Camera, gpa: std.mem.Allocator, world: World, samples_per_pixel: usize) !void {
    const stdout = std.io.getStdOut().writer();

    const image_data: [][3]u8 = try gpa.alloc([3]u8, self.image_width * self.image_height);
    defer gpa.free(image_data);

    const progress = std.Progress.start(.{ .root_name = "Raytracing", .estimated_total_items = 2 });
    defer progress.end();

    {
        const generation_progress = progress.start("Generating image", self.image_height);
        defer generation_progress.end();

        var pool: std.Thread.Pool = undefined;
        try pool.init(.{ .allocator = gpa });
        defer pool.deinit();

        var wg: std.Thread.WaitGroup = .{};
        defer pool.waitAndWork(&wg);

        for (0..self.image_height) |j| {
            pool.spawnWg(&wg, completeRow, .{ self, j, world, image_data, samples_per_pixel, generation_progress });
        }
    }

    const writing_progress = progress.start("Writing image to file", image_data.len);
    defer writing_progress.end();
    try stdout.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height });
    var buffered_writer = std.io.bufferedWriter(stdout);
    var buffer: [1024]u8 = undefined;
    for (image_data) |pixel| {
        defer writing_progress.completeOne();
        const message = try std.fmt.bufPrint(
            buffer[0..],
            "{} {} {}\n",
            .{
                pixel[0],
                pixel[1],
                pixel[2],
            },
        );
        _ = try buffered_writer.write(message);
    }
    try buffered_writer.flush();
}

fn completeRow(self: Camera, j: usize, world: World, out: [][3]u8, samples_per_pixel: usize, progress_bar: std.Progress.Node) void {
    defer progress_bar.completeOne();
    const pixel_samples_scale = 1.0 / @as(f64, @floatFromInt(samples_per_pixel));
    for (0..self.image_width) |i| {
        var pixel_color = math.color_zero;
        for (0..samples_per_pixel) |_| {
            pixel_color += self.per_pixel(i, j, world);
        }
        pixel_color *= math.splat(pixel_samples_scale);
        pixel_color = math.gammaCorrection(pixel_color);
        out[j * self.image_width + i] = .{
            @intFromFloat(pixel_color[0] * 255.999),
            @intFromFloat(pixel_color[1] * 255.999),
            @intFromFloat(pixel_color[2] * 255.999),
        };
    }
}

fn get_ray(self: Camera, x: usize, y: usize) Ray {
    const offset = math.sampleSquare();
    const pixel_sample = self.pixel00_loc + ((math.splat(@as(f64, @floatFromInt(x)) + offset[0])) * self.pixel_delta_u) + ((math.splat(@as(f64, @floatFromInt(y)) + offset[1])) * self.pixel_delta_v);

    const ray_origin = self.center;
    return Ray.init(ray_origin, pixel_sample - ray_origin);
}

fn per_pixel(self: Camera, x: usize, y: usize, world: World) Color {
    var light = math.color_zero;
    var contribution = math.color_one;
    var ray = self.get_ray(x, y);
    for (0..self.max_depth) |_| {
        if (world.hit(ray, Interval.init(0.0, std.math.inf(f64)))) |hit_record| {
            if (hit_record.material.scatter(ray, hit_record)) |scatter| {
                contribution *= scatter.attenuation;
                ray = scatter.scattered_ray;
            } else {
                break;
            }
        } else {
            light += Color{ 0.5, 0.7, 1.0 } * contribution;
            break;
        }
    }
    return light;
}
