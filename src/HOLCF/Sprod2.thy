(*  Title:      HOLCF/Sprod2.thy
    ID:         $Id$
    Author:     Franz Regensburger
    Copyright   1993 Technische Universitaet Muenchen

Class Instance **::(pcpo,pcpo)po
*)

Sprod2 = Sprod1 + 

instance "**"::(pcpo,pcpo)po 
		(refl_less_sprod, antisym_less_sprod, trans_less_sprod)
end


