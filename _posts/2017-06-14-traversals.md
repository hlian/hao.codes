---
layout: post
title: "Traversals and Bazaars: a Rambling, In-Depth Guide That Nobody Asked For"
author: hao
---

Maybe at this point I should rename Spoke Proof to _Lens Apocrypha_.

OK so by now you may have seen this:

``` haskell
{-# LANGUAGE RankNTypes #-}
type Lens big small =
  forall f. Functor f => (small -> f small) -> big -> f big
type Traversal big small =
  forall ap. Applicative ap => (small -> ap small) -> big -> ap big
  
-- note that if `optic :: Lens big small`,
-- then `optic :: Traversal big small` also
-- because `Applicative` inherits from `Lens`
```

And you may have seen lens tutorials trying to start from `Lens` and going up to `Traversal`. But here's a controversial opinion: traversals are a better gateway drug for `lens`-style optics than lenses are. Whereas lenses "target" (an overloaded hand-wavey term at best) exactly one part of a bigger data structure, a traversal can target 0, 1, or many -- in generality we find simplicity. And whereas the `Lens` type comes out of seemingly nowhere, the `Traversal` type already exists in `base`!

``` haskell
traverse                   :: (Traversable f, Applicative m)
                           => (a -> m b) -> f a         -> m (f b)
traverse.traverse          :: (Traversable f, Traversable g, Applicative m)
                           => (a -> m b) -> f (g a)     -> m (f (g b))
traverse.traverse.traverse :: (Traversable f, Traversable g, Traversable h, Applicative m)
                           => (a -> m b) -> f (g (h a)) -> m (f (g (h b)))
```

The above snippet comes from the oft-cided [Derivation article](https://github.com/ekmett/lens/wiki/Derivation) of the lens project. Note that `traverse :: Traversable t => Traversal (t small) small`.

Indeed, what keeps the `lens` package from adopting Purescript-like profunctor-based optics is that it attempts to maintain "backwards compatibility" with `traverse`.

## Quickly deriving `Traversal` from `traverse`

(This is just a re-arrangement of the Derviation article.)

We know that traversals should support setters and we know what `over` should look like from every lens tutorial on the internet; this naturally constrains the optic it takes to be `Identity`.

``` haskell
ghci> let over l f = runIdentity . l (Identity . f)
ghci> :t over
over :: ((a -> Identity b) -> s -> Identity t) -> (a -> b) -> s -> t
```

There are some laws we need to verify but we will glide past them.

We also know that traversals should be able to "get" 0, 1, ∞ parts of a value. We can start with `foldMapDefault`

``` haskell
foldMapDefault :: (Traversable t, Monoid m) => (a -> m) -> t a -> m
foldMapDefault f = getConst . traverse (Const . f)
```

We want to abstract out the `traverse` and so we get

``` haskell
ghci> let foldMapOf l f = getConst . l (Const . f)
ghci> :t foldMapOf
foldMapOf :: ((a -> Const r b) -> s -> Const r t) -> (a -> r) -> s -> r
```

So now we have two different concrete types for a traversal:

``` haskell
(a -> Identity b) -> s -> Identity t
(a -> Const r b) -> s -> Const r t
```

What unifies `Identity` and `Const r`? Nothing! However, if we attach a `Monoid r` constraint

``` haskell
(a -> Identity b) -> s -> Identity t
Monoid r => (a -> Const r b) -> s -> Const r t
```

all of a sudden we can take advantage of the `Monoid r => Applicative (Const r)` instance that exists in `Control.Applicative`. This yields us our standard s-t-a-b traversal:

``` haskell
type Traversal s t a b =
  forall ap. Applicative ap => (a -> ap b) -> s -> ap t
```

There are more laws we will glide past happily.

## Clones, Reification, and `Bazaar`s

Let's take a sharp left turn. Say I want to write a function that uses a traversal twice: once to write, once to read:

``` haskell
type Traversal big small =
  forall ap. Applicative ap => (small -> ap small) -> big -> ap big

-- | Traverses a value of type big, accumulating the result in monoid mon
foldMapOf :: Monoid mon => Traversal big small -> (small -> mon) -> big -> mon
foldMapOf traversal fold =
  getConst . traversal (Const . fold)

-- | foldMapOf with mappend/mzero inlined
foldrOf :: Traversal big small -> (small -> r -> r) -> r -> big -> r
foldrOf traversal fold zero =
  \big -> appEndo (foldMapOf traversal (Endo . fold) big) zero

-- | toListOf stuffs all the targets of a traversal into a list
toListOf :: Traversal big small -> big -> [small]
toListOf traversal = foldrOf traversal (:) []

foo traversal big small =
  (toListOf traversal big, set traversal small big)
```

This will not typecheck, even though it should!

```
• Couldn't match type ‘ap’ with ‘Identity’
  ‘ap’ is a rigid type variable bound by
    a type expected by the context:
      forall (ap :: * -> *).
      Applicative ap =>
      (small -> ap small) -> big -> ap big
    at /Users/h/m/scratch/src/Clone.hs:37:29
  Expected type: (small -> ap small) -> big -> ap big
    Actual type: (small -> Identity small) -> big -> Identity big
• In the first argument of ‘toListOf’, namely ‘traversal’
  In the expression: toListOf traversal big
  In the expression:
    (set traversal small big, toListOf traversal big) (haskell-hdevtools)
```

What happens here is that `toListOf` and `set` are having a tug-of-war over what `ap` should be: `toListOf` wants the `ap ~ m, Monoid m => Applicative (Const m)` instance and `set` wants the `Identity ~ m, Applicative Identity` instance. Because Haskell enforces the [monomorphism restriction](https://wiki.haskell.org/Monomorphism_restriction), the type inferencer will be unable to ever correctly infer the type of `ap`.

Note that we _could_ remove the restriction but, as the Haskell wiki details, we would run into (1) ambiguous types and (2) possibly terrible runtime performance. Nobody said that living at the bleeding edge of typed functional programming would be easy.

Now, in our example, we can wave the problem away by giving `foo` a type-signature. As it _is_ a top-level definition we should be doing so anyway. But this problem can come up in more complicated functions, where the expression that would trigger this type error would be deeply nested. Being awesome library authors, we want to provide a "cloning" function that will _fix `ap` as generically as possible_ so that it can later be turned back into a generic traversal.

That is, we want to find some type `ATraversal` such that

``` haskell
type ATraversal s t a b = ???

clone :: ATraversal s t a b -> Traversal s t a b
clone = ???

foo traversal big small =
  (toListOf (clone traversal) big, set (clone traversal) small big)
```

_and_ `ATraversal s t a b :: Traversal s t a b` unifies. This last note is important because it precludes the simplest solution, which is reification:

``` haskell

newtype ReifiedTraversal s t a b =
  ReifiedTraversal { Traversal s t a b } 

clone :: ReifiedTraversal s t a b -> Traversal s t a b
clone (ReifiedTraversal traversal) = traversal

foo traversal big small =
  (toListOf (clone . ReifiedTraversal $ traversal) big,
   set (clone . ReifiedTraversal $ traversal) small big)
```

Here we introduce a newtype but it comes at the penalty of forcing users to call into the newtype. This is good ... but not _great_.

Let us now pause in the text so the reader can go out and try to figure out the answer.

Back already? No answer? It's OK. The answer to this problem is fucking bizarre. It's `Bazaar`:

``` haskell
newtype Bazaar a b t =
  Bazaar { runBazaar :: forall ap. Applicative ap => (a -> ap b) -> ap t }
  deriving Functor

type Traversal s t a b =
  forall ap. (Applicative ap) => (a -> ap b) -> s -> ap t

-- | Traversal except without the ap floating around
type ATraversal s t a b =
  (a -> Bazaar a b b) -> s -> Bazaar a b t

clone :: ATraversal s t a b -> Traversal s t a b
clone atraversal =
  \a2apb s -> do
    let Bazaar baz = atraversal (\a -> Bazaar (\a2apb -> a2apb a)) s
    baz a2apb
```

This is pulled straight from `lens`, sort of. `lens` is made complicated by prisms and indexed optics, which forces it to use its profunctors-with-an-extra-f representation. However, if we just restrict ourselves for the time being to traversals and optics, we can fix any profunctor type variable `p` we see to be `p ~ (->)`. As a result, a lot of the `Corepresentable p => Sellable p (Bazaar p), Profuntor p => Bizarre p (Bazaar p)` instances can be thrown away with their resulting definitions inlined and simplified. Anyway if you somehow got something out of this guide I recommend you go read the source code in `Control.Lens.Internal.Context` to see how all this _can_ be (abstrusely) generalized to support all the optics in the `lens` packge.

Anyway, if we ignore defining exactly what `Bazaar` _is_ we can loosely outline how it works:

* `atraversal` is a promise that, should it be given a `a -> Bazaar a b b`, it will give us back an `f t`
* We, puzzled, look around the room for an `a -> Bazaar a b b`; we find none
* Meanwhile, we trying to construct a generic traversal
n
* We are given a traversal where `ap ~ Bazaar a b` has been fixed [*]
* `Bazaar a b t` is exactly `Traversal s t a b` except it has already been applied to a value (the `s` is gone)
* We use the traversal to traverse through `s` once
* At each element `a` of `s` we construct a `Bazaar a b a`
* A traversal's job is to upgrade an `a -> ap b` to an `s -> ap t`
* So this traveral-and-Bazaar tap dance gets us back an `s -> Bazaar a b t`, which when applied to `s`
* Gets us an `Bazaar a b t`, which when applied to `a2apb :: a -> ap b`
* Gets us an `f t`

More simply: `Bazaar` acts like a list of `a`. We started out asking ourselves what the _most generic_ `ap` we could pick for `Traversal` could be (since we _had_ to pick one). So we knew that whatever the answer was that it had to store all the elements `a` we found in `s` as we traversed it. But rather than storing `a` directly (as a list would), we store these thunks `(a -> ap b) -> ap b`. Each bazaar we make in `clone` is a tiger lying in wait for an `a -> ap b` value; as soon as it is given one it pounces by applying the `a` it had been storing all along.

It is the machinery of traversals that then kicks in and upgrades this from an `ap b` to an `ap t`.

I confess that this only makes partial sense to me. It is that teach-yourself-more-and-more-Haskell feeling of understanding something 10% more each time you come back to it, and concentrating on moving forward for the time being rather than being stuck on one thing.

If you want to read more on this derivation, see [the blog post by Twan van Laarhoven](https://twanvl.nl/blog/haskell/non-regular1), in which he presents a non-Church-encoded version of `Bazaar` called `FunList`. The comments on that blog post prove an equivalence between his type and `Bazaar`. I think it is the Church encoding (sometimes called a [final encoding](http://okmij.org/ftp/tagless-final/index.html)) of the data type that obfuscates true intuition here.

It might also be helpful to compare these notes against the official documentation for Bazaar:

> * This is used to characterize a `Traversal`.
> * a.k.a. indexed Cartesian store comonad, indexed Kleene store comonad, or an indexed `FunList`.
> * A `Bazaar` is like a `Traversal` that has already been applied to some structure.
> * Where a `Context a b t` holds an `(a, b -> t)`, a `Bazaar a b t` holds N `a`s and a function from N `b`s to `t`, (where N might be infinite).
> * Mnemonically, a Bazaar holds many stores and you can easily add more.
> * This is a final encoding of Bazaar.

## `singular`

Because Functor is more general than Applicative, all lenses are traversals. The magic of the `lens` library design is that this happens automatically without any additional code, that even though we live in a language without subtyping we can encode this idea with typeclasses, parametricity, and carefully-reasoned optical laws.

However, `lens` provides this intriguing and unsafe helper:

```haskell
singular :: Traversal s t a a -> Lens s t a a
singular = ???

-- >>> [1,2,3] ^. singular _head
-- 1

-- >>> [1..10] ^. singular (ix 7)
-- 8

-- >>> [1..10] & singular (ix 7) .~ 100
-- [1,2,3,4,5,6,7,100,9,10]
```

It works like this: if you know that a traversal will target more than zero `a` values in `s`, you can convert it to a lens. If it targets zero values, you will get back a lens that will `error` out into bottom at runtime.

It turns out that implementing this function is simple now that we have armed ourselves with `Bazaar`:

```haskell
singular :: Traversal s t a a -> Lens s t a a
singular traversal =
  \a2fa s -> do
    let baz = traversal (\a -> Bazaar ($ a)) s
    case toListOf traversal s of
      (a:as) -> fmap (\a' -> smush baz (a':as)) (a2fa a)
      [] -> fmap (\_ -> smush baz []) (a2fa (error "singularity"))
```

Once again we traverse `s`, storing each `a` inside these bazaar thunks. Each thunk is `Bazaar a b b` and the traversal upgrades all these into a `Bazaar a b t`. Same as before.

We then traverse `s` _again_ (I think the `lens` library has figured out how to traverse only once, but I was unable to get it to work? Warrants further investigation. Something about the `getting` optic.) and see how many values the traversal targeted.

If there is one or more value, we are able to safely create an `f a` value, which we cons with the tail to get `f [a]`. Then this function kicks in:

``` haskell
unconsWithDefault :: a -> [a] -> (a,[a])
unconsWithDefault d []     = (d,[])
unconsWithDefault _ (x:xs) = (x,xs)

-- | A state machine that pops off one b each time it runs
gobble :: State [b] b
gobble = state (unconsWithDefault (error ""))

-- | Assuming bazaar was constructed on a list of size N, runs gobble N times
smush :: Bazaar a b t -> [b] -> t
smush (Bazaar bazaar) bs = evalState (bazaar (\_ -> gobble)) bs
```


