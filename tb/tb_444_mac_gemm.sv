module tb_444_mac_gemm;
  //---------------------------
  // Design Time Parameters
  //---------------------------

  //---------------------------
  // DESIGN NOTE:
  // Parameters are a way to customize your design at
  // compile time. Here we define the data width,
  // memory depth, and number of ports for the
  // multi-port memory instances used in the DUT.
  //
  // In other test benches, you can also have test parameters,
  // such as the number of tests to run, or the sizes of
  // matrices to be used in the tests.
  //
  // You can customize these parameters as needed.
  // Or you can also add your own parameters.
  //---------------------------

  // General Parameters
  parameter int unsigned NumInputs    = 4;
  parameter int unsigned RowsPerTile  = 4;
  parameter int unsigned ColsPerTile  = 4;
  parameter int unsigned InDataWidth   = 8;
  parameter int unsigned OutDataWidth  = 32;
  parameter int unsigned DataDepth     = 4096;
  parameter int unsigned AddrWidth     = (DataDepth <= 1) ? 1 : $clog2(DataDepth);
  parameter int unsigned SizeAddrWidth = 8;

  // Test Parameters
  parameter int unsigned MaxNum   = 64;
  parameter int unsigned NumTests = 100;

  parameter int unsigned SingleM = 1;
  parameter int unsigned SingleK = 1;
  parameter int unsigned SingleN = 1;

  //---------------------------
  // Wires
  //---------------------------

  // Size control
  logic [SizeAddrWidth-1:0] M_i, K_i, N_i;

  // Clock, reset, and other signals
  logic clk_i;
  logic rst_ni;
  logic start;
  logic done;
  logic [AddrWidth-1:0] test_depth;

  //---------------------------
  // Memory
  //---------------------------

  parameter int unsigned TileRowInputDataWidth = RowsPerTile* NumInputs * InDataWidth;
  parameter int unsigned TileColInputDataWidth = ColsPerTile* NumInputs * InDataWidth;
  parameter int unsigned TileOutputDataWidth = RowsPerTile * ColsPerTile * OutDataWidth;

  // Golden data dump
  logic signed [TileOutputDataWidth-1:0] G_memory [DataDepth];

  // Memory control
  logic [AddrWidth-1:0] sram_a_addr;
  logic [AddrWidth-1:0] sram_b_addr;
  logic [AddrWidth-1:0] sram_c_addr;

  int K_packed_depth;
  int N_packed_depth;
  int M_packed_depth;

  int global_m;
  int global_n;
  int global_k;



  logic signed [TileRowInputDataWidth-1:0] temp_row_pack_data;
  logic signed [TileColInputDataWidth-1:0] temp_col_pack_data;
  logic signed [InDataWidth-1:0] val;

  // Memory access
  logic signed [RowsPerTile*NumInputs-1:0][ InDataWidth-1:0] sram_a_rdata; //4*4 8bit
  logic signed [ColsPerTile*NumInputs-1:0][ InDataWidth-1:0] sram_b_rdata; //4*4 8bit
  wire  signed [RowsPerTile*ColsPerTile-1:0][ OutDataWidth-1:0] sram_c_wdata; //16*32bit 
  logic                           sram_c_we;

  //---------------------------
  // Declaration of input and output memories
  //---------------------------

  //---------------------------
  // DESIGN NOTE:
  // These are where the memories are instantiated for the DUT.
  // You can modify the data width and data depth parameters.
  //
  // This can be useful for increasing your memory bandwidth.
  // However, you need to think about and take care of how to,
  // initialize the memories accordingly.
  // That includes knowing how to pack the data accordingly.
  //
  // Make sure that the connection for the address, data, and wen
  // signals are consistent with the number of ports.
  //
  // Refer to the single_port_memory.sv and 
  // tb_single_port_memory.sv file for more details.
  //---------------------------

  // Input memory A
  // Note: this is read only
  single_port_memory #(
    .DataWidth     ( TileRowInputDataWidth ),
    .DataDepth     ( DataDepth    ),
    .AddrWidth     ( AddrWidth    )
  ) i_sram_a (
    .clk_i         ( clk_i        ),
    .rst_ni        ( rst_ni       ),
    .mem_addr_i    ( sram_a_addr  ),
    .mem_we_i      ( '0           ),
    .mem_wr_data_i ( '0           ),
    .mem_rd_data_o ( sram_a_rdata )
  );

  // Input memory B
  // Note: this is read only
  single_port_memory #(
    .DataWidth     ( TileColInputDataWidth ),
    .DataDepth     ( DataDepth    ),
    .AddrWidth     ( AddrWidth    )
  ) i_sram_b (
    .clk_i         ( clk_i        ),
    .rst_ni        ( rst_ni       ),
    .mem_addr_i    ( sram_b_addr  ),
    .mem_we_i      ( '0           ),
    .mem_wr_data_i ( '0           ),
    .mem_rd_data_o ( sram_b_rdata )
  );

  // Output memory C
  // Note: this is write only
  single_port_memory #(
    .DataWidth     ( TileOutputDataWidth ),
    .DataDepth     ( DataDepth    ),
    .AddrWidth     ( AddrWidth    )
  ) i_sram_c (
    .clk_i         ( clk_i        ),
    .rst_ni        ( rst_ni       ),
    .mem_addr_i    ( sram_c_addr  ),
    .mem_we_i      ( sram_c_we    ),
    .mem_wr_data_i ( sram_c_wdata ),
    .mem_rd_data_o ( /* unused */ )
  );

  //---------------------------
  // DUT instantiation
  //---------------------------
  gemm_accelerator_444_top #(
    .NumInputs     ( NumInputs     ),
    .RowsPerTile   ( RowsPerTile   ),
    .ColsPerTile   ( ColsPerTile   ),
    .InDataWidth   ( InDataWidth   ),
    .OutDataWidth  ( OutDataWidth  ),
    .AddrWidth     ( AddrWidth     ),
    .SizeAddrWidth ( SizeAddrWidth )
  ) i_dut (
    .clk_i          ( clk_i        ),
    .rst_ni         ( rst_ni       ),
    .start_i        ( start        ),
    .N_size_i       ( N_i          ),
    .M_size_i       ( M_i          ),
    .K_size_i       ( K_i          ),
    .sram_a_addr_o  ( sram_a_addr  ),
    .sram_b_addr_o  ( sram_b_addr  ),
    .sram_c_addr_o  ( sram_c_addr  ),
    .sram_a_rdata_i ( sram_a_rdata ),
    .sram_b_rdata_i ( sram_b_rdata ),
    .sram_c_wdata_o ( sram_c_wdata ),
    .sram_c_we_o    ( sram_c_we    ),
    .done_o         ( done         )
  );

  //---------------------------
  // Tasks and functions
  //---------------------------
  `include "includes/common_tasks.svh"
  `include "includes/test_tasks_444.svh"
  `include "includes/test_func_444.svh"

  //---------------------------
  // Test control
  //---------------------------

  // Clock generation
  initial begin
    clk_i = 1'b0;
    forever #5 clk_i = ~clk_i;  // 100MHz clock
  end

  //---------------------------
  // DESIGN NOTE:
  //
  // The sequence driver is usually the main stimulus
  // generator for the test bench. Here is where
  // you define the sequence of operations to be
  // performed during the simulation.
  //
  // It often starts with an initial reset sequence,
  // by loading default values and asserting the reset.
  //
  // We also do for-loops to run multiple tests
  // with different input parameters. In this case,
  // we randomize the matrix sizes for each test.
  //
  // You can also customize in here the way
  // the memories are initialized, how the golden
  // results are generated, and how the results
  // are verified.
  //
  // Refer to the tasks and functions included above
  // for more details.
  //---------------------------

  // Sequence driver
  initial begin

    // Initial reset
    start  = 1'b0;
    rst_ni = 1'b0;
    #50;
    rst_ni = 1'b1;

    for (integer num_test = 0; num_test < NumTests; num_test++) begin
      $display("Test number: %0d", num_test);

      if (num_test == 0) begin
        M_i = 1;
        K_i = 1;
        N_i = 1;
      end else if(num_test == 1) begin
        M_i = 4;
        K_i = 64;
        N_i = 16;
      end else if(num_test == 2) begin
        M_i = 16;
        K_i = 64;
        N_i = 4;
       end else if(num_test == 3) begin
        M_i = 32;
        K_i = 32;
        N_i = 32;
      end else begin
        // Randomize matrix sizes
        M_i = ($urandom() % MaxNum) + 1; // Ensure non-zero size
        K_i = ($urandom() % MaxNum) + 1; // Ensure non-zero size
        N_i = ($urandom() % MaxNum) + 1; // Ensure non-zero size
      end

      $display("M: %0d, K: %0d, N: %0d", M_i, K_i, N_i);

      //---------------------------
      // DESIGN NOTE:
      // You will most likely modify this part
      // to initialize the input memories
      // according to your design requirements.
      //
      // In here, we simply fill the memories
      // with random data for testing.
      //
      // We assume a row-major storage for both matrices A and B.
      // Row major means that the elements of each row
      // are stored in contiguous memory locations.
      //
      // We also make the assumption that the matrix output C
      // will be stored in row-major format as well.
      //
      // Take note that you WILL change this part according to your design.
      // Just make sure that the way you initialize the memories
      // is consistent with the way you generate the golden results
      // and the way your DUT reads/writes the data.
      //
      // The tricky part here is that since the data accesses are
      // shared within a single long bit-width (suppose you use longer)
      // memory word. For example, if your memory word is 32 bits wide
      // and your data width is 8 bits, then you can pack
      // 4 data elements in a single memory word.
      // So when you initialize the memory, you need to
      // make sure that the data elements are packed
      // correctly within each memory word.
      //---------------------------

      // Initialize memories with random data
      K_packed_depth = (K_i + NumInputs - 1) / NumInputs;
      N_packed_depth = (N_i + ColsPerTile - 1) / ColsPerTile;
      M_packed_depth = (M_i + RowsPerTile - 1) / RowsPerTile;


      $display("K_packed_depth: %0d\n", K_packed_depth);
      $display("N_packed_depth: %0d\n", N_packed_depth);
      $display("M_packed_depth: %0d\n", M_packed_depth);
      // ---------------------------------------------------------
      // Matrix A (row major + Zero Padding)
      // ---------------------------------------------------------

      // for (integer m = 0; m < M_i; m++) begin
      //   for (integer k = 0; k < K_i; k = k+NumInputs) begin
      //     temp_pack_data = '0;
      //     for (integer i = 0; i < NumInputs; i++) begin
      //       if ((k + i) < K_i) begin
      //         val = $urandom() % (2 ** 8);
      //       end
      //        // 位拼接：这里采用 Little Endian (低位放低索引)
      //        // [7:0] 放 k+0, [15:8] 放 k+1 ...
      //        temp_pack_data[i*InDataWidth +: InDataWidth] = val;
      //     end
      //     i_sram_a.memory[m*K_packed_depth+(k/NumInputs)] = temp_pack_data;
      //   end
      // end
      for (integer m_tile=0; m_tile < M_packed_depth; m_tile++) begin
        for (integer k = 0; k < K_packed_depth; k++) begin
          temp_row_pack_data = '0;
          for (integer row=0; row < RowsPerTile; row++) begin
            for (integer i = 0; i < NumInputs; i++) begin
              global_m = m_tile * RowsPerTile + row;
              global_k = k * NumInputs + i;
              if ((global_m < M_i) && (global_k < K_i)) begin
                  //val = $urandom() % (2 ** InDataWidth);
                  //val = (global_m*64 + global_k) % (2 ** (InDataWidth-1));
                  val = 1; // For easier debugging
                 
                  temp_row_pack_data[row*NumInputs*InDataWidth + i*InDataWidth +: InDataWidth] = val;
              end
            end
          end
          i_sram_a.memory[m_tile * K_packed_depth + k] = temp_row_pack_data;
        end
      end
      // ---------------------------------------------------------
      // Matrix B (colomn major + Zero Padding)
      // ---------------------------------------------------------
      for (integer n_tile=0; n_tile < N_packed_depth; n_tile++) begin
        for (integer k = 0; k < K_packed_depth; k++) begin
          temp_col_pack_data = '0;
          for (integer col=0; col< ColsPerTile; col++) begin
            for (integer i = 0; i < NumInputs; i++) begin
              global_n = n_tile * ColsPerTile + col;
              global_k = k * NumInputs + i;
              if ((global_n < N_i) && (global_k < K_i)) begin
                  //val = $urandom() % (2 ** InDataWidth);
                  //val = (global_n*64 + global_k) % (2 ** (InDataWidth-1));
                  val = 1; // For easier debugging
                 
                  temp_col_pack_data[col*NumInputs*InDataWidth + i*InDataWidth +: InDataWidth] = val;
              end
            end
          end
          i_sram_b.memory[n_tile * K_packed_depth + k] = temp_col_pack_data;
        end
      end
      // for (integer k = 0; k < K_i; k++) begin
      //   for (integer n = 0; n < N_i; n++) begin
      //     i_sram_b.memory[k*N_i+n] = $urandom() % (2 ** InDataWidth);
      //   end
      // end

      // Generate golden result
      gemm_444_golden(M_i, K_i, N_i, i_sram_a.memory, i_sram_b.memory, G_memory);

      // Just delay 1 cycle
      clk_delay(1);

      // Execute the GeMM
      start_and_wait_gemm();

      test_depth = M_packed_depth * N_packed_depth;

      // Verify the result
      verify_444_result_c(G_memory, i_sram_c.memory, test_depth,
                      0 // Set this to 1 to make mismatches fatal
      );

      // Just some trailing cycles
      // For easier monitoring in waveform
      clk_delay(10);
    end

    $display("All test tasks completed successfully!");
    $finish;
  end

endmodule
