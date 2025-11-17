module adder(
  input wire clk,
  input wire [3:0] a,
  input wire [3:0] b,
  output wire [4:0] out
);
  wire literal_25;
  wire [4:0] add_28;
  assign literal_25 = 1'h0;
  assign add_28 = {literal_25, a} + {literal_25, b};
  assign out = add_28;
endmodule
