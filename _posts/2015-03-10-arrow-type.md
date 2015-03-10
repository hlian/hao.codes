---
layout: post
title: "The function arrow type poopmonster"
author: hao
---

## The arrow type

In Haskell, the arrow type may be the best argument for S-expressions this side of the ’90s. A keen Haskell programmer

```
f :: a -> b -> c
```

might without hesitation read this off as

```
f :: Function a (Function b c)
```

but to most Haskell learners this mechanical translation is difficult, especially when it happens behind the scenes.

## Functor

For example,

```
where
  puzzle = repeat <$> Left <$> Just
```

seems at first to be nonsensial until you realize that `(->)` inhabits the Functor type. (Recall that `<$>` is the infix operator for `fmap`.) The instance?

```
-- 'r' does NOT mean 'return type'
instance Functor (-> r) where
  fmap :: (a -> b) -> ((-> r) a) -> ((-> r) b)
  fmap f arrow_r_a = ?
```

As with most Haskell things, the code and understanding improves with rearranging.

```
instance Functor (-> r) where
  fmap :: (a -> b) -> (r -> a) -> (r -> b)
  fmap a2b r2a = (\a -> a2b (r2a a))
```

Note that even though `r` is named as if it stands for 'return type,' it in fact is the type of the argument passed in, which remains invariant after `fmap a2b` is called upon it. It, in fact, _must_ remain invariant as this is an instance of `Functor` for `(-> r)`: `r` is fixed.

It may help to think of `r` instead as the 'returner type,' in that it is the one whose job is to return `a` and `b`. It may also hurt to think like this.

And so this instance is complete. But! it is not the shortest.

```
instance Functor (-> r) where
  fmap = (.)
```

And so, returning to our first puzzle, we realize that `repeat <$> Left <$> Just` is just `repeat . Left . Just`.

Why go to all trouble, when `.` is as good at `<$>`? It comes up very rarely.
