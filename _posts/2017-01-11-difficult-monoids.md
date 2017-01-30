---
layout: post

title: "Less obvious monoids poopmonster"
author: hao
---

"Monads are a monoid in the category of endofunctors," a joke first attributed to [James Iry](iry), though the idea almost certainly predates him. Glib though it may be, this answer says something about the success of monoids – a simple mathematical structure with closure, identity, and associativity that appears seemingly everywhere. When we notice a monoid, we should take the time to marvel and appreciate them.

A note: when we bring category theory to Haskell we do so loosely. We hand-wave problems like bottom, laziness, and equality. We use category theory as a way build better programs, leaving the rigor to mathematicians who are free from the tyranny of pull requests and project deadlines. It is a kindness that imperfect languages exist like Haskell that let us encode abstractions at this high a level.

## Hask

Let **Hask** be a category formed from Haskell types of kind `*`. In true category-theoretical form, we name it in boldface and phlegmatically drop a handful of letters. A category has objects and morphisms.

* Each object **Hask** is type in the kind `\*`. This is the normal kind where most of our datatypes and functions live. Unless you have imported `GHC.TypeLits` or turned on `DataKinds` you are probably working inside `*`. Here are some example objects: `3 :: Int`, `double :: Int -> Int`, `double 3 :: Int`.

* Each morphism between two objects `A, B` is a function (a value, not a type) of type `f :: A -> B`. Each possible function is a morphism in the category.

As [pigworker points out][pw], this is not the only category we can form from Haskell programming. It is unlucky that we have blessed it with the name **Hask**.

Something that never gets pointed out but I think is true: the kind restriction of `*` rules out many normal Haskell types, such as `Maybe :: * -> *`.
It means functions like `safeHead :: forall a. [a] -> Maybe a` cannot be found as a morphism in this category. However something like `safeHead @Int :: [Int] -> Maybe Int` (a wild `-XTypeApplication` appears) would be a morphism, from object `[Int] :: *` to object `Maybe Int :: *`.
It is possible that this is an incorrect explanation of **Hask**.
I had a great deal of difficulty tracking down a source for how to construct **Hask**, but let us work with what we have for now.

[pw]: http://stackoverflow.com/a/37368282/3963

## [Hask, Hask]

Now we complicate.

We can build another category out of this one: the functor category
**[Hask, Hask]**. This will strongly correspond to our notion of `Functor`::

    class Functor f where
      fmap :: (a -> b) -> (f a -> f b)

Note that `f` here must have kind `* -> *`.

Let us construct **[Hask, Hask]** as a category:

* Each object in **[Hask, Hask]** is a type with kind `* -> *`.

* Each morphism between objects `f, g :: * -> *` is a function (avaluenotatype) with type `newtype f :~> g = forall a. f a -> g a`. Each possible function with this type appears as a morphism. We sometimes call this a "natural transformation," to sound cool. Natural transformations have [more structure][ms] than I am letting on but we will skip over them with dancerly aplomb.

[ms]: https://ncatlab.org/nlab/show/natural+transformation

To make this category a functor category we must also constrain each object in **[Hask, Hask]** to be a _functor_. In Haskell-land a functor `F` here is a type `F :: * -> *` (like `Maybe` or `[]`) that obeys functor laws:

* We should be able to lift objects from **Hask** into `F(Hask)` e.g. lifting `Int` to `Maybe Int` or `[Int]`.

* We should be able to lift morphisms from **Hask** into `F(Hask)` e.g. lifting `double :: Int -> Int` into `fmap double :: Maybe Int -> Maybe Int` or `fmap double :: [Int] -> [Int]`.

* The identity morphism in **Hask** must be the identity morphism in **[Hask, Hask]** i.e. `fmap id = id`

* Morphisms that compose in **Hask** should continue to compose in **[Hask, Hask]** i.e. `fmap (p . q) = fmap p . fmap q`.

Examples of objects in this functor category, all of which [we have seen before][me]:

[me]: /functors.html

* `Identity :: * -> *` in `data Identity a = Identity a`

* `Const :: * -> *` in `data Const r a = Const r`

* `List :: * -> *` in `data List a = Nil | Cons a (List a)`

## A wild monoid in [Hask, Hask] appears

We can equip this endofunctor category with a bifunctor `data Compose
f g a = Compose (f (g a))`.

A bifunctor is like `Functor` with kind `* -> * -> *` instead. Like
`Functor`, it can lift morphisms from **Hask** (`bimap :: (a -> a') ->
(b -> b') -> f a b -> f a' b'`) and has laws about identity. I refer
you to the [`Bifunctor` typeclass][bitc] for more details.

In practical programming bifunctors are rarer than functors but you
are undoubtedly familiar with another example: `(,) :: * -> * -> *`.
  
`Compose` is special: this bifunctor satisfies
several [coherence conditions](ncat), none of which I particularly
understand. If either `f` or `g` is `Identity`, it does nothing (we
say that `Identity` is the left and right identity of this bifunctor.)

We now have enough to define the monoidal category `([Hask, Hask],
Compose, Identity)`. There are many monoidal categories that can form
out of **[Hask, Hask]** and this is merely one of them. I think this
often gets lost when we say that "monads are a monoid on the category
of Hask endofunctors"; it would be more precise but less pithy to say
that monads are a monoidal category formed by composition.

[^nat]: Natural transformations, though irrelevant here, do show up during practical programming. E.g. they come in handy during practical matters e.g. [allowing the end-user to use her own monad transformer stack in library design][srv].
[srv]: https://hackage.haskell.org/package/servant-0.9.1.1/docs/Servant-Utils-Enter.html#t::-126--62-
[bitc]: https://hackage.haskell.org/package/bifunctors-3.2.0.1/docs/Data-Bifunctor.html
[ncat]: https://ncatlab.org/nlab/show/monoidal+category


## Anyway

 In the same way that monads are a monoid category
formed from the category of endofunctors (see [this post by Kmett][0])

[0]: https://www.reddit.com/r/haskell/comments/5ez9b1/monoid_in_the_category_of_endofunctors/dagtvsb/

The following question comes from [Petr Pudlák](http://stackoverflow.com/questions/38169453/whats-the-relationship-between-profunctors-and-arrows/38172390#38172390):

> What profunctors lack compared to arrows is the ability to compose
> them. If we add composition, will we get an arrow? In other words,
> if a (strong) profunctor is also a category, is it already an arrow?
> If not, what's missing?

I wrote up an answer on Stack Overflow and thought I would reprint it
here. You have to try and make content and sometimes new content is
just old content repackaged.

