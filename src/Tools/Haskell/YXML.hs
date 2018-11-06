{- generated by Isabelle -}

{-  Title:      Tools/Haskell/YXML.hs
    Author:     Makarius
    LICENSE:    BSD 3-clause (Isabelle)

Efficient text representation of XML trees.  Suitable for direct
inlining into plain text.
-}

module Isabelle.YXML (charX, charY, strX, strY, detect, output_markup,
  buffer_body, buffer, string_of_body, string_of, parse_body, parse)
where

import qualified Data.Char as Char
import qualified Data.List as List

import Isabelle.Library
import qualified Isabelle.Markup as Markup
import qualified Isabelle.XML as XML
import qualified Isabelle.Buffer as Buffer


{- markers -}

charX, charY :: Char
charX = Char.chr 5
charY = Char.chr 6

strX, strY, strXY, strXYX :: String
strX = [charX]
strY = [charY]
strXY = strX ++ strY
strXYX = strXY ++ strX

detect :: String -> Bool
detect = any (\c -> c == charX || c == charY)


{- output -}

output_markup :: Markup.T -> Markup.Output
output_markup markup@(name, atts) =
  if Markup.is_empty markup then Markup.no_output
  else (strXY ++ name ++ concatMap (\(a, x) -> strY ++ a ++ "=" ++ x) atts ++ strX, strXYX)

buffer_attrib (a, x) =
  Buffer.add strY #> Buffer.add a #> Buffer.add "=" #> Buffer.add x

buffer_body :: XML.Body -> Buffer.T -> Buffer.T
buffer_body = fold buffer

buffer :: XML.Tree -> Buffer.T -> Buffer.T
buffer (XML.Elem (name, atts) ts) =
  Buffer.add strXY #> Buffer.add name #> fold buffer_attrib atts #> Buffer.add strX #>
  buffer_body ts #>
  Buffer.add strXYX
buffer (XML.Text s) = Buffer.add s

string_of_body :: XML.Body -> String
string_of_body body = Buffer.empty |> buffer_body body |> Buffer.content

string_of :: XML.Tree -> String
string_of = string_of_body . single


{- parse -}

-- split: fields or non-empty tokens

split :: Bool -> Char -> String -> [String]
split _ _ [] = []
split fields sep str = splitting str
  where
    splitting rest =
      case span (/= sep) rest of
        (_, []) -> cons rest []
        (prfx, _ : rest') -> cons prfx (splitting rest')
    cons item = if fields || not (null item) then (:) item else id


-- structural errors

err msg = error ("Malformed YXML: " ++ msg)
err_attribute = err "bad attribute"
err_element = err "bad element"
err_unbalanced "" = err "unbalanced element"
err_unbalanced name = err ("unbalanced element " ++ quote name)


-- stack operations

add x ((elem, body) : pending) = (elem, x : body) : pending

push "" _ _ = err_element
push name atts pending = ((name, atts), []) : pending

pop ((("", _), _) : _) = err_unbalanced ""
pop ((markup, body) : pending) = add (XML.Elem markup (reverse body)) pending


-- parsing

parse_attrib s =
  case List.elemIndex '=' s of
    Just i | i > 0 -> (take i s, drop (i + 1) s)
    _ -> err_attribute

parse_chunk ["", ""] = pop
parse_chunk ("" : name : atts) = push name (map parse_attrib atts)
parse_chunk txts = fold (add . XML.Text) txts

parse_body :: String -> XML.Body
parse_body source =
  case fold parse_chunk chunks [(("", []), [])] of
    [(("", _), result)] -> reverse result
    ((name, _), _) : _ -> err_unbalanced name
  where chunks = split False charX source |> map (split True charY)

parse :: String -> XML.Tree
parse source =
  case parse_body source of
    [result] -> result
    [] -> XML.Text ""
    _ -> err "multiple results"
