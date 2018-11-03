{- GENERATED by Isabelle! -}
{-  Title:      Haskell/Tools/Markup.hs
    Author:     Makarius
    LICENSE:    BSD 3-clause (Isabelle)

Quasi-abstract markup elements.
-}

module Isabelle.Markup (T, empty, is_empty, Output, no_output)
where

import qualified Isabelle.Properties as Properties


type T = (String, Properties.T)

empty :: T
empty = ("", [])

is_empty :: T -> Bool
is_empty ("", _) = True
is_empty _ = False


type Output = (String, String)

no_output :: Output
no_output = ("", "")
