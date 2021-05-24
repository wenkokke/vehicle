{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE FlexibleInstances   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications    #-}
{-# LANGUAGE TypeFamilies        #-}
{-# LANGUAGE TypeOperators       #-}

module Vehicle.Core.AST.Info where

import Vehicle.Core.AST.Builtin
import Vehicle.Core.AST.Core
import Vehicle.Core.AST.DeBruijn
import Vehicle.Core.AST.Instance ()
import Vehicle.Core.AST.Provenance
import Vehicle.Core.AST.Recursive
import Vehicle.Prelude


-- |Abstract syntax trees, where the representation of names and builtins is fixed.
type ATree (ann :: Sort -> *) (sort :: Sort)
  = Tree DeBruijn Builtin ann sort

type AKind ann = ATree ann 'KIND
type AType ann = ATree ann 'TYPE
type ATArg ann = ATree ann 'TARG
type AExpr ann = ATree ann 'EXPR
type AEArg ann = ATree ann 'EARG
type ADecl ann = ATree ann 'DECL
type AProg ann = ATree ann 'PROG

-- |Abstract syntax trees, where the representation of names and builtins is fixed.
type ATreeF (ann :: Sort -> *) (sort :: Sort) (sorted :: Sort -> *)
  = TreeF DeBruijn Builtin ann sort sorted

type AKindF ann sorted = ATreeF ann 'KIND sorted
type ATypeF ann sorted = ATreeF ann 'TYPE sorted
type ATArgF ann sorted = ATreeF ann 'TARG sorted
type AExprF ann sorted = ATreeF ann 'EXPR sorted
type AEArgF ann sorted = ATreeF ann 'EARG sorted
type ADeclF ann sorted = ATreeF ann 'DECL sorted
type AProgF ann sorted = ATreeF ann 'PROG sorted

-- |Type information, based on sort.
newtype Info (sort :: Sort) = Info { unInfo :: INFO sort }

-- |Computes type information based on sort; kinds for types, types for expressions.
type family INFO (sort :: Sort) where
  INFO 'KIND = ()
  INFO 'TYPE = AKind (Info :*: K Provenance)
  INFO 'TARG = AKind (Info :*: K Provenance)
  INFO 'EXPR = AType (Info :*: K Provenance)
  INFO 'EARG = AType (Info :*: K Provenance)
  INFO 'DECL = ()
  INFO 'PROG = ()

instance KnownSort sort => Eq (Info sort) where
  Info info1 == Info info2 =
    case sortSing @sort of
      SKIND -> info1 == info2
      STYPE -> info1 == info2
      STARG -> info1 == info2
      SEXPR -> info1 == info2
      SEARG -> info1 == info2
      SDECL -> info1 == info2
      SPROG -> info1 == info2

instance Semigroup (Info 'KIND) where
  Info () <> Info () = Info ()

instance Monoid (Info 'KIND) where
  mempty = Info ()

instance Semigroup (Info 'DECL) where
  Info () <> Info () = Info ()

instance Monoid (Info 'DECL) where
  mempty = Info ()

instance Semigroup (Info 'PROG) where
  Info () <> Info () = Info ()

instance Monoid (Info 'PROG) where
  mempty = Info ()

-- * DSL for writing kinds as info annotations

toKind ::
  forall sort. (KnownSort sort, sort `In` ['TYPE, 'TARG]) =>
  Info sort -> AKind (Info :*: K Provenance)
toKind = case sortSing @sort of STYPE -> unInfo; STARG -> unInfo

fromKind ::
  forall sort. (KnownSort sort, sort `In` ['TYPE, 'TARG]) =>
  AKind (Info :*: K Provenance) -> Info sort
fromKind = case sortSing @sort of STYPE -> Info; STARG -> Info

infixl 3 `kApp`

kApp ::
  forall sort. (KnownSort sort, sort `In` ['TYPE, 'TARG]) =>
  Info sort -> Info sort -> Info sort
kApp k1 k2 = fromKind $ KApp mempty (toKind k1) (toKind k2)

infixr 4 ~>

(~>) ::
  forall sort. (KnownSort sort, sort `In` ['TYPE, 'TARG]) =>
  Info sort -> Info sort -> Info sort
k1 ~> k2 = kFun `kApp` k1 `kApp` k2

kFun, kType, kDim, kDimList :: forall sort. (KnownSort sort, sort `In` ['TYPE, 'TARG]) => Info sort
kFun     = fromKind (KCon mempty KFun)
kType    = fromKind (KCon mempty KType)
kDim     = fromKind (KCon mempty KDim)
kDimList = fromKind (KCon mempty KDimList)

-- * DSL for writing types as info annotations

toType ::
  forall sort. (KnownSort sort, sort `In` ['EXPR, 'EARG]) =>
  Info sort -> AType (Info :*: K Provenance)
toType = case sortSing @sort of SEXPR -> unInfo; SEARG -> unInfo

fromType ::
  forall sort. (KnownSort sort, sort `In` ['EXPR, 'EARG]) =>
  AType (Info :*: K Provenance) -> Info sort
fromType = case sortSing @sort of SEXPR -> Info; SEARG -> Info
