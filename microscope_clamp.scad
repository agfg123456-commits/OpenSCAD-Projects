// =====================================================================
//  Handheld digital microscope -> boom arm clamp
//  Split ring clamp (one M3 bolt) + rear arm + single fork tab.
//  All units mm.
//
//  Coordinate system (as printed):
//    Z  up. Ring sits flat on the bed at z = 0, tab points up.
//    Y  front/back. Scope front (split + bolt ears) is toward -Y,
//       the scope's flat back is toward +Y and the arm runs out along +Y.
//    X  left/right. The split plane and the tab plate are both on x = 0
//       (the plane through the scope's centerline).
//    y = 0 is the scope's flat back BODY surface (no clearance added).
//    The flat back is taken as vertical (same plane top and bottom);
//    the 1.5 mm of depth taper therefore all shows up at the front.
// =====================================================================

/* [Mode] */
test_slice      = false;  // true: only ring + ears, 5 tall, bottom profile

/* [Scope body profile (D shape)] */
band_height     = 20.5;   // clear band on the scope body (reference only)
body_w_bottom   = 46.3;   // side-to-side width at bottom of band
body_d_bottom   = 48.5;   // depth, front of oval to flat back, at bottom
body_w_top      = 48.0;   // width at top of band
body_d_top      = 50.0;   // depth at top of band
body_flat       = 25.0;   // width of the flat back (same top and bottom)
fit_clearance   = 0.3;    // bore is offset outward from the body by this

/* [Ring] */
clamp_height    = 20;     // ring height (band is 20.5)
wall            = 4;      // ring wall thickness, follows the D shape
split_gap       = 3;      // split at front center, full height

/* [Bolt ears] */
ear_thickness   = 8;      // each ear, in X (>= 6)
ear_out         = 10;     // how far the ears stick out past the ring front
bolt_len        = 16;     // M3 x 16 socket head cap screw (under head)
bolt_hole       = 3.4;    // M3 clearance
cb_dia          = 6.2;    // counterbore for socket head
cb_depth        = 3.2;
head_height     = 3.0;    // M3 SHCS head height (check only)
nut_af          = 5.8;    // nut pocket across flats (M3 nut is 5.5)
nut_depth       = 2.6;    // nut pocket depth
nut_thick       = 2.4;    // M3 nut thickness (check only)

/* [Arm and tab] */
arm_width       = 12;     // arm, left to right
tab_thickness   = 5.4;    // EXACT - slides into the boom arm fork
tab_offset      = 55;     // hole center behind the scope's flat back surface
tab_hole_height = 18.5;   // hole center above top face of clamp / arm
tab_hole        = 6.2;    // fork screw hole diameter
tab_width_base  = 23;     // front-to-back width where tab meets arm
tab_width_hole  = 20;     // front-to-back width at hole height
tab_fillet      = 3;      // fillet radius, tab sides to arm top
arm_fillet      = 4;      // fillet radius, arm sides to ring flat back

/* [Printing] */
use_teardrops   = true;   // horizontal holes get a 45 deg pointed top
teardrop_cap    = 1.25;   // truncate the teardrop point at this x radius

/* [Resolution] */
ellipse_segs    = 240;    // points on each profile ellipse
$fn             = 64;     // round features (holes, fillets)

/* [Hidden] */
eps = 0.01;

// ---------------------------------------------------------------------
//  Profile maths
//  Ellipse semi-axes a = W/2 (X), b (Y). A straight flat cuts the back of
//  the ellipse at distance y0 behind its center. For the flat to be F
//  wide:   y0/b = sqrt(1 - (F/W)^2)
//  Depth front-of-ellipse to flat:  D = b + y0
//  =>      b = D / (1 + sqrt(1 - (F/W)^2))
// ---------------------------------------------------------------------
function ell_k(W, F)    = sqrt(1 - pow(F / W, 2));   // y0 / b
function ell_b(W, D, F) = D / (1 + ell_k(W, F));
function ell_y0(W, D, F)= ell_b(W, D, F) * ell_k(W, F);

// Linear taper of the body: W and D at height z of the ring
hc = test_slice ? 5 : clamp_height;
function W_at(z) = test_slice ? body_w_bottom
                 : body_w_bottom + (body_w_top - body_w_bottom) * z / clamp_height;
function D_at(z) = test_slice ? body_d_bottom
                 : body_d_bottom + (body_d_top - body_d_bottom) * z / clamp_height;

// Report semi-axes
b_bot  = ell_b (body_w_bottom, body_d_bottom, body_flat);
y0_bot = ell_y0(body_w_bottom, body_d_bottom, body_flat);
b_top  = ell_b (body_w_top,    body_d_top,    body_flat);
y0_top = ell_y0(body_w_top,    body_d_top,    body_flat);
echo(str("BOTTOM profile: a (side/side) = ", body_w_bottom / 2,
         "  b (front/back) = ", b_bot, "  flat is ", y0_bot,
         " behind ellipse center  (b + y0 = ", b_bot + y0_bot, ")"));
echo(str("TOP    profile: a (side/side) = ", body_w_top / 2,
         "  b (front/back) = ", b_top, "  flat is ", y0_top,
         " behind ellipse center  (b + y0 = ", b_top + y0_top, ")"));

// ---------------------------------------------------------------------
//  Derived positions
// ---------------------------------------------------------------------
ring_back_y   = fit_clearance + wall;              // outer flat back of ring
ring_front_mid= -(D_at(hc / 2) + fit_clearance + wall); // outer front, mid height
ear_tip_y     = ring_front_mid - ear_out;
bolt_y        = ring_front_mid - ear_out / 2;
bolt_z        = hc / 2;
ear_x_in      = split_gap / 2;
ear_x_out     = split_gap / 2 + ear_thickness;

tab_z0        = clamp_height;                      // top face of arm
tab_hole_z    = tab_z0 + tab_hole_height;
tab_r         = tab_width_hole / 2;                // top radius, concentric
tab_back_y    = tab_offset + tab_r;                // straight vertical back edge
tab_front_hole_y = tab_back_y - tab_width_hole;    // front edge at hole height
tab_front_base_y = tab_back_y - tab_width_base;    // front edge at base
function tab_front_y(z) = tab_front_base_y
    + (tab_front_hole_y - tab_front_base_y) * (z - tab_z0) / tab_hole_height;

// Bolt stack check (measured from the nut ear's gap face)
bolt_end      = bolt_len - (ear_thickness - cb_depth) - split_gap;
nut_far_face  = ear_thickness - nut_depth + nut_thick;
echo(str("BOLT: stack ears+gap = ", 2 * ear_thickness + split_gap,
         ", M3x", bolt_len, " tip lands ", bolt_end - ear_thickness,
         " past nut-ear outer face (nut far face at ", nut_far_face - ear_thickness,
         "). If the gap closes fully the tip protrudes ", bolt_end + split_gap - ear_thickness));
echo(str("TAB: hole at y=", tab_offset, " z=", tab_hole_z,
         "; tab spans y ", tab_front_base_y, "..", tab_back_y, " at base, ",
         tab_front_hole_y, "..", tab_back_y, " at hole height"));

assert(ear_thickness >= 6, "ears must be at least 6 thick");
assert(bolt_end >= nut_far_face, "bolt too short to pass fully through the nut");
assert(bolt_end - ear_thickness <= 2, "bolt protrudes more than 2 mm past nut ear");
assert(cb_depth >= head_height, "counterbore shallower than bolt head");
assert(arm_width / 2 + arm_fillet <= body_flat / 2,
       "arm + fillets wider than the ring's flat back");
assert(tab_thickness / 2 + tab_fillet <= arm_width / 2,
       "tab fillets overhang the arm");
assert(tab_front_base_y > ring_back_y, "tab runs into the ring");
assert(clamp_height <= band_height, "clamp taller than the clear band");

// ---------------------------------------------------------------------
//  2D: D profile with flat back on y = 0, front toward -Y
// ---------------------------------------------------------------------
module d_profile(W, D, F) {
    a  = W / 2;
    b  = ell_b(W, D, F);
    y0 = ell_y0(W, D, F);
    p0 = asin(y0 / b);               // param angle at the right flat corner
    sweep = 180 + 2 * p0;            // round the front to the left corner
    polygon([for (i = [0 : ellipse_segs])
                let (t = p0 - sweep * i / ellipse_segs)
                [a * cos(t), -y0 + b * sin(t)]]);
}

// Thin slice of the profile at height z, grown by g
module profile_slice(z, g) {
    translate([0, 0, z])
        linear_extrude(height = eps)
            offset(r = g) d_profile(W_at(z), D_at(z), body_flat);
}

// Tapered solid of the profile grown by g, from z0 to z1
module tapered(z0, z1, g) {
    hull() {
        profile_slice(z0, g);
        profile_slice(z1 - eps, g);
    }
}

// ---------------------------------------------------------------------
//  Printing helpers: horizontal holes along X
// ---------------------------------------------------------------------
module teardrop2d(r) {
    if (use_teardrops) {
        intersection() {
            union() {
                circle(r = r);
                rotate(45) square(r);              // point toward +v
            }
            translate([-r - 1, -r - 1]) square([2 * r + 2, r + 1 + teardrop_cap * r]);
        }
    } else {
        circle(r = r);
    }
}

// 2D (u, v) -> world (y, z), extruded along X from x0 to x1
module along_x(x0, x1) {
    translate([x0, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(height = x1 - x0) children();
}

// ---------------------------------------------------------------------
//  Parts
// ---------------------------------------------------------------------
module ring_outer() {
    tapered(0, hc, fit_clearance + wall);
}

module bore() {
    tapered(-1, hc + 1, fit_clearance);
}

module ears() {
    y_back = -D_at(0) * 0.6;   // starts well inside the bore; bore trims it
    for (s = [-1, 1])
        translate([s > 0 ? ear_x_in : -ear_x_out, ear_tip_y, 0])
            cube([ear_thickness, y_back - ear_tip_y, hc]);
}

module bolt_cuts() {
    // clearance hole through both ears
    along_x(-ear_x_out - 1, ear_x_out + 1)
        translate([bolt_y, bolt_z]) teardrop2d(bolt_hole / 2);
    // counterbore for the socket head, -X ear
    along_x(-ear_x_out - 1, -ear_x_out + cb_depth)
        translate([bolt_y, bolt_z]) teardrop2d(cb_dia / 2);
    // hex nut pocket, +X ear. Full part: vertex up (30 deg roof, no
    // support or bridge). Test slice: flats horizontal so the clipped
    // pocket still keys the nut against turning.
    along_x(ear_x_out - nut_depth, ear_x_out + 1)
        translate([bolt_y, bolt_z])
            rotate(test_slice ? 0 : 90)
                circle(r = nut_af / 2 / cos(30), $fn = 6);
}

module split_cut() {
    translate([-split_gap / 2, ear_tip_y - 1, -1])
        cube([split_gap, -ear_tip_y + 1 - D_at(0) * 0.6, hc + 2]);
}

module arm() {
    y0 = fit_clearance + wall / 2;           // starts inside the ring wall
    translate([-arm_width / 2, y0, 0])
        cube([arm_width, tab_back_y - y0, clamp_height]);
    // vertical fillets, arm sides to ring flat back
    for (m = [0, 1]) mirror([m, 0, 0])
        linear_extrude(height = clamp_height)
            difference() {
                translate([arm_width / 2 - eps, ring_back_y - eps])
                    square([arm_fillet + eps, arm_fillet + eps]);
                translate([arm_width / 2 + arm_fillet, ring_back_y + arm_fillet])
                    circle(r = arm_fillet);
            }
}

module tab_profile2d() {
    // (u, v) = (y, z)
    zb = tab_z0 - 1;                          // sink into the arm
    union() {
        polygon([[tab_front_y(zb), zb],
                 [tab_back_y,      zb],
                 [tab_back_y,      tab_hole_z],
                 [tab_front_hole_y, tab_hole_z]]);
        translate([tab_offset, tab_hole_z]) circle(r = tab_r, $fn = 96);
    }
}

module tab() {
    difference() {
        along_x(-tab_thickness / 2, tab_thickness / 2) tab_profile2d();
        along_x(-tab_thickness / 2 - 1, tab_thickness / 2 + 1)
            translate([tab_offset, tab_hole_z]) teardrop2d(tab_hole / 2);
    }
    // fillets, tab sides to arm top, running front to back
    yf = tab_front_y(tab_z0 + tab_fillet);
    for (m = [0, 1]) mirror([m, 0, 0])
        translate([0, tab_back_y, 0]) rotate([90, 0, 0])
            linear_extrude(height = tab_back_y - yf)
                difference() {
                    translate([tab_thickness / 2 - eps, tab_z0 - eps])
                        square([tab_fillet + eps, tab_fillet + eps]);
                    translate([tab_thickness / 2 + tab_fillet, tab_z0 + tab_fillet])
                        circle(r = tab_fillet);
                }
}

// ---------------------------------------------------------------------
//  Assembly
// ---------------------------------------------------------------------
module clamp() {
    difference() {
        union() {
            ring_outer();
            ears();
            if (!test_slice) arm();
        }
        bore();
        split_cut();
        bolt_cuts();
    }
    if (!test_slice) tab();
}

clamp();
