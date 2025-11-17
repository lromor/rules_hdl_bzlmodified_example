load("@rules_hdl//gds_write:build_defs.bzl", "gds_write")
load("@rules_hdl//place_and_route:build_defs.bzl", "place_and_route")
load("@rules_hdl//synthesis:build_defs.bzl", "synthesize_rtl")
load("@rules_hdl//verilog:providers.bzl", "verilog_library")

verilog_library(
    name = "adder_system_verilog_lib",
    srcs = [
        ":adder.sv",
    ],
)

synthesize_rtl(
    name = "adder_synth_sky130",
    top_module = "adder",
    deps = [
        ":adder_system_verilog_lib",
    ],
)

place_and_route(
    name = "adder_place_and_route_sky130",
    # ~0.67 GHz
    #clock_period = "1.5",
    core_padding_microns = 2,
    die_height_microns = 150,
    die_width_microns = 150,
    min_pin_distance = "2",
    placement_density = "0.7",
    synthesized_rtl = ":adder_synth_sky130",
)

gds_write(
    name = "adder_gds_sky130",
    implemented_rtl = ":adder_place_and_route_sky130",
)
