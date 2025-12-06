//--------------------------
// Useful functions for testing
//--------------------------


function automatic void gemm_444_golden(
  input  logic [AddrWidth-1:0] M,
  input  logic [AddrWidth-1:0] K,
  input  logic [AddrWidth-1:0] N,
  input  logic signed [ TileRowInputDataWidth-1:0] A_i [DataDepth],
  input  logic signed [ TileColInputDataWidth-1:0] B_i [DataDepth],
  output logic signed [TileOutputDataWidth-1:0] Y_o [DataDepth]
);

 int K_packed_depth = (K + NumInputs - 1) / NumInputs;
 int M_packed_depth = (M + RowsPerTile - 1) / RowsPerTile;
 int N_packed_depth = (N + ColsPerTile - 1) / ColsPerTile;
 
 int global_m, global_n, global_k, i;
 longint signed acc;
 logic [TileOutputDataWidth-1:0] temp_output_tile;

 for (integer m_tile = 0; m_tile < M_packed_depth; m_tile++) begin
  for (integer n_tile = 0; n_tile < N_packed_depth; n_tile++) begin
      temp_output_tile = '0;

      for (integer row = 0; row < RowsPerTile; row++) begin
        for (integer col = 0; col < ColsPerTile; col++) begin
            global_m = m_tile * RowsPerTile + row;
            global_n = n_tile * ColsPerTile + col;
            acc = 0;

            if(global_m < M && global_n < N) begin
              for (integer k = 0; k < K; k++) begin
                  i = k%NumInputs;
                  acc += $signed(A_i[ m_tile * K_packed_depth + k/NumInputs][(i + row*NumInputs)* InDataWidth +: InDataWidth]) *
                         $signed(B_i[ n_tile * K_packed_depth + k/NumInputs][(i + col*NumInputs)* InDataWidth +: InDataWidth]);
              end
            end
            temp_output_tile[(row * ColsPerTile + col) * OutDataWidth +: OutDataWidth] = acc[OutDataWidth-1:0];
        end
      end
      Y_o[m_tile * N_packed_depth + n_tile] = temp_output_tile;
  end
 end
endfunction

function automatic void gemm_2D_golden(
  input  logic [AddrWidth-1:0] M,
  input  logic [AddrWidth-1:0] K,
  input  logic [AddrWidth-1:0] N,
  input  logic signed [ParforK-1:0][ InDataWidth-1:0] A_i [DataDepth],
  input  logic signed [ParforK*ParforN-1:0][ InDataWidth-1:0] B_i [DataDepth],
  output logic signed [ParforN-1:0][OutDataWidth-1:0] Y_o [DataDepth]
);
  int unsigned m, n, k;
  int unsigned n_block, ni; 
  
  logic signed [OutDataWidth-1:0] acc;
  logic signed [ParforN-1:0][OutDataWidth-1:0] temp_pack_Y; 
 
  int input_A_idx;   
  int input_B_idx;
  int K_packed_depth;
  int N_packed_depth;

  K_packed_depth = (K + ParforK - 1) / ParforK;
  N_packed_depth = (N + ParforN - 1) / ParforN;

  for (m = 0; m < M; m++) begin
    
    for (n_block = 0; n_block < N_packed_depth; n_block++) begin 
      temp_pack_Y = '0; 

      for (ni = 0; ni < ParforN; ni++) begin
        n = n_block * ParforN + ni;

        if (n < N) begin
            acc = 0;
            for (k = 0; k < K; k++) begin
              input_A_idx = k % ParforK;
              input_B_idx = k % ParforK + (n % ParforN) * ParforK;
              
              acc += $signed(A_i[ m * K_packed_depth + (k / ParforK)][input_A_idx]) * $signed(B_i[(n / ParforN) * K_packed_depth + (k / ParforK)][input_B_idx]);
            end
            temp_pack_Y[ni] = acc;
        end
      end
      Y_o[m * N_packed_depth + n_block] = temp_pack_Y;
    end
  end
endfunction
// function automatic void gemm_golden(
//   input  logic [AddrWidth-1:0] M,
//   input  logic [AddrWidth-1:0] K,
//   input  logic [AddrWidth-1:0] N,
//   input  logic signed [M_packed_depth*K_packed_depth-1:0][ TileRowInputDataWidth-1:0] A_i [DataDepth],
//   input  logic signed [N_packed_depth*K_packed_depth-1:0][ TileColInputDataWidth-1:0] B_i [DataDepth],
//   output logic signed [TileOutputDataWidth-1:0] Y_o [DataDepth]
// );
//   int unsigned m, n, k;
//   int signed acc;
 
//   int input_idx;   

//   int K_packed_depth;
//   K_packed_depth = (K + NumInputs - 1) / NumInputs;//ceiling

//   for (m = 0; m < M; m++) begin
//     for (n = 0; n<N; n++) begin
//       acc = 0;
//       for (k = 0; k < K; k++) begin
//         input_idx   = k % NumInputs;
//         acc += $signed(A_i[ m * K_packed_depth + (k / NumInputs)][input_idx]) * $signed(B_i[n * K_packed_depth + (k / NumInputs)][input_idx]);
//       end
//       Y_o[m*N + n] = acc;
//     end
// end
// endfunction
// function automatic void gemm_golden(
//   input  logic [AddrWidth-1:0] M,
//   input  logic [AddrWidth-1:0] K,
//   input  logic [AddrWidth-1:0] N,
//   input  logic signed [ InDataWidth-1:0] A_i [DataDepth],
//   input  logic signed [ InDataWidth-1:0] B_i [DataDepth],
//   output logic signed [OutDataWidth-1:0] Y_o [DataDepth]
// );
//   int unsigned m, n, k;
//   int signed acc;

//   for (m = 0; m < M; m++) begin
//     for (n = 0; n<N; n++) begin
//       acc = 0;
//       for (k = 0; k < K; k++) begin
//         acc += $signed(A_i[m*K + k]) * $signed(B_i[k*N + n]);
//       end
//       Y_o[m*N + n] = acc;
//     end
// end
// endfunction