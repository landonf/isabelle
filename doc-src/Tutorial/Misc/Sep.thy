Sep = List +
consts sep :: "'a * 'a list => 'a list"
recdef sep "measure (%(a,xs). length xs)"
    "sep(a, [])     = []"
    "sep(a, [x])    = [x]"
    "sep(a, x#y#zs) = x # a # sep(a,y#zs)"
end
