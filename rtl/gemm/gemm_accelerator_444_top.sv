//---------------------------
// The 1-MAC GeMM accelerator top module
//
// Description:
// This module implements a simple General Matrix-Matrix Multiplication (GeMM)
// accelerator using a single Multiply-Accumulate (MAC) Processing Element (PE).
// It interfaces with three SRAMs for input matrices A and B, and output matrix C.
//
// It includes a controller to manage the GeMM operation and address generation logic
// for accessing the SRAMs based on the current matrix sizes and counters.
//
// Parameters:
// - InDataWidth  : Width of the input data (matrix elements).
// - OutDataWidth : Width of the output data (result matrix elements).
// - AddrWidth    : Width of the address bus for SRAMs.
// - SizeAddrWidth: Width of the size parameters for matrices.
//
// Ports:
// - clk_i        : Clock input.
// - rst_ni       : Active-low reset input.
// - start_i      : Start signal to initiate the GeMM operation.
// - M_size_i     : Size of matrix M (number of rows in A and C
// - K_size_i     : Size of matrix K (number of columns in A and rows in B).
// - N_size_i     : Size of matrix N (number of columns in B and C).
// - sram_a_addr_o: Address output for SRAM A.
// - sram_b_addr_o: Address output for SRAM B.
// - sram_c_addr_o: Address output for SRAM C.
// - sram_a_rdata_i: Data input from SRAM A.
// - sram_b_rdata_i: Data input from SRAM B.
// - sram_c_wdata_o: Data output to SRAM C.
// - sram_c_we_o  : Write enable output for SRAM C.
// - done_o       : Done signal indicating completion of the GeMM operation.
//---------------------------

module gemm_accelerator_444_top #(
  parameter int unsigned NumInputs = 1,
  parameter int unsigned RowsPerTile = 4,
  parameter int unsigned ColsPerTile = 4,
  parameter int unsigned InDataWidth = 8,
  parameter int unsigned OutDataWidth = 32,
  parameter int unsigned AddrWidth = 16,
  parameter int unsigned SizeAddrWidth = 7
) (
  input  logic                            clk_i,
  input  logic                            rst_ni,
  input  logic                            start_i,
  input  logic        [SizeAddrWidth-1:0] M_size_i,
  input  logic        [SizeAddrWidth-1:0] K_size_i,
  input  logic        [SizeAddrWidth-1:0] N_size_i,
  output logic        [    AddrWidth-1:0] sram_a_addr_o,
  output logic        [    AddrWidth-1:0] sram_b_addr_o,
  output logic        [    AddrWidth-1:0] sram_c_addr_o,
  input  logic signed [RowsPerTile*NumInputs-1:0][  InDataWidth-1:0] sram_a_rdata_i, // Matrix A data 4x4 8 bit
  input  logic signed [ColsPerTile*NumInputs-1:0][  InDataWidth-1:0] sram_b_rdata_i, // Matrix B data 4x4 8 bit
  output wire signed [RowsPerTile*ColsPerTile-1:0][ OutDataWidth-1:0] sram_c_wdata_o,           // Matrix C data 4x4  32 bit
  output logic                            sram_c_we_o,
  output logic                            done_o
);

  localparam int unsigned CountWidth = SizeAddrWidth-2;
  //---------------------------
  // Wires
  //---------------------------
  logic [CountWidth-1:0] M_count;
  logic [CountWidth-1:0] K_count;
  logic [CountWidth-1:0] N_count;

  logic busy;
  logic valid_data;
  assign valid_data = start_i || busy;  // Always valid in this simple design

  //---------------------------
  // DESIGN NOTE:
  // This is a simple GeMM accelerator design using a single MAC PE.
  // The controller manages just the counting capabilities.
  // Check the gemm_controller.sv file for more details.
  //
  // Essentially, it tightly couples the counters and an FSM together.
  // The address generation logic is just after this controller.
  //
  // You have the option to combine the address generation and controller
  // all in one module if you prefer. We did this intentionally to separate tasks.
  //---------------------------

  // Main GeMM controller
  gemm_444_controller #(
    .AddrWidth      ( SizeAddrWidth ),
    .CountWidth     ( CountWidth    ),
    .NumInputs      ( NumInputs     ),
    .RowsPerTile    ( RowsPerTile   ),
    .ColsPerTile    ( ColsPerTile   )
  ) i_gemm_controller (
    .clk_i          ( clk_i       ),
    .rst_ni         ( rst_ni      ),
    .start_i        ( start_i     ),
    .input_valid_i  ( 1'b1        ),  // Always valid in this simple design
    .result_valid_o ( sram_c_we_o ),
    .busy_o         ( busy        ),
    .done_o         ( done_o      ),
    .M_size_i       ( M_size_i    ),
    .K_size_i       ( K_size_i    ),
    .N_size_i       ( N_size_i    ),
    .M_count_o      ( M_count     ),
    .K_count_o      ( K_count     ),
    .N_count_o      ( N_count     )
  );

  //---------------------------
  // DESIGN NOTE:
  // This part is the address generation logic for the input and output SRAMs.
  // In our example, we made the assumption that both matrices A and B
  // are stored in row-major order.
  //
  // Please adjust this part to align with your designed memory layout
  // The counters are used for the matrix A and matrix B address generation;
  // for matrix C, the corresponding address is calculated at the previous cycle,
  // thus adding one cycle delay on c
  //
  // Just be careful to know on which cycle the addresses are valid.
  // Align it carefully with the testbench's memory control.
  //---------------------------

  // Input addresses for matrices A and B
  logic [AddrWidth-1:0] K_packed_depth;
  assign K_packed_depth = (K_size_i + NumInputs - 1) / NumInputs;
  logic [AddrWidth-1:0] N_packed_depth;
  assign N_packed_depth = (N_size_i + ColsPerTile - 1) / ColsPerTile;
  logic [AddrWidth-1:0] M_packed_depth;
  assign M_packed_depth = (M_size_i + RowsPerTile - 1) / RowsPerTile;


  assign sram_a_addr_o = (M_count* K_packed_depth + K_count);
  assign sram_b_addr_o = (N_count* K_packed_depth + K_count);

  // Output address for matrix C
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sram_c_addr_o <= '0;
    end else if (1'b1) begin  // Always valid in this simple design
      sram_c_addr_o <= (M_count * N_packed_depth + N_count);
    end
  end

  //---------------------------
  // DESIGN NOTE:
  // This part is the MAC PE instantiation and data path logic.
  // Check the general_mac_pe.sv file for more details.
  //
  // In this example, we only use a single MAC PE hence it is a simple design.
  // However, you can expand this part to support multiple PEs
  // by adjusting the data widths and input/output connections accordingly.
  //
  // Systemverilog has a useful mechanism to generate multiple instances
  // using generate-for loops.
  // Below is an example of a 2D generate-for loop to create a grid of PEs.
  //
  // ----------- BEGIN CODE EXAMPLE -----------

  /*
    for M = 0 to M'/4 -1             M_count = 0 to 0
      for N = 0 to N'/4 -1           N_count = 0 to 3
        for K = 0 to K'/NumInputs-1  K_count = 0 to 15
          parfor m = 0 to 3
          parfor n = 0 to 3
          parfor k = 0 to NumInputs -1
            MAC_PE_array[M*4 + m][N*4 + n] += A_matrix[M*4 + m][K*NumInputs + k] * B_matrix[K*NumInputs + k][N*4 + n]
  */


  // genvar m, k, n;
  //
  //   for (m = 0; m < 4; m++) begin : gem_mac_pe_m
  //     for (n = 0; n < 4; n++) begin : gem_mac_pe_n
  //         mac_module #(
  //           < insert parameters >
  //         ) i_mac_pe (
  //           < insert port connections >
  //         );
  //     end
  //   end
  // ----------- END CODE EXAMPLE -----------
  // 
  // There are many guides on the internet (or even ChatGPT) about generate-for loops.
  // We will give it as an exercise to you to modify this part to support multiple MAC PEs.
  // 
  // When dealing with multiple PEs, be careful with the connection alignment
  // across different PEs as it can be tricky to debug later on.
  // Plan this very carefully, especially when delaing with the correcet data ports
  // data widths, slicing, valid signals, and so much more.
  //
  // Additionally, this MAC PE is already output stationary.
  // You have the freedom to change the dataflow as you see fit.
  //---------------------------

  // The MAC PE instantiation and data path logics
  genvar row,col;

  for (row=0; row<RowsPerTile; row++) begin : gem_mac_pe_m
    for (col=0; col<ColsPerTile; col++) begin : gem_mac_pe_n
      // You can instantiate multiple MAC PEs here
      general_mac_pe #(
        .InDataWidth  ( InDataWidth            ),
        .NumInputs    ( NumInputs              ),
        .OutDataWidth ( OutDataWidth           )
      ) i_mac_pe (
        .clk_i        ( clk_i                  ),
        .rst_ni       ( rst_ni                 ),
        .a_i          ( signed'(sram_a_rdata_i[row*NumInputs +: NumInputs]) ),
        .b_i          ( signed'(sram_b_rdata_i[col*NumInputs +: NumInputs]) ),
        .a_valid_i    ( valid_data             ),
        .b_valid_i    ( valid_data             ),
        .init_save_i  ( start_i||sram_c_we_o   ),
        .acc_clr_i    ( !busy                  ),
        .c_o          ( sram_c_wdata_o[row*ColsPerTile+col] )
      );
    end
  end
  

endmodule
