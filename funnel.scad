include <scad-hose/hose-tail.scad>;

rim_hole_r = 6/2;

drain_r = 2.5/2;

chamber_wall_t = 4;

function funnel_hight(mouth_r, throat_r) = mouth_r - throat_r;

function flange_bolt_circle_r(or) = or - chamber_wall_t - rim_hole_r;

module circular_bolting_flange( or, flange_t = chamber_wall_t, bolt_hole_r = rim_hole_r, holes_n = 6 ) {
	difference() {
		cylinder(r = or, h = flange_t);
		for( a = [0 : 360/holes_n : 360]) {
			rotate([0, 0, a]) {
				translate([flange_bolt_circle_r(or), 0, -eps]) {
					cylinder( r = bolt_hole_r, h = flange_t + eps2);
				}
			}
		}
	}
}

horizontal_wall_t = sqrt(2) * chamber_wall_t;

module funnel_inside(mouth_r, throat_r, tip = true) {
	funnel_h = funnel_hight(mouth_r, throat_r);
	tip_h = tip ? horizontal_wall_t : 0;
	translate([0, 0, -eps]) union() {
		cylinder(r2 = mouth_r, r1 = throat_r, h = funnel_hight(mouth_r, throat_r) + eps2);
		if(tip) {
			translate([0, 0, -tip_h]) cylinder(r = throat_r, h = tip_h + eps2, $fn = 15);
		}
	}
}

//funnel_inside(funnel_mouth_r, hose_tail_ir(feed_id, hose_tail_default_stretch(), min_wall_t));

module funnel_outside(mouth_r, throat_r, flange_t = chamber_wall_t, tip = true) {
	funnel_h = funnel_hight(mouth_r, throat_r);
	flange_or = mouth_r + horizontal_wall_t + 2 * (chamber_wall_t + rim_hole_r);
	tip_h = tip ? horizontal_wall_t : 0;
	union() {
		// Outside of cone
		cylinder(r2 = mouth_r + horizontal_wall_t,
		         r1 = tip ? throat_r : throat_r + horizontal_wall_t,
		         h = funnel_h + tip_h);
		if(flange_t) {
			// Rim
			translate([0, 0, funnel_h - flange_t]) {
				circular_bolting_flange(flange_or, flange_t);
			}
		}
	}
}

// FIXME: tip = true is broken.
module funnel(mouth_r, throat_r, flange_t = 0, tip = false) {
	difference() {
		funnel_outside(mouth_r, throat_r, flange_t, tip);
		funnel_inside(mouth_r, throat_r, tip);
	}
}

//funnel(mouth_r = 70/2, throat_r = 16/2, flange_t = 0, tip = false);
//funnel(mouth_r = 70/2, throat_r = 16/2, tip = false);
//funnel(mouth_r = 70/2, throat_r = 16/2);

// FIXME: is broken by funnel inversion.
module funnel_with_tail(mouth_r, feed_id, feed_tail_h) {
	throat_r = hose_tail_ir(feed_id, hose_tail_default_stretch(), chamber_wall_t);
	funnel(mouth_r, throat_r, chamber_wall_t);
		translate([0, 0, funnel_hight(mouth_r, throat_r)]) {
			hose_tail(feed_id, feed_tail_h, chamber_wall_t);
	}
}

//funnel_with_tail(mouth_r = 70/2, feed_id = 16, feed_tail_h = 25);
