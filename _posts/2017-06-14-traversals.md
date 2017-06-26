---
layout: post
title: "Traversals and Bazaars: a Rambling, In-Depth Guide That Nobody Asked For"
author: hao
---

Welcome back to another episode of _Lens: Apocrypha_.

## Traversable

Our story begins with the humble `Traversable` typeclass:

``` haskell
class (Functor t, Foldable t) => Traversable t where
  traverse :: Applicative f => (a -> f b) -> t a -> f (t b)
```

These are defined, characterized, and thoroughly investigated in McBride and Paterson's 2008 paper, ["Applicative Programming with Effects"](http://www.staff.city.ac.uk/~ross/papers/Applicative.pdf). Let's say this up top: this is not a casual use of typeclasses. It is not immediately obvious, nor should it be, why this typeclass encodes iteration into a variety of higher-kinded datatypes in Haskell.

To borrow examples from the 2008 paper, let us implement `sequence` (run a list of `IO` actions, collecting results) and `transpose` (matrix tranposition) in Haskell:

``` haskell
sequence :: [IO a] -> IO [a]
sequence [] = return []
sequence (io:ios) = do
  a <- io
  as <- sequence ios
  return (a:as)

transpose :: [[a]] -> [[a]]
transpose [] = []
transpose (xs:xss) = zipWith (:) xs (transpose xss)
```

Both functions take a functor of a functor of an `a`; both "swap" the functors. In the first example, a list of I/O actions becomes an I/O of a list. In the second example a row list of column lists becomes a column list of row lists.

As the smiling men dressed in polo T-shirts would say, that's not all. Define, if you will:

``` haskell
pureIO :: a -> IO b
pureIO a = return a

apIO :: IO (a -> b) -> IO a -> IO b
apIO fIO aIO = do
  f <- fIO
  a <- aIO
  return (f a)

pureZip :: a -> [a]
pureZip = repeat

apZip :: [a -> b] -> [a] -> [b]
apZip (f:fs) (x:xs) = (f x):(apZip fs xs)
apZip _ _ = []
```

Then:

``` haskell
sequence []  = pureIO []
sequence (io:ios) = pureIO (:) `apIO` io `apIO` sequence ios

transpose [] = pureZip []
transpose (xs:xss) = pureZipList (:) `apZip` xs `apZip` transpose xss
```

This all suggests that there should be a typeclass that contains `pure` and `ap`; thus was born `Applicative`. Note that the above code also acts as a proof by contradiction that `Applicative` sits _above_ `Monad`: it's impossible to implement a lawful `Monad` instance for zip-lists but it is possible to implement an `Applicative` instance from any `Monad` instance.

Fun fact: applicative functors were originally called _idioms_ because they could be sugared up inside _idiom brackets_:

``` haskell
sequence (io:ios) = [[ (:) io (sequence ios) ]]
transpose (xs:xss) = [[ (:) xs (transpose xss) ]]
```

Inside idiom brackets the ` ` (function application) operator is overloaded and calls to `pure` are automatically inserted to point any argument into the applicative functor. This never caught on but we will cheerfully use it in our code examples. (Also, selfishly, I hiding behind the syntax in order to avoid defining a `ZipList` newtype.)

Now note that `sequence` and `transpose` are both special cases of

``` haskell
dist :: Applicative f => [f a] -> f [a]
dist [] = [[ [] ]]
dist (fa:fas) = [[ (:) fa (dist fas) ]]

sequence = dist
transpose = dist
```

But also note that we can abstract like this:

``` haskell
traverse :: Applicative f => (a -> f b) -> [a] -> f [b]
traverse f [] = [[ [] ]]
traverse f (a:as) = [[ (:) (f a) (traverse f as) ]]

dist = traverse id
```

Does it matter which abstraction we pick? No: `dist = traverse id` and `traverse f = sequence . map f`. We can say that having one implies the other, even if we might want to define both in our instances in order to optimize for space and time.

### Beyond Lists

Given our wild success at generalizing iteration over linked lists into `traverse`/`sequence`, we might ask what other containers and, more generally, types are traversable. First we will need a typeclass:

``` haskell
class Functor t => Traversable t where
  traverse :: Applicative f => (a -> f b) -> t a -> f (t b)
  sequence :: Applicative f => t (f a) -> f (t a)

instance Traversable [] where
  ...
```

We will inherit from `Functor` because it lets us more generally define `traverse f = sequence . fmap f` (instead of `map f`). Also, we will want the free theorems from the parametricity of the `Functor` type class if we want to derive `Traversable` and its laws, most of which I have skipped here, more rigorously.

So, other datatypes besides lists. As a generality, types that track failure (`Maybe`, `Either e`) also are traversable: to traverse a `Nothing :: Maybe a` or a `Left (x :: e) :: Either e a`, we simply propagate the failure with `pure Nothing :: f (Maybe b)` and `pure (Left x) :: f (Either e b)`. What these types have in common is that they are disjoint unions of the identity type; in the calculus of ADTs we might say that they are constants that become zero when you take the derivative with respect to `a`. We might say that after a few drinks, anyway.

``` haskell
instance Traversable Maybe where
  traverse :: Applicative f => (a -> f b) -> Maybe a -> f (Maybe b)
  traverse visitor Nothing = pure Nothing :: f (Maybe b)
  traverse visitor (Just a) = Just (visitor a)

instance Traversable (Either e) where
  traverse :: Applicative f => (a -> f b) -> Either e a -> f (Either e b)
  traverse visitor (Left e) = pure (Left e) :: f (Either e b)
  traverse visitor (Right a) = Just (visitor a)
```

It is easy to discharge the failure cases with `pure`. In other words, for failure cases, the type `a` becomes a "phantom type" as it does not get used to type `Nothing` and `Left e`; and, since it is a phantom type, we can arbitrarily cast to `b`.

Something else interesting: First, define higher-kinded products and sums.

``` haskell
data Product f g a = Pair (f a) (g a) deriving Functor
data Sum f g a = InL (f a) | InR (g a) deriving Functor
```

Then note that these are traversable! Algebras with functors preserves traversability.

``` haskell
-- | Left as an exericse for the reader.
instance (Traversable f, Traversable g) => Traversable (Product f g) where ...

-- | Left as an exericse for the reader.
instance (Traversable f, Traversable g) => Traversable (Sum f g) where ...
```

This agrees with our discussion of `Maybe` and `Either`, as both can be created algebraically out of the `Sum` and `Const` functors:

``` haskell
import Control.Applicative
import Data.Functor.Identity
newtype Maybe' a = Maybe' (Sum (Const ()) Identity a) deriving Functor
newtype Either' e a = Either' (Sum (Const e) Identity a) deriving Functor
```

### Examples and Analogies from an Unkind World

If we flip `traverse` we get the for-loop we know and love from imperative languages:

``` haskell
for :: (Traversable t, Applicative f) => t a -> (a -> f b) -> f (t b)
for = flip traverse

-- Note: IO is an applicative functor.
main :: IO ()
main = do
  args <- System.Environment.getArgs
  contents <- for args readFile
  print contents
```

If we use `traverse` in conjunction with `Const`, we get something akin to LINQ's `Enumerable.ToList()`. (To date, I cannot think of a better-designed iteration library than LINQ. LINQ is a complete joy to use, and that it can encode SQL is a terrific magic trick.)

``` haskell
import Control.Lens ((^.))
import Data.Aeson (Value)
import Data.Map (Map)
import Network.Wreq

main :: IO ()
main = do
  resp <- get "https://api.github.com/repos/ekmett/lens"
  jsoned <- asJSON resp :: IO (Response (Map String Value))
  print$ traverse (\value -> Const [value]) (jsoned ^. responseBody)
```

This decodes the JSON object in the Github API response into a `Data.Map.Map` of strings mapping to other JSON values; it then traverses the map, collecting the values into a `Const [Value]` applicative functor. It turns out that `Const m` is an applicative functor if `m` is a monoid! For our example we choose `[Value]`, constructing the simplest monoid we can think of out of `Value`s. This code prints:

``` haskell
Const [
    String "https://api.github.com/repos/ekmett/lens/{archive_format}{/ref}",
    String "https://api.github.com/repos/ekmett/lens/assignees{/user}",
    String "https://api.github.com/repos/ekmett/lens/git/blobs{/sha}",
    String "https://api.github.com/repos/ekmett/lens/branches{/branch}",
    String "https://github.com/ekmett/lens.git",
    String "https://api.github.com/repos/ekmett/lens/collaborators{/collaborator}",
    String "https://api.github.com/repos/ekmett/lens/comments{/number}",
    String "https://api.github.com/repos/ekmett/lens/commits{/sha}",
    String "https://api.github.com/repos/ekmett/lens/compare/{base}...{head}",
    String "https://api.github.com/repos/ekmett/lens/contents/{+path}",
    String "https://api.github.com/repos/ekmett/lens/contributors",
    String "2012-07-25T22:00:42Z",
    String "master",
    String "https://api.github.com/repos/ekmett/lens/deployments",
    String "Lenses, Folds, and Traversals - Join us on freenode #haskell-lens",
    String "https://api.github.com/repos/ekmett/lens/downloads",
    String "https://api.github.com/repos/ekmett/lens/events",
    Bool False,
    Number 178.0,
    ...
```

The

## Traversals from Traverse

Let's switch gears to the `lens` package, specifically these two type aliases:

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

Note immediately that we can rewrite the `traverse` type signature we had above as `traverse :: Traversable t => Traversal (t small) small`.

You may have seen `lens` tutorials that start from `Lens` and going up to `Traversal`. But traversals are a better gateway drug for `lens`-style optics than lenses are! Whereas lenses "target" (a hand-waving verb, at best) exactly one part of a bigger data structure, a traversal can target 0, 1, or many -- in generality we find simplicity.

And, whereas the `Lens` type emerges _ex nihilo_, the `Traversal` type already exists in `base`! (This section of the blog post is primarily a summary of the [Derivation wiki entry](https://github.com/ekmett/lens/wiki/Derivation) in ekmett/lens.)

``` haskell
traverse                   :: (Traversable f, Applicative m)
                           => (a -> m b) -> f a         -> m (f b)
traverse.traverse          :: (Traversable f, Traversable g, Applicative m)
                           => (a -> m b) -> f (g a)     -> m (f (g b))
traverse.traverse.traverse :: (Traversable f, Traversable g, Traversable h, Applicative m)
                           => (a -> m b) -> f (g (h a)) -> m (f (g (h b)))
```

This is more than coincidence; it is one of the stated goals of the ekmett/lens project to preserve backwards compatilibity with `base`. That means, for one, that it is axiomatic that `traverse` acts like a valid `Traversal`. That is, it must compose with any other `Traversal` optic we define.

Indeed, what keeps the `lens` package from adopting Purescript-like profunctor-based optics -- frequent _Spoke Proof_ post fodder -- is that you cannot express `traverse` in both profunctor form and this form.

## Quickly Deriving `Traversal` from `traverse`

How did this `Traversal` type come to be?

If we treat functional references as a pair of getters and setters, we can think of `traverse` from `base` as the "get" end. It allows us to read the small parts of a bigger data structure into any `Applicative` container we want. For example

``` haskell
ghci>
```

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
  (toListOf traversal big, over traversal (\_ -> small) big)
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

Anyway, if we ignore defining exactly what `Bazaar` _is_ we can loosely outline how it works:

* `atraversal` is a promise that, should it be given a `a -> Bazaar a b b`, it will give us back an `f t`
* We, puzzled, look around the room for an `a -> Bazaar a b b`; we find none
* Meanwhile, we trying to construct a generic traversal
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

### lens

This is pulled straight from `lens`, sort of. `lens` is made complicated by prisms and indexed optics, which forces it to use its profunctors-with-an-extra-f representation. However, if we just restrict ourselves for the time being to traversals and optics, we can fix any profunctor type variable `p` we see to be `p ~ (->)`. As a result, a lot of the `Corepresentable p => Sellable p (Bazaar p), Profuntor p => Bizarre p (Bazaar p)` instances can be thrown away with their resulting definitions inlined and simplified. Anyway if you somehow got something out of this guide I recommend you go read the source code in `Control.Lens.Internal.Context` to see how all this _can_ be (abstrusely) generalized to support all the optics in the `lens` packge.

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




## incoming

doug [Jun 16]
`foldMapDefault` was confusing to me because I didn't realize `Const` was an applicative if its held value was a monoid, which you brought up not too much later. I know that it's part of `Data.Traversable`; I guess what I'm saying is that I missed the point that you were making where we are just replacing the `traverse` with `l`, and I instead tried to make sense of the whole thing.

doug [Jun 16]
You defined `over` for the crowd but used `set`, so maybe provide a definition of that in terms of `over`?

doug [Jun 16]
I got so confused because you named an argument `fold` and I thought you meant `Data.Foldable.fold` and couldn't figure out how in the world that typechecked

doug [Jun 16]
What is this syntax? `ReifiedTraversal { Traversal s t a b }`

doug [Jun 16]
What's the type of top-level `foo` that would make this work like you said? I can't find one

doug [Jun 16]
Maybe sidebar the "This is pulled straight from lens" paragraph? I think the walkthrough in bullets below should come more naturally after the code

doug [Jun 16]
What about adding the `clone` usage in the `Bazaar` code snippet? I can't get it to work with just `clone traversal` because I don't think `ATraversal s t a b :: Traversal s t a b` unifies like you said it should? Is `Bazaar` missing an applicative instance? (I went back and added an applicative instance and it works)

doug [Jun 16]
Aside: I cannot get this to typecheck:

```foo' :: Traversal s t a b -> s -> [a]
foo' traversal big = toListOf traversal big
```

but if I change it to `Traversal s s a a`, it works. The error is

```Expected type: (a -> ap a) -> s -> ap s
  Actual type: (a -> ap b) -> s -> ap t
```

Also if I use a `(s ~ t, a ~ b)` constraint, it works. What am I not understanding?

doug [Jun 16]
That's all I got. It was really informative, and to my surprise, I think I understand it. It feels so weird though. Uncomfortably weird.

hao [Jun 17]
ooh great feedback!

hao [Jun 17]
xoxoxox

hao [Jun 17]
yeah, not all the combinators work on stab form

hao [Jun 17]
i was careless

hao [Jun 17]
ssaa is the right type you did good

hao [Jun 17]
it's a weird data structure

hao [Jun 17]
like a linked list on mushrooms
