ConstDefs = Types +
constdefs nand :: gate
         "nand A B == ~(A & B)"
          exor :: gate
         "exor A B == A & ~B | ~A & B"
end
