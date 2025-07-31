const std = @import("std");

pub const Vec3 = @Vector(3, f64);
pub const Color = Vec3;

pub const color_zero: Color = .{ 0.0, 0.0, 0.0 };
pub const color_one: Color = .{ 1.0, 1.0, 1.0 };

pub threadlocal var rand_state = std.Random.DefaultPrng.init(69);

pub fn gammaCorrection(color: Color) Color {
    return .{
        gammaCorrectionComponent(color[0]),
        gammaCorrectionComponent(color[1]),
        gammaCorrectionComponent(color[2]),
    };
}

fn gammaCorrectionComponent(value: f64) f64 {
    return if (value > 0.0)  std.math.sqrt(value)  else  0.0;
}

pub fn randomRange(min: f64, max: f64) Vec3 {
    const rand = rand_state.random();
    const range = (max - min) + min;
    return .{ rand.float(f64) * range, rand.float(f64) * range, rand.float(f64) * range };
}

pub fn randomUnitVector() Vec3 {
    while (true) {
        const p = randomRange(-1.0, 1.0);
        const lensq = lengthSquared(p);
        if (1e-160 < lensq and lensq <= 1.0) {
            return p / splat(std.math.sqrt(lensq));
        }
    }
}

pub fn sampleSquare() Vec3 {
    const rand = rand_state.random();
    return .{ rand.float(f64) - 0.5, rand.float(f64) - 0.5, 0.0 };
}

pub fn length(v: Vec3) f64 {
    return @sqrt(lengthSquared(v));
}

pub fn lengthSquared(v: Vec3) f64 {
    return @reduce(.Add, v * v);
}

pub fn nearZero(v: Vec3) bool {
    const s: f64 = 1e-8;
    return @reduce(.And, @abs(v) < splat(s));
}

pub fn randomOnHemisphere(normal: Vec3) Vec3 {
    const on_unit_sphere = randomUnitVector();
    return if (dot(on_unit_sphere, normal) > 0.0)
        on_unit_sphere
    else
        -on_unit_sphere;
}

pub fn splat(value: anytype) Vec3 {
    return switch (@typeInfo(@TypeOf(value))) {
        .int, .comptime_int, .float, .comptime_float => @splat(value),
        inline else => @compileError("Invalid type passed into splat, expected ints or floats, got: " ++ @typeName(@TypeOf(value))),
    };
}

pub fn reflect(v: Vec3, normal: Vec3) Vec3 {
    return v - splat(2 * dot(v, normal)) * normal;
}

pub fn dot(lhs: Vec3, rhs: Vec3) f64 {
    return @reduce(.Add, lhs * rhs);
}

pub const Interval = struct {
    min: f64,
    max: f64,

    pub const empty = .{ .min = std.math.inf(f64), .max = -std.math.inf(f64) };

    pub fn init(min: f64, max: f64) Interval {
        return .{ .min = min, .max = max };
    }

    pub fn size(self: Interval) f64 {
        return self.max - self.min;
    }

    pub fn contains(self: Interval, x: f64) bool {
        return self.min <= x and x <= self.max;
    }

    pub fn surrounds(self: Interval, x: f64) bool {
        return self.min < x and x < self.max;
    }

    pub fn clamp(self: Interval, x: f64) f64 {
        return x.clamp(self.min, self.max);
    }
};
