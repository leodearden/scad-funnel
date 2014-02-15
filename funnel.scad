use <hose/hose_tail.scad>;
include <gear-mother-mold.scad>;

funnel_mouth_r = 70/2;

rim_hole_r = 6/2;

drain_r = 2.5/2;

chamber_wall_t = 8;

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
flange_or = funnel_mouth_r + horizontal_wall_t + 2 * (chamber_wall_t + rim_hole_r);

module funnel_inside(mouth_r, throat_r, tip = true) {
	funnel_h = funnel_hight(mouth_r, throat_r);
	tip_h = tip ? horizontal_wall_t : 0;
	translate([0, 0, -eps]) union() {
		cylinder(r1 = mouth_r, r2 = throat_r, h = funnel_hight(mouth_r, throat_r) + eps2);
		if(tip) {
			translate([0, 0, funnel_h]) cylinder(r = throat_r, h = tip_h + eps2, $fn = 15);
		}
	}
}

//funnel_inside(funnel_mouth_r, hose_tail_ir(feed_id, hose_tail_default_stretch(), min_wall_t));

module funnel_outside(mouth_r, throat_r, flange_t = chamber_wall_t, tip = true) {
	funnel_h = funnel_hight(mouth_r, throat_r);
	tip_h = tip ? horizontal_wall_t : 0;
	union() {
		// Outside of cone
		cylinder(r1 = mouth_r + horizontal_wall_t,
		         r2 = tip ? throat_r : throat_r + horizontal_wall_t,
		         h = funnel_h + tip_h);
		// Rim
		circular_bolting_flange(flange_or, flange_t);
	}
}

module funnel(mouth_r, throat_r, flange_t = chamber_wall_t, tip = true) {
	difference() {
		funnel_outside(mouth_r, throat_r, flange_t, tip);
		funnel_inside(mouth_r, throat_r, tip);
	}
}

//funnel(funnel_mouth_r, hose_tail_ir(feed_id, hose_tail_default_stretch(), min_wall_t), 2 * chamber_wall_t );

module funnel_with_tail() {
       	throat_r = hose_tail_ir(feed_id, hose_tail_default_stretch(), min_wall_t);
	funnel(funnel_mouth_r, throat_r, chamber_wall_t);
       	translate([0, 0, funnel_hight(funnel_mouth_r, throat_r)]) {
		hose_tail(feed_id, feed_tail_h, min_wall_t);
	}
}

//funnel_with_tail();

duct_ir = hose_tail_min_or(feed_id, hose_tail_default_stretch()) - min_wall_t;
// rs^2 = rd^2 + (rs - hd)^2
//      = rd^2 + rs^2 - 2rs.hd + hd^2
//: rs  = (rd^2 + hd^2)/2hd
module dome_top() {
	dome_h = 25;
	dome_r = flange_or - 2 * (rim_hole_r + chamber_wall_t);
	dome_sphere_r = (pow(dome_r, 2) + pow(dome_h, 2))/(2 * dome_h);
	difference() {
		union() {
			circular_bolting_flange(flange_or);
			intersection() {
				translate([0, 0, dome_h - dome_sphere_r]) sphere(r = dome_sphere_r);
				cylinder(r = dome_r + eps, h = dome_h);
			}
			translate([0, 0, dome_h]) {
				translate([0, -dome_r * 2/3, 0]) {
					rotate([90, 0, 0]) {
						hose_tail(feed_id, feed_tail_h, min_wall_t);
					}
					rotate([-90, 0, 0]) {
						cylinder(r = hose_tail_min_or(feed_id, hose_tail_default_stretch()), h = dome_r * 2/3);
					}
				}
				sphere(r = hose_tail_min_or(feed_id, hose_tail_default_stretch()));
			}
		}
		translate([0, 0, dome_h - dome_sphere_r]) {
			sphere(r = dome_sphere_r - chamber_wall_t);
		}
		translate([0, 0, dome_h]) {
			sphere(r = duct_ir);
			rotate([-180, 0, 0]) cylinder(r = duct_ir, h = duct_ir + chamber_wall_t);
			translate([0, -dome_r * 2/3, 0]) {
				rotate([-90, 0, 0]) {
					translate([0, 0, -eps]) {
						cylinder(r = duct_ir, h = dome_r * 2/3 + eps2);
					}
				}
			}
		}
	}
}

//dome_top();

spacer_h = 8;
module flange_spacer() {
	difference() {
		circular_bolting_flange(flange_or, spacer_h);
		translate([0, 0, -eps]) {
			cylinder(r = flange_bolt_circle_r(flange_or), h = spacer_h + eps2);
			translate([-flange_or - eps, 0, 0]) {
				cube([2 * (flange_or + eps), flange_or  + eps, spacer_h + eps2]);
			}
			// pull appart notch
			translate([flange_or - rim_hole_r, 0 ,0]) {
				rotate([0, 0, -45]) cube([2*rim_hole_r, 2*rim_hole_r, spacer_h + eps2]);
			}
		}
	}
}

//flange_spacer();

degasser_h = funnel_hight(funnel_mouth_r, drain_r) + horizontal_wall_t;
module degasser() {
	overlap = 0.5;
	fudge = 5;
	union() {
		translate([0, 0, degasser_h]) rotate([180, 0, 0]) {
			funnel(funnel_mouth_r, drain_r, flange_t = degasser_h * (1 - overlap) + eps);
		}
		difference() {
			funnel_outside(funnel_mouth_r, drain_r, flange_t = degasser_h * (1 - overlap) + eps);
			funnel_inside(funnel_mouth_r, drain_r, flange_t = degasser_h * (1 - overlap) + eps);
			translate([0, 0, degasser_h + eps]) {
				rotate([180, 0, 0]) {
					cylinder(r = flange_or + eps, h = degasser_h * (1 - overlap) + eps);
				}
			}
			translate([0, 0, feed_id/2 + chamber_wall_t]) {
				rotate([90, 0, 0]) cylinder(r = duct_ir, h = flange_or + eps);
			}
		}
		translate([0, -flange_or + fudge, feed_id/2 + chamber_wall_t]) {
			rotate([90, 0, 0]) hose_tail(feed_id, feed_tail_h, min_wall_t);
		}
	}
}

//degasser();

module feed_chamber_assembly() {
	%rotate([180, 0, 0]) funnel_with_tail();
	#flange_spacer();
	rotate([0, 0, 180]) #flange_spacer();
	translate([0, 0, spacer_h]) {
		degasser();
		translate([0, 0, degasser_h]) {
			%dome_top();
		}
	}
}

//feed_chamber_assembly();