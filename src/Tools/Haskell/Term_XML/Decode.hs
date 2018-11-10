{- generated by Isabelle -}

{-  Title:      Tools/Haskell/Term_XML/Decode.hs
    Author:     Makarius
    LICENSE:    BSD 3-clause (Isabelle)

XML data representation of lambda terms.

See also "$ISABELLE_HOME/src/Pure/term_xml.ML".
-}

module Isabelle.Term_XML.Decode (sort, typ, term)
where

import Isabelle.Library
import qualified Isabelle.XML as XML
import Isabelle.XML.Decode
import Isabelle.Term


sort :: T Sort
sort = list string

typ :: T Typ
typ ty =
  ty |> variant
  [\([a], b) -> Type (a, list typ b),
   \([a], b) -> TFree (a, sort b),
   \([a, b], c) -> TVar ((a, int_atom b), sort c)]

term :: T Term
term t =
  t |> variant
   [\([a], b) -> Const (a, typ b),
    \([a], b) -> Free (a, typ b),
    \([a, b], c) -> Var ((a, int_atom b), typ c),
    \([a], []) -> Bound (int_atom a),
    \([a], b) -> let (c, d) = pair typ term b in Abs (a, c, d),
    \([], a) -> App (pair term term a)]
