(*  Title:      HOLCF/ex/Loop.thy
    ID:         $Id$
    Author:     Franz Regensburger
    License:    GPL (GNU GENERAL PUBLIC LICENSE)

Theory for a loop primitive like while
*)

Loop = Tr +

consts
        step  :: "('a -> tr)->('a -> 'a)->'a->'a"
        while :: "('a -> tr)->('a -> 'a)->'a->'a"

defs

  step_def      "step == (LAM b g x. If b$x then g$x else x fi)"
  while_def     "while == (LAM b g. fix$(LAM f x.
                   If b$x then f$(g$x) else x fi))"

end
 
