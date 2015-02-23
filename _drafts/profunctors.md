---
layout: post
title: "What are profunctors?"
author: hao
---

* I get curious about the lenses I'm using. When I write `"5" ^?
   _Number` while [jazzing around JSON][3], I wonder how `_Number` is
   implemented in [lens-aeson][1]. <em>I Hoogle/Hayoo over to `_Number`.</em>

* I see `_Number :: Prism' t Scientific` and note that `t` is a type
  variable constrained by `AsNumber t`. The instances of `AsNumber`
  are mostly strings and bytes, so I gently substitute `Text` for `t`.

    `_Number :: Prism' Text Scientific` makes sense to me because the
    value `"5" ^? _Number` must be the `Scientific` (the Part) read out
    from `"5"`'s data type `Text` (the Whole). `Prism'` must be
    parametrized over the whole and the part, like `Lens'`.

    _I click over to `Prism'`._

* I see that `Prism'` is aliased to `Prism`, with `s = t` and `a = b`.
  I deduce that the prism `_Number` is simple, in the same way that
  `type Lens' s a = Lens s s a a` is simple: the type variables stay
  constant during a setting operation.

    This checks out. `"5" & _Number .~ 10 -- "10"` should neither
    return a non-`Text` value, nor should it twiddle with the
    `Scientific` nature of the old number `5`.

    _I click over to `Prism`, the fully generalized prism type._

* I see that `Prism` is `type Prism s t a b = forall p f. (Choice p,
  Applicative f) => p a (f b) -> p s (f t)`. The quantified `f` tells
  me that every prism is a traversal, which is something I've read and
  is also [charted front-and-center][2] in the documentation.

    But what is `p`? _I click over to `Choice`._

* [Choice is defined as a subclass of `Profunctor`][choice]. And so
  I'm stuck, and I'm stuck on this seemingly simple question:

[0]: http://hackage.haskell.org/package/lens
[1]: https://hackage.haskell.org/package/lens-aeson-1.0.0.3/docs/Data-Aeson-Lens.html
[2]: chart
[3]: jazzing
[choice]: http://hackage.haskell.org/package/lens-4.7/docs/Control-Lens-Prism.html#t:Choice

What are profunctors?

The go-to answer is [sigfpe's "Profunctors in Haskell" post][sigfpe],
but it requires a little knowledge of category theory. The crux is:

> There are lots of analogies for thinking about profunctors. For
> example, some people think of them as generalising functors in the
> same way that relations generalise functions. More specifically,
> given a function f:A→B, f associates to each element of A, a single
> element of B. But if we want f to associate elements of A with
> elements of B more freely, for example 'mapping' elements of A to
> multiple elements of B then we instead use a relation which can be
> written as a function f:A×B→{0,1} where we say xfy iff f(x,y)=1. In
> this case, profunctors map to Set rather than {0,1}.&nbsp;&nbsp;<cite>Dan Piponi</cite>

I know a little set theory but zero category theory, so while the SAT
analogy of relations:functions :: profunctors:functors is interesting
to me, I think I lack the intuition / heart-of-the-cards required to
glean true wisdom from it.

For example: while I understand that Hask<sup>op</sup> is the
[dual][d] of D, I have a hard time reconciling the two definitions.

* Definition (1) says a profunctor is the functor Hask<sup>op</sup> × Hask → Hask

* Definition (2) says a profunctor is

    ```haskell
    class Profunctor p where
      -- law: dimap (f . g) (h . i) ≡ dimap g h . dimap f i
      dimap :: (a -> b) -> (c -> d) -> p b c -> p a d
    ```

(Messy authorial thought process here! Hask is the category where
objects are Haskell types and the morphism from object _A_ to object
_B_ is _A_ → _B_. And Hask<sup>op</sup> × Hask is also a category. `p`
must be the functor from Hask<sup>op</sup> × Hask to Hask
[laws and all] and ... so `p b c` and `p a d` must be the
"destination" of that functor? The laws for `p` must imply and is
implied by the law for `dimap` in that typeclass? I have a shaky
knowledge of those laws and I don't know duals
[Hask<sup>op</sup> is the "dual" of Hask].)

[sigfpe]: http://blog.sigfpe.com/2011/07/profunctors-in-haskell.html
[d]: http://en.wikipedia.org/wiki/Dual_%28category_theory%29

So instead I've begun drawing this little painting out in my head:

## A portrait of a profunctor as a young artist

This is what a profunctor is. A type constructor `p` with kind `* -> *
-> *`is profunctor iff

* Whenever you have a function `a -> b`
* & a function `c -> d`
* & a value `p b c`

as depicted here:

```
a -------> b
         ~
       ~
     p
   ~
 ~
c -------> d
```

there exists a value `p a d`. That is, I'm able to complete the
diagram (exclamation marks):

```
a -------> b
 !       ~
   !   ~
     p
   ~   !
 ~       !
c -------> d
```

(On paper, I get to draw diagonal arrows instead of ASCII. Dream with
me here.)

## The easiest-to-understand profunctor

The easiest-to-understand profunctor is `(->)`. It's a type
constructor of kind `* -> * -> *`; so far, so good. And given this:

```
a -------> b
         -
       -
    (->)
   -
 -
c -------> d
```

I'm confident I can give you `(->) a d`. Because: given two functions
`a -> b` / `c -> d` and given the value `(->) b c`, I can give you
`(->) a d` simply by composing with the dot operator twice. From
[Data.Profunctor](https://hackage.haskell.org/package/profunctors-3.1.1/docs/src/Data-Profunctor.html):

```haskell
instance Profunctor (->) where
  dimap ab cd bc = cd . bc . ab
```

## A slightly-harder-to-understand profunctor

A slightly-harder-to-understand profunctor is the `Klesli` arrow:

```haskell
newtype Klesli m a b = Klesli { unKlesli :: a -> m b }
```

It too has kind `* -> * -> *` and again we make an "Oh, good" noise. 
