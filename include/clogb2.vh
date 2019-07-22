function integer clogb2;
input integer val;
begin
    clogb2 = 1;
    for (val = val/2; val > 1; val = val/2) begin
        clogb2 = clogb2 + 1;
    end
end
endfunction
