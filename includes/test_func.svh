//--------------------------
// Useful functions for testing
//--------------------------
function automatic void gemm_golden(
  input  logic [AddrWidth-1:0] M,
  input  logic [AddrWidth-1:0] K,
  input  logic [AddrWidth-1:0] N,
  input  logic signed [NumInputs-1:0][ InDataWidth-1:0] A_i [DataDepth],
  input  logic signed [NumInputs-1:0][ InDataWidth-1:0] B_i [DataDepth],
  output logic signed [OutDataWidth-1:0] Y_o [DataDepth]
);
  int unsigned m, n, k;
  int signed acc;
 
  int input_idx;   

  int K_packed_depth;
  K_packed_depth = (K + NumInputs - 1) / NumInputs;//ceiling

  for (m = 0; m < M; m++) begin
    for (n = 0; n<N; n++) begin
      acc = 0;
      for (k = 0; k < K; k++) begin
        input_idx   = k % NumInputs;
        acc += $signed(A_i[ m * K_packed_depth + (k / NumInputs)][input_idx]) * $signed(B_i[n * K_packed_depth + (k / NumInputs)][input_idx]);
      end
      Y_o[m*N + n] = acc;
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