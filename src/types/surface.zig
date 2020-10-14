const wlr = @import("wlroots.zig");

const os = @import("std").os;

const pixman = @import("pixman");

const wayland = @import("wayland");
const wl = wayland.server.wl;

pub const Surface = extern struct {
    pub const State = extern struct {
        pub const field = struct {
            pub const buffer = 1 << 0;
            pub const surface_damage = 1 << 1;
            pub const buffer_damage = 1 << 2;
            pub const opaque_region = 1 << 3;
            pub const input_region = 1 << 4;
            pub const transform = 1 << 5;
            pub const scale = 1 << 6;
            pub const frame_callback_list = 1 << 7;
            pub const viewport = 1 << 8;
        };

        /// This is a bitfield of State.field members
        committed: u32,

        buffer_resource: ?*wl.Resource,
        dx: i32,
        dy: i32,
        surface_damage: pixman.Region32,
        buffer_damage: pixman.Region32,
        @"opaque": pixman.Region32,
        input: pixman.Region32,
        transform: wl.Output.Transform,
        scale: i32,
        frame_callback_list: wl.List,

        width: c_int,
        height: c_int,
        buffer_width: c_int,
        buffer_height: c_int,

        viewport: struct {
            has_src: bool,
            has_dst: bool,
            src: wlr.FBox,
            dst_width: c_int,
            dst_height: c_int,
        },

        buffer_destroy: wl.Listener,
    };

    pub const Role = extern struct {
        name: [*:0]const u8,
        commit: ?fn (surface: *Surface) callconv(.C) void,
        precommit: ?fn (surface: *Surface) callconv(.C) void,
    };

    resource: *wl.Resource,
    renderer: *wlr.Renderer,

    buffer: ?*wlr.ClientBuffer,

    sx: c_int,
    sy: c_int,

    buffer_damage: pixman.Region32,
    opaque_region: pixman.Region32,
    input_region: pixman.Region32,

    current: State,
    pending: State,
    previous: State,

    role: ?*const Role,
    role_data: ?*c_void,

    events: struct {
        commit: wl.Signal,
        new_subsurface: wl.Signal,
        destroy: wl.Signal,
    },

    /// Subsurface.parent_link
    subsurfaces: wl.List,
    /// Subsurface.parent_pending_link
    subsurface_pending_list: wl.List,

    renderer_destroy: wl.Listener,

    data: ?*c_void,

    extern fn wlr_surface_create(client: *wl.Client, version: u32, id: u32, renderer: *wlr.Renderer, resource_list: ?*wl.List) ?*Surface;
    pub const create = wlr_surface_create;

    extern fn wlr_surface_set_role(surface: *Surface, role: *const Role, role_data: ?*c_void, error_resource: ?*wl.Resource, error_code: u32) bool;
    pub const setRole = wlr_surface_set_role;

    extern fn wlr_surface_has_buffer(surface: *Surface) bool;
    pub const hasBuffer = wlr_surface_has_buffer;

    extern fn wlr_surface_get_texture(surface: *Surface) ?*wlr.Texture;
    pub const getTexture = wlr_surface_get_texture;

    extern fn wlr_surface_get_root_surface(surface: *Surface) ?*Surface;
    pub const getRootSurface = wlr_surface_get_root_surface;

    extern fn wlr_surface_point_accepts_input(surface: *Surface, sx: f64, sy: f64) bool;
    pub const pointAcceptsInput = wlr_surface_point_accepts_input;

    extern fn wlr_surface_surface_at(surface: *Surface, sx: f64, sy: f64, sub_x: *f64, sub_y: *f64) ?*Surface;
    pub const surfaceAt = wlr_surface_surface_at;

    extern fn wlr_surface_send_enter(surface: *Surface, output: *wlr.Output) void;
    pub const sendEnter = wlr_surface_send_enter;

    extern fn wlr_surface_send_leave(surface: *Surface, output: *wlr.Output) void;
    pub const sendLeave = wlr_surface_send_leave;

    extern fn wlr_surface_send_frame_done(surface: *Surface, when: *const os.timespec) void;
    pub const sendFrameDone = wlr_surface_send_frame_done;

    extern fn wlr_surface_get_extends(surface: *Surface, box: *wlr.Box) void;
    pub const getExtends = wlr_surface_get_extends;

    extern fn wlr_surface_from_resource(resource: *wl.Resource) ?*Surface;
    pub const fromResource = wlr_surface_from_resource;

    extern fn wlr_surface_for_each_surface(
        surface: *Surface,
        iterator: fn (surface: *Surface, sx: c_int, sy: c_int, data: ?*c_void) void,
        user_data: ?*c_void,
    ) void;
    pub fn forEachSurface(
        surface: *Surface,
        comptime T: type,
        iterator: fn (surface: *Surface, sx: c_int, sy: c_int, data: T) callconv(.C) void,
        data: T,
    ) void {
        wlr_surface_for_each_surface(surface, iterator, data);
    }

    extern fn wlr_surface_get_effective_damage(surface: *Surface, damage: *pixman.Region32) void;
    pub const getEffectiveDamage = wlr_surface_get_effective_damage;

    extern fn wlr_surface_get_buffer_source_box(surface: *Surface, box: *wlr.FBox) void;
    pub const getBufferSourceBox = wlr_surface_get_buffer_source_box;
};

pub const Subsurface = extern struct {
    pub const State = extern struct {
        x: i32,
        y: i32,
    };

    resource: *wl.Resource,
    surface: *Surface,
    parent: ?*Surface,

    current: State,
    pending: State,

    cached: Surface.State,
    has_cache: bool,

    synchronized: bool,
    reordered: bool,
    mapped: bool,

    /// Surface.subsurfaces
    parent_link: wl.List,
    /// Surface.subsurface_pending_list
    parent_pending_link: wl.List,

    surface_destroy: wl.Listener,
    parent_destroy: wl.Listener,

    events: struct {
        destroy: wl.Signal,
        map: wl.Signal,
        unmap: wl.Signal,
    },

    data: ?*c_void,

    extern fn wlr_subsurface_create(surface: *Surface, parent: *Surface, version: u32, id: u32, resource_list: ?*wl.List) ?*Subsurface;
    pub const create = wlr_subsurface_create;
};