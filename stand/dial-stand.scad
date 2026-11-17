// Desk stand for the Waveshare ESP32-S3-Touch-AMOLED-1.75C (the one in the round aluminum case).
//
// The dial sits in a shallow cup, tilted back, with its USB-C port facing down. The plug goes straight down a
// slot into the hollow pedestal, and the cable bends inside and leaves through a slot in the back of the base.
// Nothing but the dial shows from the front.
//
// Case size from Waveshare's drawing: 55.00 mm across, 15.05 mm thick, glass 48.96 mm across.
// To fit it: thread the cable up from under the base, through the slot, plug it in, then set the dial in the cup.
//
// Printing: as modeled, base down. PLA or PETG, 0.2 mm layers, 3 walls, 15 % infill. The roof inside the
// pedestal is a short bridge; supports only if the printer bridges poorly.

/* [Dial] */
dial_d     = 55.00;   // case diameter
dial_t     = 15.05;   // case thickness
clearance  = 0.4;     // gap around the case; raise to 0.6 if it is tight

/* [Stand] */
tilt       = 15;      // degrees the dial leans back
lift       = 55;      // height of the dial's bottom edge above the desk (room for a straight USB-C plug)
wall       = 2.4;
lip        = 2.2;     // how far the front lip reaches in over the bezel (the glass starts 3 mm in)
lip_t      = 2.0;     // front lip thickness
wrap       = 42;      // degrees the cup climbs each side of the port; above ~48 it would hit the lower button
back_h     = 30;      // how far up the back the support tab reaches
slot       = [18, 12];// plug slot: along the rim, through the thickness
plug_len   = 30;      // rigid part of the plug below the dial
cable_w    = 6.5;     // cable slot in the base
base       = [72, 84, 5];

$fn = 160;
R  = dial_d / 2;
Rc = R + clearance;
T  = dial_t + clearance;
e  = 0.01;

// ── the cup, in the dial's own frame: front face at y = 0, back at y = T, bottom of the case at z = 0 ──────────

module disc(r, y0, y1) { translate([0, y0, Rc]) rotate([-90, 0, 0]) cylinder(r = r, h = y1 - y0); }

module wedge(deg) {
    L = 3 * R;
    rotate([90, 0, 0]) linear_extrude(height = 200, center = true)
        polygon([[0, Rc], [-L * sin(deg), Rc - L * cos(deg)], [0, Rc - L], [L * sin(deg), Rc - L * cos(deg)]]);
}

module cup_solid() {
    intersection() {
        disc(Rc + wall, -lip_t, T + wall);
        wedge(wrap);
    }
    // The tab the dial leans on.
    hull() {
        translate([-14, T, 0]) cube([28, wall, e]);
        translate([0, T, back_h - 10]) rotate([-90, 0, 0]) cylinder(r = 10, h = wall);
    }
    // The tube around the plug slot.
    translate([-slot[0] / 2 - wall, T / 2 - slot[1] / 2 - wall, -plug_len])
        cube([slot[0] + 2 * wall, slot[1] + 2 * wall, plug_len + Rc * 0.2]);
}

module cup_void() {
    disc(Rc, 0, T);                          // the case
    disc(Rc - lip - clearance, -lip_t - 1, e);   // the window in the front lip
    translate([-slot[0] / 2, T / 2 - slot[1] / 2, -plug_len - 2]) cube([slot[0], slot[1], plug_len + 2 + Rc]);
}

module tilted() { translate([0, 0, lift]) rotate([-tilt, 0, 0]) children(); }

// ── the pedestal and base, in desk coordinates ───────────────────────────────────────────────────────────

ped   = [slot[0] + 2 * wall + 4, 34];   // outside, x by y
ped_y = -12;                             // its front edge
roof  = lift - 14;                       // top of the hollow inside

module rounded(size, r) {
    hull() for (x = [r, size[0] - r], y = [r, size[1] - r]) translate([x, y, 0]) cylinder(r = r, h = size[2]);
}

module body() {
    tilted() cup_solid();
    translate([-ped[0] / 2, ped_y, 0]) rounded([ped[0], ped[1], lift - 3], 3);
    translate([-base[0] / 2, ped_y - 14, 0]) rounded(base, 10);
}

module voids() {
    tilted() cup_void();
    // The hollow inside the pedestal, open underneath.
    translate([-ped[0] / 2 + wall, ped_y + wall, -e]) cube([ped[0] - 2 * wall, ped[1] - 2 * wall, roof]);
    // The cable's way out: through the back wall and along the base to its back edge.
    translate([-cable_w / 2, ped_y + wall, -e]) cube([cable_w, 200, 9]);
}

module stand() difference() {
    body();
    voids();
}

stand();
