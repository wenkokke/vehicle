{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE LambdaCase #-}

{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE FlexibleInstances   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications    #-}
{-# LANGUAGE TypeFamilies        #-}
{-# LANGUAGE TypeOperators       #-}
{-# LANGUAGE OverloadedStrings   #-}

{-# OPTIONS_GHC -Wno-orphans #-}
module Vehicle.Core.Print where

import Data.Maybe (fromMaybe)
import Data.Text (Text, pack, unpack)
import qualified Data.List.NonEmpty as NonEmpty (toList)

import Prettyprinter (Pretty(..), Doc, layoutPretty, parens, brackets, vsep, hsep, (<+>), line, defaultLayoutOptions)
import Prettyprinter.Render.Text (renderStrict)

import Vehicle.Core.AST
import Vehicle.Prelude hiding (line)

printTree :: Pretty a => a -> String
printTree a = unpack $ renderStrict $ layoutPretty defaultLayoutOptions $ pretty a

prettyT :: Text -> Doc a
prettyT = pretty

instance Pretty (K Symbol 'TARG) where
  pretty = pretty . unK

instance Pretty (K Symbol 'TYPE) where
  pretty = pretty . unK

instance Pretty (K Symbol 'EARG) where
  pretty = pretty . unK

instance Pretty (K Symbol 'EXPR) where
  pretty = pretty . unK

instance Pretty (Builtin 'KIND) where
  pretty b = pretty $ fromMaybe (pack ("UNKNOWN KIND BUILTIN" <> show b)) (symbolFromBuiltin b)

instance Pretty (Builtin 'TYPE) where
  pretty b = pretty $ fromMaybe (pack ("UNKNOWN TYPE BUILTIN" <> show b)) (symbolFromBuiltin b)

instance Pretty (Builtin 'EXPR) where
  pretty b = pretty $ fromMaybe (pack ("UNKNOWN EXPR BUILTIN" <> show b)) (symbolFromBuiltin b)

instance Pretty (Kind name ann) where
  pretty = \case
    KApp  _ann k1 k2 -> pretty k1 <+> parens (pretty k2)
    KCon  _ann op    -> pretty op
    KMeta _ann i     -> pretty i

instance Pretty (name 'TARG) => Pretty (TArg name ann) where
  pretty (TArg _ann n) = pretty n

instance ( Pretty (name 'TYPE)
         , Pretty (name 'TARG)
         ) => Pretty (Type name ann) where
  pretty = \case
    TForall     _ann n t   -> prettyT "forall" <+> pretty n <+> pretty t
    TApp        _ann t1 t2 -> pretty t1 <> parens (pretty t2)
    TVar        _ann n     -> pretty n
    TCon        _ann op    -> pretty op
    TLitDim     _ann d     -> pretty d
    TLitDimList _ann ts    -> brackets $ hsep $ map pretty (NonEmpty.toList ts)
    TMeta       _ann i     -> pretty i

instance ( Pretty (name 'TYPE)
         , Pretty (name 'TARG)
         , Pretty (name 'EXPR)
         , Pretty (name 'EARG)
         ) => Pretty (Expr name ann) where
  pretty = \case
    EAnn     _ann e t     -> parens $ pretty e <+> prettyT ":type" <+> pretty t
    ELet     _ann n e1 e2 -> prettyT "let" <+> pretty n <+> pretty e1 <+> pretty e2
    ELam     _ann n e     -> prettyT "lambda" <+> pretty n <+> pretty e
    EApp     _ann e1 e2   -> pretty e1 <+> parens (pretty e2)
    EVar     _ann n       -> pretty n
    ETyApp   _ann e t     -> pretty e <+> pretty t
    ETyLam   _ann n e     -> prettyT "tlambda" <+> pretty n <+> pretty e
    ECon     _ann op      -> pretty op
    ELitInt  _ann z       -> pretty z
    ELitReal _ann r       -> pretty r
    ELitSeq  _ann es      -> brackets $ pretty es

instance Pretty (name 'EARG) => Pretty (EArg name ann) where
  pretty (EArg _ann n) = pretty n

instance ( Pretty (name 'TYPE)
         , Pretty (name 'TARG)
         , Pretty (name 'EXPR)
         , Pretty (name 'EARG)
         ) => Pretty (Decl name ann) where
  pretty = \case
    DeclNetw _ann n t    -> parens $ prettyT "declare-network" <+> pretty n <+> prettyT ":" <+> pretty t <+> line
    DeclData _ann n t    -> parens $ prettyT "declare-dataset" <+> pretty n <+> prettyT ":" <+> pretty t <+> line
    DefType  _ann n ns t -> parens $ prettyT "define-type" <+> pretty n <+> parens (pretty ns) <+> pretty t
    DefFun   _ann n t e  -> parens $ prettyT "define-fun" <+> pretty n <+> pretty t <+> pretty e

instance ( Pretty (name 'TYPE)
         , Pretty (name 'TARG)
         , Pretty (name 'EXPR)
         , Pretty (name 'EARG)
         ) => Pretty (Prog name ann) where
  pretty (Main _ann ds) = vsep (map pretty (NonEmpty.toList ds))
