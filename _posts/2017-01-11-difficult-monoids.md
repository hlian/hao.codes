---
layout: post

title: "Monoids of difficult things poopmonster"
author: hao
---

To the oft-asked question "What are monads?" we answer: monads are a
monoid in the category of endofunctors. Glib though the answer may be,
this answer says something about the elegance and success of monoids –
that monoids are everywhere and that, when we notice one, we should
take the time to marvel and appreciate them.

So, if we are to take this answer seriously, we should slowly unpack
it. In the span of a dozen or so words we are making several
assumptions and errors.

[iry]: http://james-iry.blogspot.com/2009/05/brief-incomplete-and-mostly-wrong.html

We should mention something up top: You can learn a great deal of
Haskell without ever having to understand category theory, this
sentence, or anything in I'm about to say.

There is a great deal of looseness when we bring category theory to
Haskell. We tend to hand-wave problems like unchecked exceptions,
infinite loops, laziness, and equality. We would rather use category
theory here as a metaphor to help us understand Haskell programs,
knowing that these results would never pass scrutiny and only describe
an imaginary subset of Haskell where everything cleanly fits together
and nothing useful is ever accomplished.

## [Hask, Hask]

**Hask** is a category formed from Haskell types. In typical category
theory form, we name it with a boldface abbreviation. Each object
**Hask** is Haskell type of kind `*`; each morphism between two types
`A, B` is a function `f :: A -> B`. Note that functions are both
objects and morphisms. Confusing, but not illegal.

We can build another category out of this one: the functor category
**[Hask, Hask]**. Each object is a type with kind `* -> *`; two
examples are given below. Additionally each object should obey
_functor laws_: these say that there should be a way to lift morphisms
from `Hask` into `[Hask, Hask]` (not unlike `fmap :: (a -> b) -> (f a
-> f b)`) and that this mechanism should obey some rules about
identity. Since we are Haskell programmers we can think of this by
analogy to the `Functor` type class: each `f :: * -> *` should have a
lawful `Functor` instance.

Examples of objects in this functor category, all of which [we have seen before][me]:

[me]: /functors.html

* `Identity :: * -> *` in `data Identity a = Identity a`

* `Const :: * -> *` in `data Const r a = Const r`

* `List :: * -> *` in `data List a = Nil | Cons a (List a)`

Each morphisms between two objects in **[Hask, Hask]** is a natural
transformation; we will not worry too much about what they are.[^nat]

## A wild monoid in [Hask, Hask] appears

We can equip this endofunctor category with a bifunctor `data Compose
f g a = Compose (f (g a))`.

A bifunctor is like `Functor` with kind `* -> * -> *` instead. Like
`Functor`, it can lift morphisms from `Hask` (`bimap :: (a -> a') ->
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

