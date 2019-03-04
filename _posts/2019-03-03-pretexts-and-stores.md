---
layout: post
title:  "Deriving Lenses through Stores, Pretexts, and Yoneda"
author: hao
---

Here's an unusual way into lenses, as if you needed another one. Take this:

```haskell
type Lens' big small =
  big -> (small, small -> big)
```

(It's a grown-up, refactored version of this: `type Lens'' big small = (big -> small, big -> small -> big)`. Convince yourself that's true before proceeding.)

In essence it says that, were you to give me a Big Thing, I could

- Give you a small piece of it _the getter_;

- Or give you a function that updates the small piece inside the big piece _the setter_.

Let's see it in action:

```haskell
_1 :: Lens' (a, b) a
_1 (a, b) = (a, update -> (update, b))
```

Now I can

- Evaluate `let (getter, setter) = _1 ("hello", "world")`

- `getter` contains the value, fulfilling our getter needs

- `setter "goodbye"` evaluates to `("goodbye", "world")`, fulfilling our setter needs

Marvelous! Circumlocutious, but marvelous nonetheless. We set about implementing a lens library around this construction.

## Stores

But wait! Let us apply one [cuil](https://www.reddit.com/r/worldnews/comments/7da5i/police_raids_reveal_baby_farms/c06cqxb/).

We note that the right-hand side of the arrow above, `(small, small -> big)`, is a _functor_ on `big`. Let's make this explicit:

```haskell
-- Kmett calls this type "Store"; we follow along.
newtype Store small big = Store (small, small -> big)

instance Functor Store where
  fmap f (Store (getter, setter)) = Store (getter, f . setter)
```

Because it's a functor, it obeys the **YONEDA LEMMA**. I shouted it out loud because it's so important.

The Yoneda lemma comes from the world of category theory. It looks complicated, but in essence it says that "you are exactly all the things that can be done to you."
In other words, if it quacks like a duck, and it moves like a duck, and in our ideological universe a duck is simply a product of how it quacks and how it moves, then it _must_ be a duck.
Fun fact: Nobuo Yoneda (1930-1966) worked on the ALGOL family of languages. When Saunders Mac Lane, author of _the_ category theory textbook, interviewed him, it came up!

The lemma is too complicated to reprint here, but it expresses itself in Haskell very simply. That is partially because the category of Haskell types is very simple.

## First-order Yoneda lemma in Haskell

For first-order Haskell types, this means:

- If you have a value `F a` is a functor , then

- `forall f. Functor F => forall b. (a -> b) -> F b` is _equivalent_ to `F a`

Let's see an example!

- Say I have a list `[1, 2, 3]`. Its type is `[Int]`, so `F` is `List` and `a` is `Int`. 

- Then the Yoneda lemma says that `\f -> [f 1, f 2, f 3]` is _equivalent_ to `[1, 2, 3]`, where `f` has type `Int -> b` for _some_ b

  - To see that this is true, pass in `id` for `f` _this proves one direction of the equality_

  - And then see that `\f -> fmap f [1, 2, 3]` is how we can walk the other direction

## Second-order Yoneda lemma in Haskell

There's also a Yoneda lemma for second-order Haskell types!

- If you have a functor `F`, e.g. `data F x = blah blah blah`

- Then the type `F x`, for some `x` is _equivalent to_

- `forall G. Functor G => forall t. (F t -> G t) -> G x`

- Where `forall G, t. Functor G => (F t -> G t)` is a _natural transformation_ – meaning it maps the identity and the composition operator of the category `F(Hask)` into the identity and composition operator of the category `G(Hask)`, where  `Hask` is the category of Haskell types

Some examples!

- Let `F` be the `Const` functor, a.k.a. `newtype Const constant x = Const constant`

- The left-hand side of the lemma simplifies to `forall G. Functor G => forall t. (Const constant t -> G t) -> G x`

- Though we wrote `forall G.` the function `Const constant t -> G t` actually puts powerful constraints on what `G` can be

- Note, for example, that `Const constant t` doesn't "depend" on `t` at all

- In order for `F t -> G t` to be a natural transformation, then, `G` must _also_ be a `Const c` functor for _some_ `c`

- We can rewrite the above to `forall c, t. (Const constant c -> Const c t) -> Const c x`

- This simplifies to `forall c, t. (constant -> c) -> c`

## See also

- ["Yoneda Intuition from Humble Beginnings"](https://gist.github.com/Icelandjack/02069708bc75f4284ac625cd0e2ec81f) by Icelandjack
