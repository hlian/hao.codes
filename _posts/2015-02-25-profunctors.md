---
layout: post
title: "What are profunctors? poopmonster"
author: hao
---

## Where profunctors come from

Q: if a newcomer to lenses asks you, **how do lenses work?**, what do
you say?

You can take her through the derivation of van Laarhoven's lenses, and
she will walk away with puzzled but bright eyes. The material is
dense, but ultimately resolves into a handful of typeclassing tricks.
But how about more complicated lenses? How about _prisms_?

Take `"5" ^? _Number` for example, which one might write
while [jazzing around JSON][3]. `_Number`, exported by
[lens-aeson][1], is a prism.

The first stop is the Hackage entry for lens-aeson, which informs me
that `_Number :: Prism' Text Scientific`.

(Can we take a moment to appreciate Hackage? A community-driven
documentation bonanza containing every Haskell package, with links to
source code and _cross-references between typeclasses and instances_.)

Why the prime mark `'`? Well,

```haskell
type Prism' part whole = Prism part part whole whole
```

OK, so what is `Prism`? According to Hackage,

```haskell
type Prism s t a b = forall p f. (Choice p, Applicative f) =>
    p a (f b) -> p s (f t)
```

So this became abstract very quickly. For a long time in using lenses,
profunctors were this big wall

The constraint `Applicative f` tells me that every prism is a
traversal, as per the [big scary chart from the lens package][2], so
at least that part I grok. But what is `Choice p`?

And here we have our first run-in with profunctors. For you see,
[Choice is defined as a subclass of `Profunctor`][choice], which leads
us to a deceptively simple question:

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

The blog post sets up the neat little SAT analogy of
relations:functions :: profunctors:functors. I have read it many
times, but as I do not know much about category theory's functors I
must walk away, wishing that I had the intuition / heart-of-the-cards
for the material.

But enough is enough! Let's tackle profunctors without _any_ knowledge
of category theory and see how far we can get. Let's begin from the
Haskell definition:

```haskell
class Profunctor p where
  dimap :: (a -> b) -> (c -> d) -> p b c -> p a d
  -- where dimap (f . g) (h . i) ≡ dimap g h . dimap f i
```

This says that a type `p` is a profunctor iff

* For some function `ab :: a -> b`, and
* For some function `cd :: c -> d`,
* There exists a function `pbcpad :: p b c -> p a d`, and
* We call such a function a _dimap_.

## What are dimaps?

`dimap` sounds like it's been named carefully, as to rhyme with a
Functor's `map`, but Functors are magic and we will drive past this
rest stop, so as to avoid any hand-wavy explanations.

So what are dimaps? It's far too heavy a type to carry around in your
head, yet we lack the mathematical machinery to simplify and analyze
and synthesize a working intuition for it.

So I propose this: a visual.

    a         ⇗ c        a ⇘         c
    |       ⇗   |        |   ⇘       |
    |     ⇗     |        |     ⇘     |
    v   ⇗       v        v       ⇘   v
    b ⇗         d        b         ⇘ d

        p b c       ->       p a d

In _addition_, there is a law here: `dimap (f . g) (h . i) ≡ dimap g h
. dimap f i`.

Thesis: it is this very law where

(The law is important, so let's restate it here: `dimap` distributes
over function composition, where `f . g` splits into `g` and `f`
whereas `h . i` splits into `h` and `i` (the other order). Presumably
the functor laws combined with the first definition yield the
law.[^messy])

The reconciliation is opaque to me.

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

It remains to show that `dimap (f . g) (h . i) ≡ dimap g h . dimap f i` for this instance of `dimap`. It does!

First choose `a, b, c, d, e, f` so that `f :: b -> c` and `g :: a -> b` and `h :: e -> f` and `i :: d -> e`.

Now fix `p :: (->) c d`. We want to show that `dimap (f . g) (h . i) $ p` produces the same value as `dimap g h . dimap f i $ p`.

What is `dimap (f . g) (h . i) $ p`? Well, it must be the arrow crossing `p :: c -> d` here:

```
   (g)      (f)
a -----> b -----> c
  \             /
    \         / (p)
      \     /
        \ /
        / \
      /     \
    /         \
  /             \
d -----> e -----> f
   (i)      (h)
```

In other words, some value `q :: a -> f`.


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

Again it remains to show that `dimap (f . g) (h . i) ≡ dimap g h . dimap f i` for this instance of `dimap`. (It does!)

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
