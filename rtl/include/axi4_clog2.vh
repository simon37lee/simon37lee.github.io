// Integer ceil(log2(value)) helper, used to turn a FIFO_DEPTH parameter
// (entries) into the ADDR_WIDTH expected by async_fifo (address bits).
// Deliberately NOT include-guarded: Verilog functions are module-scoped, so
// this is meant to be `included once inside the body of every module that
// needs it (each inclusion defines a private copy local to that module).
function integer axi4_clog2;
  input integer value;
  integer temp;
  begin
    temp = value - 1;
    for (axi4_clog2 = 0; temp > 0; axi4_clog2 = axi4_clog2 + 1)
      temp = temp >> 1;
  end
endfunction
