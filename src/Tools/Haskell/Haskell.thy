(*  Title:      Tools/Haskell/Haskell.thy
    Author:     Makarius

Support for Isabelle tools in Haskell.
*)

theory Haskell
  imports Pure
  keywords "generate_haskell_file" "export_haskell_file" :: thy_decl
begin

ML_file "haskell.ML"


section \<open>Commands\<close>

ML \<open>
  Outer_Syntax.command \<^command_keyword>\<open>generate_haskell_file\<close> "generate Haskell file"
    (Parse.position Parse.path -- (\<^keyword>\<open>=\<close> |-- Parse.input Parse.embedded)
      >> Haskell.generate_file_cmd);

  Outer_Syntax.command \<^command_keyword>\<open>export_haskell_file\<close> "export Haskell file"
    (Parse.name -- (\<^keyword>\<open>=\<close> |-- Parse.input Parse.embedded)
      >> Haskell.export_file_cmd);
\<close>


section \<open>Source modules\<close>

generate_haskell_file Library.hs = \<open>
{-  Title:      Tools/Haskell/Library.hs
    Author:     Makarius
    LICENSE:    BSD 3-clause (Isabelle)

Basic library of Isabelle idioms.
-}

module Isabelle.Library
  ((|>), (|->), (#>), (#->), the_default, fold, fold_rev, single, quote, trim_line)
where

import Data.Maybe


{- functions -}

(|>) :: a -> (a -> b) -> b
x |> f = f x

(|->) :: (a, b) -> (a -> b -> c) -> c
(x, y) |-> f = f x y

(#>) :: (a -> b) -> (b -> c) -> a -> c
(f #> g) x = x |> f |> g

(#->) :: (a -> (c, b)) -> (c -> b -> d) -> a -> d
(f #-> g) x  = x |> f |-> g


{- options -}

the_default :: a -> Maybe a -> a
the_default x Nothing = x
the_default _ (Just y) = y


{- lists -}

fold :: (a -> b -> b) -> [a] -> b -> b
fold _ [] y = y
fold f (x : xs) y = fold f xs (f x y)

fold_rev :: (a -> b -> b) -> [a] -> b -> b
fold_rev _ [] y = y
fold_rev f (x : xs) y = f x (fold_rev f xs y)

single :: a -> [a]
single x = [x]


{- strings -}

quote :: String -> String
quote s = "\"" ++ s ++ "\""

trim_line :: String -> String
trim_line line =
  case reverse line of
    '\n' : '\r' : rest -> reverse rest
    '\n' : rest -> reverse rest
    _ -> line
\<close>

generate_haskell_file Value.hs = \<open>
{-  Title:      Haskell/Tools/Value.hs
    Author:     Makarius
    LICENSE:    BSD 3-clause (Isabelle)

Plain values, represented as string.
-}

module Isabelle.Value
  (print_bool, parse_bool, print_int, parse_int, print_real, parse_real)
where

import Data.Maybe
import qualified Data.List as List
import qualified Text.Read as Read


{- bool -}

print_bool :: Bool -> String
print_bool True = "true"
print_bool False = "false"

parse_bool :: String -> Maybe Bool
parse_bool "true" = Just True
parse_bool "false" = Just False
parse_bool _ = Nothing


{- int -}

print_int :: Int -> String
print_int = show

parse_int :: String -> Maybe Int
parse_int = Read.readMaybe


{- real -}

print_real :: Double -> String
print_real x =
  let s = show x in
    case span (/= '.') s of
      (a, '.' : b) | List.all (== '0') b -> a
      _ -> s

parse_real :: String -> Maybe Double
parse_real = Read.readMaybe
\<close>

generate_haskell_file Buffer.hs = \<open>
{-  Title:      Tools/Haskell/Buffer.hs
    Author:     Makarius
    LICENSE:    BSD 3-clause (Isabelle)

Efficient text buffers.
-}

module Isabelle.Buffer (T, empty, add, content)
where

newtype T = Buffer [String]

empty :: T
empty = Buffer []

add :: String -> T -> T
add "" buf = buf
add x (Buffer xs) = Buffer (x : xs)

content :: T -> String
content (Buffer xs) = concat (reverse xs)
\<close>

generate_haskell_file Properties.hs = \<open>
{-  Title:      Tools/Haskell/Properties.hs
    Author:     Makarius
    LICENSE:    BSD 3-clause (Isabelle)

Property lists.
-}

module Isabelle.Properties (Entry, T, defined, get, put, remove)
where

import qualified Data.List as List


type Entry = (String, String)
type T = [Entry]

defined :: T -> String -> Bool
defined props name = any (\(a, _) -> a == name) props

get :: T -> String -> Maybe String
get props name = List.lookup name props

put :: Entry -> T -> T
put entry props = entry : remove (fst entry) props

remove :: String -> T -> T
remove name props =
  if defined props name then filter (\(a, _) -> a /= name) props
  else props
\<close>

generate_haskell_file Markup.hs = \<open>
{-  Title:      Haskell/Tools/Markup.hs
    Author:     Makarius
    LICENSE:    BSD 3-clause (Isabelle)

Quasi-abstract markup elements.
-}

module Isabelle.Markup (
  T, empty, is_empty, properties,

  nameN, name, xnameN, xname, kindN,

  lineN, end_lineN, offsetN, end_offsetN, fileN, idN, positionN, position,

  wordsN, words, no_wordsN, no_words,

  tfreeN, tfree, tvarN, tvar, freeN, free, skolemN, skolem, boundN, bound, varN, var,
  numeralN, numeral, literalN, literal, delimiterN, delimiter, inner_stringN, inner_string,
  inner_cartoucheN, inner_cartouche, inner_commentN, inner_comment,
  token_rangeN, token_range,
  sortingN, sorting, typingN, typing, class_parameterN, class_parameter,

  antiquotedN, antiquoted, antiquoteN, antiquote,

  paragraphN, paragraph, text_foldN, text_fold,

  keyword1N, keyword1, keyword2N, keyword2, keyword3N, keyword3, quasi_keywordN, quasi_keyword,
  improperN, improper, operatorN, operator, stringN, string, alt_stringN, alt_string,
  verbatimN, verbatim, cartoucheN, cartouche, commentN, comment,

  writelnN, writeln, stateN, state, informationN, information, tracingN, tracing,
  warningN, warning, legacyN, legacy, errorN, error, reportN, report, no_reportN, no_report,

  intensifyN, intensify,
  Output, no_output)
where

import Prelude hiding (words, error)

import Isabelle.Library
import qualified Isabelle.Properties as Properties


{- basic markup -}

type T = (String, Properties.T)

empty :: T
empty = ("", [])

is_empty :: T -> Bool
is_empty ("", _) = True
is_empty _ = False

properties :: Properties.T -> T -> T
properties more_props (elem, props) =
  (elem, fold_rev Properties.put more_props props)

markup_elem name = (name, (name, []) :: T)


{- misc properties -}

nameN :: String
nameN = \<open>Markup.nameN\<close>

name :: String -> T -> T
name a = properties [(nameN, a)]

xnameN :: String
xnameN = \<open>Markup.xnameN\<close>

xname :: String -> T -> T
xname a = properties [(xnameN, a)]

kindN :: String
kindN = \<open>Markup.kindN\<close>


{- position -}

lineN, end_lineN :: String
lineN = \<open>Markup.lineN\<close>
end_lineN = \<open>Markup.end_lineN\<close>

offsetN, end_offsetN :: String
offsetN = \<open>Markup.offsetN\<close>
end_offsetN = \<open>Markup.end_offsetN\<close>

fileN, idN :: String
fileN = \<open>Markup.fileN\<close>
idN = \<open>Markup.idN\<close>

positionN :: String; position :: T
(positionN, position) = markup_elem \<open>Markup.positionN\<close>


{- text properties -}

wordsN :: String; words :: T
(wordsN, words) = markup_elem \<open>Markup.wordsN\<close>

no_wordsN :: String; no_words :: T
(no_wordsN, no_words) = markup_elem \<open>Markup.no_wordsN\<close>


{- inner syntax -}

tfreeN :: String; tfree :: T
(tfreeN, tfree) = markup_elem \<open>Markup.tfreeN\<close>

tvarN :: String; tvar :: T
(tvarN, tvar) = markup_elem \<open>Markup.tvarN\<close>

freeN :: String; free :: T
(freeN, free) = markup_elem \<open>Markup.freeN\<close>

skolemN :: String; skolem :: T
(skolemN, skolem) = markup_elem \<open>Markup.skolemN\<close>

boundN :: String; bound :: T
(boundN, bound) = markup_elem \<open>Markup.boundN\<close>

varN :: String; var :: T
(varN, var) = markup_elem \<open>Markup.varN\<close>

numeralN :: String; numeral :: T
(numeralN, numeral) = markup_elem \<open>Markup.numeralN\<close>

literalN :: String; literal :: T
(literalN, literal) = markup_elem \<open>Markup.literalN\<close>

delimiterN :: String; delimiter :: T
(delimiterN, delimiter) = markup_elem \<open>Markup.delimiterN\<close>

inner_stringN :: String; inner_string :: T
(inner_stringN, inner_string) = markup_elem \<open>Markup.inner_stringN\<close>

inner_cartoucheN :: String; inner_cartouche :: T
(inner_cartoucheN, inner_cartouche) = markup_elem \<open>Markup.inner_cartoucheN\<close>

inner_commentN :: String; inner_comment :: T
(inner_commentN, inner_comment) = markup_elem \<open>Markup.inner_commentN\<close>


token_rangeN :: String; token_range :: T
(token_rangeN, token_range) = markup_elem \<open>Markup.token_rangeN\<close>


sortingN :: String; sorting :: T
(sortingN, sorting) = markup_elem \<open>Markup.sortingN\<close>

typingN :: String; typing :: T
(typingN, typing) = markup_elem \<open>Markup.typingN\<close>

class_parameterN :: String; class_parameter :: T
(class_parameterN, class_parameter) = markup_elem \<open>Markup.class_parameterN\<close>


{- antiquotations -}

antiquotedN :: String; antiquoted :: T
(antiquotedN, antiquoted) = markup_elem \<open>Markup.antiquotedN\<close>

antiquoteN :: String; antiquote :: T
(antiquoteN, antiquote) = markup_elem \<open>Markup.antiquoteN\<close>


{- text structure -}

paragraphN :: String; paragraph :: T
(paragraphN, paragraph) = markup_elem \<open>Markup.paragraphN\<close>

text_foldN :: String; text_fold :: T
(text_foldN, text_fold) = markup_elem \<open>Markup.text_foldN\<close>


{- outer syntax -}

keyword1N :: String; keyword1 :: T
(keyword1N, keyword1) = markup_elem \<open>Markup.keyword1N\<close>

keyword2N :: String; keyword2 :: T
(keyword2N, keyword2) = markup_elem \<open>Markup.keyword2N\<close>

keyword3N :: String; keyword3 :: T
(keyword3N, keyword3) = markup_elem \<open>Markup.keyword3N\<close>

quasi_keywordN :: String; quasi_keyword :: T
(quasi_keywordN, quasi_keyword) = markup_elem \<open>Markup.quasi_keywordN\<close>

improperN :: String; improper :: T
(improperN, improper) = markup_elem \<open>Markup.improperN\<close>

operatorN :: String; operator :: T
(operatorN, operator) = markup_elem \<open>Markup.operatorN\<close>

stringN :: String; string :: T
(stringN, string) = markup_elem \<open>Markup.stringN\<close>

alt_stringN :: String; alt_string :: T
(alt_stringN, alt_string) = markup_elem \<open>Markup.alt_stringN\<close>

verbatimN :: String; verbatim :: T
(verbatimN, verbatim) = markup_elem \<open>Markup.verbatimN\<close>

cartoucheN :: String; cartouche :: T
(cartoucheN, cartouche) = markup_elem \<open>Markup.cartoucheN\<close>

commentN :: String; comment :: T
(commentN, comment) = markup_elem \<open>Markup.commentN\<close>


{- messages -}

writelnN :: String; writeln :: T
(writelnN, writeln) = markup_elem \<open>Markup.writelnN\<close>

stateN :: String; state :: T
(stateN, state) = markup_elem \<open>Markup.stateN\<close>

informationN :: String; information :: T
(informationN, information) = markup_elem \<open>Markup.informationN\<close>

tracingN :: String; tracing :: T
(tracingN, tracing) = markup_elem \<open>Markup.tracingN\<close>

warningN :: String; warning :: T
(warningN, warning) = markup_elem \<open>Markup.warningN\<close>

legacyN :: String; legacy :: T
(legacyN, legacy) = markup_elem \<open>Markup.legacyN\<close>

errorN :: String; error :: T
(errorN, error) = markup_elem \<open>Markup.errorN\<close>

reportN :: String; report :: T
(reportN, report) = markup_elem \<open>Markup.reportN\<close>

no_reportN :: String; no_report :: T
(no_reportN, no_report) = markup_elem \<open>Markup.no_reportN\<close>

intensifyN :: String; intensify :: T
(intensifyN, intensify) = markup_elem \<open>Markup.intensifyN\<close>


{- output -}

type Output = (String, String)

no_output :: Output
no_output = ("", "")
\<close>

generate_haskell_file XML.hs = \<open>
{-  Title:      Tools/Haskell/XML.hs
    Author:     Makarius
    LICENSE:    BSD 3-clause (Isabelle)

Untyped XML trees and representation of ML values.
-}

module Isabelle.XML (Attributes, Body, Tree(..), wrap_elem, unwrap_elem, content_of)
where

import qualified Data.List as List

import Isabelle.Library
import qualified Isabelle.Properties as Properties
import qualified Isabelle.Markup as Markup
import qualified Isabelle.Buffer as Buffer


{- types -}

type Attributes = Properties.T
type Body = [Tree]
data Tree = Elem Markup.T Body | Text String


{- wrapped elements -}

wrap_elem (((a, atts), body1), body2) =
  Elem (\<open>XML.xml_elemN\<close>, (\<open>XML.xml_nameN\<close>, a) : atts) (Elem (\<open>XML.xml_bodyN\<close>, []) body1 : body2)

unwrap_elem
  (Elem (\<open>XML.xml_elemN\<close>, (\<open>XML.xml_nameN\<close>, a) : atts) (Elem (\<open>XML.xml_bodyN\<close>, []) body1 : body2)) =
  Just (((a, atts), body1), body2)
unwrap_elem _ = Nothing


{- text content -}

add_content tree =
  case unwrap_elem tree of
    Just (_, ts) -> fold add_content ts
    Nothing ->
      case tree of
        Elem _ ts -> fold add_content ts
        Text s -> Buffer.add s

content_of body = Buffer.empty |> fold add_content body |> Buffer.content


{- string representation -}

encode '<' = "&lt;"
encode '>' = "&gt;"
encode '&' = "&amp;"
encode '\'' = "&apos;"
encode '\"' = "&quot;"
encode c = [c]

instance Show Tree where
  show tree =
    Buffer.empty |> show_tree tree |> Buffer.content
    where
      show_tree (Elem (name, atts) []) =
        Buffer.add "<" #> Buffer.add (show_elem name atts) #> Buffer.add "/>"
      show_tree (Elem (name, atts) ts) =
        Buffer.add "<" #> Buffer.add (show_elem name atts) #> Buffer.add ">" #>
        fold show_tree ts #>
        Buffer.add "</" #> Buffer.add name #> Buffer.add ">"
      show_tree (Text s) = Buffer.add (show_text s)

      show_elem name atts =
        unwords (name : map (\(a, x) -> a ++ "=\"" ++ show_text x ++ "\"") atts)

      show_text = concatMap encode
\<close>

generate_haskell_file YXML.hs = \<open>
{-  Title:      Tools/Haskell/YXML.hs
    Author:     Makarius
    LICENSE:    BSD 3-clause (Isabelle)

Efficient text representation of XML trees.  Suitable for direct
inlining into plain text.
-}

module Isabelle.YXML (charX, charY, strX, strY, detect,
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
\<close>

end
