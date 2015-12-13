---
layout: post
title: "Mastering JSON with the plate and cosmos lenses"
author: hao
---

_Day 12 of Advent of Code._

I have been attacking the Advent of Code puzzles in Haskell. Sometimes you can arrive at a solution incredibly quickly by using a modern, pure, functional programming language. Day 12 is a great example of this.

The problem in Day 12 is this: you are given a JSON blob as a string and asked to sum up all the numbers inside it. You can do this in one line with shell and regexps, but the second part of the problem (filter out all objects with the string `"red"` as a value) forces you to parse the string.

So it's midnight on Friday. You're sleepy and wildly inebriated. What's a Haskeller to do? There exists what I call the "brute force" solution, even though it is still fairly elegant thanks to the niceties of the Haskell ecosystem. In this solution we parse the string into an Aeson (as per our [treasure map](/haskell-treasure-map.html)) `Value` and then fold over the data structure.[^scientific]

[^scientific]: `Scientific` might be new to you (it was certainly new to me). The scientific package efficiently numbers to an arbitrary precision. Aeson decodes to `Scientific`, and there are helpers to convert these varmints into the rest of the number stack.


```haskell
data Value = Object (HashMap Text Value)
           | Array (Vector Value)
           | String Text
           | Number Scientific
           | Bool Bool
           | Null
             deriving (Eq, Read, Show, Typeable, Data)
```

This is a recursive datatype, so writing a fold comes pretty natural:

```haskell
import Data.Foldable (toList)

count (Object hashmap) = sum (map count (toList hashmap))
count (Array vector)   = sum (map count (toList vector))
count (Number sci)     = sci
count _                = 0
```

You gotta love the `Foldable` typeclass. We were able to destruct a hashmap and a vector without ever importing their modules or reading their Hackage pages.

This covers part one. Part two, to continue the brute-force approach, would involve putting a guard on the `count (Object hashmap) | noReds hashmap` declaration, and the guard would filter over the hashmap looking for any values of `"red"`. We would arrive at a working answer but perhaps not an interesting one.

## Rose-colored lens

But: Faithful readers of _Spoke Proof_ will remember our post
["Lens and JSON are best friends in Haskell."](/lenses-heart-json.html) What does a lensy solution look like? Let's try this. We know that we have a big data structure and we want to summarize it by taking a sum. This suggests we need to use a fold.

So let's fold over our `json :: Value` with `foldMapOf someFold`; furthermore, let's fold inside the `Sum` monoid, whose monoidal operator is addition.

```haskell
lensy json = getSum (foldMapOf someFold Sum) json
```

What should our fold be? It does not immediately seem obvious that such a lens exists. We would need a lens that targets _every number_ in the JSON object. Fortunately, there is something very close: [`Control.Lens.Plated`](https://hackage.haskell.org/package/lens-4.13/docs/Control-Lens-Plated.html).

## plate

The idea behind the `plate :: (Plated a) => Traversal' a a` traversal is simple: given a data structure of type `a`, the `plate` lens traverses all the data inside that is also of type `a`. `Plated` is the Swiss-army knife of recursive data structures. It lets you treat any recursive data type `a` as a container of `a`'s.

A quick example:

```haskell
λ> x
Array (fromList
  [ Number 1.0
  , Object (fromList [("b", Number 2.0), ("c", String "red")])
  , Object (fromList [("b", Number 2.0), ("c", String "blue")])
  , Number 3.0])

λ> x ^.. plate
[ Number 1.0
, Object (fromList [("b", Number 2.0), ("c", String "red")])
, Object (fromList [("b", Number 2.0), ("c", String "blue")])
, Number 3.0]

λ> x ^.. (plate . plate)
[Number 2.0, String "red" , Number 2.0, String "blue"]

λ> x ^.. (plate . plate . plate)
[]
```

Hopefully that helps in developing an intuition about `plate`.

## cosmos

There is another library function here, called `cosmos`:

```haskell
λ> x ^.. cosmos
[Array (fromList
  [ Number 1.0
  , Object (fromList [("b", Number 2.0), ("c", String "red")])
  , Object (fromList [("b", Number 2.0), ("c", String "blue")])
  , Number 3.0])
, Number 1.0
, Object (fromList [("b", Number 2.0), ("c", String "red")])
, Number 2.0
, String "red"
, Object (fromList [("b", Number 2.0), ("c", String "blue")])
, Number 2.0
, String "blue"
, Number 3.0]
```

Can you guess what `cosmos` does, just based off of this input? The documentation says this:

```haskell
-- Fold over all transitive descendants of a Plated container,
-- including itself.
cosmos :: Plated a => Fold a a
```

"Transitive descendants" means all the children of the container, then all the children's children, then all the children's children's children, ad infinitum until there are no more children left to be folded. With `cosmos`, we now have enough to solve part one of the problem! The `_Number` prism will compose with `cosmos` to produce

```haskell
λ> :t cosmos . _Number
   (Applicative f, Plated a, Contravariant f, AsNumber a) =>
   (Scientific -> f Scientific) -> a -> f a
```

Which is a fold![^fold]

[^fold]: A fold in lens-world is defined as an applicative and contravariant functor constraints on the s-t-a-b shape. They are one and the same. See the [type alias in Control.Lens.Fold](https://hackage.haskell.org/package/lens-4.13/docs/Control-Lens-Fold.html) for more details.

```haskell
λ> x ^.. (cosmos . _Number)
[1.0, 2.0, 2.0, 3.0]

λ> getSum $ foldMapOf (cosmos . _Number) Sum x
8.0
```

Pretty neat, right?

## cosmosOf

For part two, we will need the power user's edition of `cosmos`, which is `cosmosOf someFold`. Whereas `cosmos` assumes you want all the children of a container, `cosmosOf someFold` asks uses `someFold` to decide which next children to target. In fact, `cosmos` is defined as `cosmos = cosmosOf plate`. It's all coming together, babies!

```haskell
nonred (Object o) | "red" `elem` o = False
nonred _ = True
```

This means we can pass in a custom fold that filters out all the riff-raff objects with red:

```haskell
λ> x ^.. cosmosOf (plate . filtered nonred)
[Array (fromList
  [ Number 1.0
  , Object (fromList [("b", Number 2.0), ("c", String "blue")])
  , Number 3.0])
, Number 1.0
, Object (fromList [("b", Number 2.0), ("c", String "blue")])
, Number 2.0
, String "blue"
, Number 3.0]

λ> x ^.. cosmosOf (plate . filtered nonred) . _Number
[1.0, 2.0, 3.0]

λ> getSum $ foldMapOf (cosmosOf (plate . filtered nonred) . _Number) Sum x
6.0
```

Notice that we no longer fold over the object with "red", which means `_Number` is no longer able to target numbers inside objects with red values, which means `foldMapOf` no longer sums it up!

## Altogether now

```haskell
module Main where

import BasePrelude
import Control.Lens
import Data.Aeson
import Data.Aeson.Lens

nonred (Object o) | "red" `elem` o = False
nonred _ = True

input      = (^?! _Value) <$> readFile "<snip>"
tally fold = getSum . foldMapOf (cosmosOf fold . _Number) Sum <$> input
main       = (,) <$> tally plate <*> tally (plate . filtered nonred)
```

I think lens is great because it lets you write a program that encodes what you mean _and little more_. Today we wrote some code to define what it means to have a red-poisoned object, and we wrote some code to fold our values into a sum, and we wrote some code to read and parse a file. But that's about it! The handy-dandy, all-in-one, lemon-fresh lens package took care of the rest.
