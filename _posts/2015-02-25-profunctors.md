---
layout: post
title: "What are profunctors? poopmonster"
author: hao
---

## JSON

I get curious about the lenses I'm using. When I write `"5" ^?
   _Number` while [jazzing around JSON][3], I wonder how `_Number` is
   implemented in [lens-aeson][1].

<em>I Hoogle/Hayoo over to `_Number`.</em>

## Numbers

I see `_Number :: Prism' t Scientific` and note that `t` is a type
  variable constrained by `AsNumber t`. The instances of `AsNumber`
  are mostly strings and bytes, so I gently substitute `Text` for `t`.

`_Number :: Prism' Text Scientific` makes sense to me because the
value `"5" ^? _Number` must be the `Scientific` (the Part) read out
from `"5"`'s data type `Text` (the Whole). `Prism'` must be
parametrized over the whole and the part, like `Lens'`.

_I click over to `Prism'`._

## Prism-prime's

I see that `Prism'` is aliased to `Prism`, with `s = t` and `a = b`.
  I deduce that the prism `_Number` is simple, in the same way that
  `type Lens' s a = Lens s s a a` is simple: the type variables stay
  constant during a setting operation.

This checks out. `"5" & _Number .~ 10` (which evalutes to `"10" ::
Text`) should neither return a non-`Text` value, nor should it twiddle
with the `Scientific` nature of the old number `5`.

_I click over to `Prism`, the fully generalized prism type._

## Prisms

I see that `Prism` is `type Prism s t a b = forall p f. (Choice p,
  Applicative f) => p a (f b) -> p s (f t)`. The quantified `f` tells
  me that every prism is a traversal, which is something I've read and
  is also [charted front-and-center][2] in the documentation. But what is `p`?

_I click over to `Choice`._

## Choices

[Choice is defined as a subclass of `Profunctor`][choice]. And so
  I'm stuck, and I'm stuck on this seemingly simple question:

[0]: http://hackage.haskell.org/package/lens
[1]: https://hackage.haskell.org/package/lens-aeson-1.0.0.3/docs/Data-Aeson-Lens.html
[2]: http://i.imgur.com/4fHw3Fd.png
[3]: {% post_url 2015-02-22-lenses-heart-json %}
[choice]: http://hackage.haskell.org/package/lens-4.7/docs/Control-Lens-Prism.html#t:Choice

## What are profunctors?

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
[dual][d] of Hask, I have a hard time reconciling the two definitions.

* Definition (1) says a profunctor is the functor Hask<sup>op</sup> × Hask → Hask

* Definition (2) says a profunctor is

    ```haskell
    class Profunctor p where
      -- law: dimap (f . g) (h . i) ≡ dimap g h . dimap f i
      dimap :: (a -> b) -> (c -> d) -> p b c -> p a d
      ```

The law is important, so let's restate it here: `dimap` distributes
over function composition, where `f . g` splits into `g` and `f`
whereas `h . i` splits into `h` and `i` (the other order). Presumably
the functor laws combined with the first definition yields that type
signature?[^messy] It is opaque to me at the moment, though

[^messy]: Messy authorial thought process here: Hask is the category where objects are Haskell types and the morphism from object _A_ to object _B_ is _A_ → _B_. And Hask<sup>op</sup> × Hask is also a category. `p` must be the functor from Hask<sup>op</sup> × Hask to Hask [laws and all] and ... so `p b c` and `p a d` must be the "destination" of that functor? The laws for `p` must imply and is implied by the law for `dimap` in that typeclass? I have a shaky knowledge of those laws and I don't know duals. ([Hask<sup>op</sup> is the "dual" of Hask.)


[sigfpe]: http://blog.sigfpe.com/2011/07/profunctors-in-haskell.html
[d]: http://en.wikipedia.org/wiki/Dual_%28category_theory%29

However, I think I have stumbled upon a metaphorical conceit that you
can use to understand profunctors without understanding category
theory. You can draw out this little painting instead.

## A portrait of a profunctor as a young artist

Promise: no category theory, no duals, no mention of functors.

Say you have a type constructor `p` with kind `* -> * -> *` and a
function `a -> b` and a function `c -> d` and a value `p b c` as
depicted here.

```
a -------> b
         ~
       ~
     p
   ~
 ~
c -------> d
```

Legend: the straight arrows mean "function arrow" and the curly tildes
mean <code>b &#96;p&#96; c</code>. Then `p` is a profunctor iff there
exists a value `p a d` or, equivalently, <code>a &#96;p&#96; d</code>.
That is, I'm able to complete the diagram with another curly arrow:

```
a -------> b
 ~       ~
   ~   ~
     p
   ~   ~
 ~       ~
c -------> d
```

(On paper, I get to draw curly arrows instead of ASCII. Dream with me
here.)

## The easiest-to-understand profunctor

The easiest-to-understand profunctor is `(->)`. It's a type
constructor of kind `* -> * -> *`; so far, so good. And given this:

```
a -------> b
         /
       /
    (->)
   /
 /
c -------> d
```

The question is: can we find a value of type `(->) a d`?

I've drawn the diagram very suggestively. Where the curly arrow is
supposed to be, I've drawn a straight arrow. That's because `(-> b c)`
is equivalent to `b -> c`. A trite observation perhaps, but this was a
minor epiphany for me. Whenever you see `Profunctor p =>` in a type
signature, substitute in `(->)` for `p` and see if the type then makes
sense to you. `(->)` is the most intuitive instance of `Profunctor`,
so it serves as a sanity check for the confused reader.

So the new question is: can we find a value of type `a -> d`?

Sure! Given two functions `a -> b` / `c -> d` and given the value
`b -> c`, I can give you `a -> d` simply by function composition.

Thus the diagram is completed:

```
a -------> b
  \      /
    \  /
    (->)
    /  \
  /      \
c -------> d
```

Let's write the proof out in Haskell.

```haskell
instance Profunctor (->) where
  dimap ab cd bc = cd . bc . ab
```

See
[Data.Profunctor](https://hackage.haskell.org/package/profunctors-3.1.1/docs/src/Data-Profunctor.html).
Note that the variables are written to reflect the two ends of the
function arrow; that should help as otherwise the type inferencer is
the only person who knows what is going on here. I will try to follow
that convention below too.


## A slightly-harder-to-understand profunctor

A slightly-harder-to-understand profunctor is the `Kleisli` arrow:

```haskell
newtype Kleisli m a b = Kleisli { unKleisli :: a -> m b }
```

Ignore the fancy name. The type `a -> m b` is all that matters.
`Kleisli m` is a profunctor, if `m` is a monad! It has kind `* -> * ->
*`, as required. And here are the givens:

```
a -------> b
         /
       /
   (-> m)
   /
 /
c -------> d
```

Note that I've again substituted the profunctor out since I know that `Kleisli m b c` is equal to `b -> m c`; the straight diagonal arrow means `b -> m c`.

The question is: can we find a value of type `a -> m d` and therefore complete the diagram?

```
a -------> b
  \      /
    \  /
   (-> m)
    /  \
  /      \
c -------> d
```

The two straight diagonal arrows mean `b -> m c` and `a -> m d`.

We have `ab :: a -> b` and `cd :: c -> d` and `bmc :: b -> m c` and
`a`, and we need to find a value `m d`. Again we can almost
mechancially link these values together.

```haskell
instance Monad m => Profunctor (Kleisli m) where
  dimap ab cd (Kleisli bmc) = Kleisli $ \a -> do
    let b = ab a
    c <- bmc b
    let d = cd d
    return d
```

Note that we have to unwrap and rewrap with Kleisli to pull out the `b
-> m c` value and to wrap up the final `a -> m d` value. That's a
little a confusing, I know, since we're adding yet another layer of
abstraction. Typical Haskell.

Simplifying to the `Data.Profunctor` instance, we get the final answer.

```haskell
instance Monad m =>  Profunctor (Kleisli m) where
  dimap ab cd (Kleisli bmc) = Kleisli (cmd . bmc . ab)
                              where cmd = liftM cd
```

## Examples of profunctors in lenses

TODO

## Why profunctors?

This entry into *Spoke Proof* does the shitty thing that monad
tutorials do where they explain the typeclass instead of instances, so
there is no synthetic moment where someone explains why we decided to
refactor this `Monad` interface out of all these types, probably
because the original author has not fully yet understood `Monad`
herself. (A trap that
[the original 1992 monad paper by Philip Wadler][990] _doesn't_ fall
into, by the way. Recommended reading.)

[990]: http://homepages.inf.ed.ac.uk/wadler/papers/marktoberdorf/baastad.pdf

So let me just admit it upfront: I do not fully understand
Profunctors. I have instead come up with this magical diagram that
lets me muddle through the `lenses` documentation, and it helped me to
type it out and articulate these young-man-thoughts of mine, and I
hope it helps you.

Maybe the more we grapple with the instances the more likely we will
be hit by the spark of insight. That's what happened for me and monads
anyway.

The [other instances in Data.Profunctor](https://hackage.haskell.org/package/profunctors-3.1.1/docs/Data-Profunctor.html), besides the function arrow and the Kleisli arrow, are

* `Functor w => Profunctor (Cokleisli w)`
* `Profunctor (Tagged *)`
* `Arrow p => Profunctor (WrappedArrow p)`
* `Functor f => Profunctor (DownStar f)`
* `Functor f => Profunctor (UpStar f)`

Of those, none ring a bell for me, at least not without further
investigation. I have seen UpStar and DownStar before in the `lenses`
documentation, however, so that is where I would begin the next
leg of the journey.
