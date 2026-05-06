module otbn_sec_add_flatten_rand #(
  parameter  int Width        = 32,
  localparam int NumShares    = 2,
  localparam int Stages       = $clog2(Width),
  localparam int RandWidth    = Stages*(5*Width/4 - 2) - Width/2 + 3

) (
  input  logic clk_i,
  input  logic rst_ni,

  input  logic valid_i,
  input  logic [RandWidth-1:0] flat_rand_i,
  input  logic [Width-1:0] a_i[NumShares],
  input  logic [Width-1:0] b_i[NumShares],
  output logic [Width-1:0] sum_o[NumShares],
  output logic valid_o
);


  // The 3D array we will feed into the adder
  logic [Width-1:0] rand_3d [Stages+1][4];

  always_comb begin
    // Default tie-off
    rand_3d = '{default: '{default: '0}};
    
    // Map the flat vector to the 3D struct
    begin : flat_to_3d_mapping
      int r_idx;
      r_idx = 0;

      // Level 0: Pre-processing stage
      rand_3d[0][1][0] = flat_rand_i[r_idx];
      r_idx += 1;
      for (int i = 0; i < Width-1; i++) begin
        if (r_idx < RandWidth) begin
          rand_3d[0][0][i] = flat_rand_i[r_idx];
          r_idx += 1;
        end
      end

      // Level 1 to Stages: Prefix Tree
      for (int level = 1; level <= Stages; level++) begin
        int step = 1 << (level - 1);

        for (int i = 0; i < Width-1; i++) begin
          int remote = (i / (2 * step)) * (2 * step) + step - 1;

          if ((i % (2 * step)) >= step) begin

            // Map G Gadget Randomness (Bits [1:0])
            if ((i == (2*step-1)) || ((level == Stages) && (i >= (Width*3/4)))) begin
              if (r_idx + 1 < RandWidth) begin
                rand_3d[level][0][i] = flat_rand_i[r_idx];
                rand_3d[level][1][i] = flat_rand_i[r_idx+1];
                r_idx += 2;
              end
            end else begin
              if (r_idx < RandWidth) begin
                rand_3d[level][0][i] = flat_rand_i[r_idx];
                r_idx += 1;
              end
            end

            // Map P Gadget Randomness (Bits [3:2])
            if ((2 * step) > i) begin
              // Unused, skip
            end else if (((2*(i - remote)) <= step) || (level == 1)) begin
              if (r_idx < RandWidth) begin
                rand_3d[level][2][i] = flat_rand_i[r_idx];
                r_idx += 1;
              end
            end else begin
              if (r_idx + 1 < RandWidth) begin
                rand_3d[level][2][i] = flat_rand_i[r_idx];
                rand_3d[level][3][i] = flat_rand_i[r_idx+1];
                r_idx += 2;
              end
            end
          end
        end
      end
    end
  end

  // Instantiate the secure adder
  otbn_sec_add_core #(
    .Width     (Width)
  ) u_otbn_sec_add_core (
    .clk_i,
    .rst_ni,
    .valid_i,
    .r_i(rand_3d),
    .a_i,
    .b_i,
    .sum_o,
    .valid_o
  );

endmodule
