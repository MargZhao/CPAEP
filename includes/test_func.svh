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