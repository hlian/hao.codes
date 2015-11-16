---
layout: post
title: "Programming language papers explained: reflection"
author: hao
---

_The first installment in a ninety-billion long series._

Like many [Oleg](http://okmij.org/ftp/Haskell/) papers, the idea presented in "Functional Pearl: Implicit Configurations" is elegant but aloof.

![](https://s-media-cache-ak0.pinimg.com/736x/42/2a/99/422a990be84a4638ae76bca1ceade430.jpg)

Let's back up and start with clock arithmetic. The kind of math you do with clocks is slightly harder than normal math because you can't go above 12 for hours and you can't go above 60 for minutes. For example, 10 hours from 3 o'clock is 1 o'clock, not 13 o'clock. If you keep thinking along these lines, you get modular arithmetic, which takes the addition and multiplication of regular arithmetic and adds a similar restriction: a _modulus_. In the hour and minutes examples, the moduli were 12 and 60. When you choose interesting moduli, you can [change the world](https://en.wikipedia.org/wiki/RSA_(cryptosystem)).

But anyway. If you have a number like 13 and you want to know what the equivalent would be "mod 12" you divide by 12 and take the remainder. Haskell has this function. It's `mod`. We now have all the tools at our disposal to write a modular arithmetic library in Haskell. Let's start by implementing addition and multiplication; the way you introduce a new number type to the number stack in Haskell is by implementing an instance of `Num`.

```haskell
-- The type for our moduli, to distinguish them from the numbers being modded.
newtype Modulus = Modulus Int

-- The numbers being modded.
data Modded = Modded Modulus Int

instance Num Modded where
    Modded modulus@(Modulus m) a + Modded (Modulus m) b = Modded modulus (mod m (a + b))
    Modded modulus@(Modulus m) a * Modded (Modulus n) b = Modded modulus (mod m (a * b))
```

(There are more functions to implement, but we'll ignore them for brevity.)

So this is a fine solution that would be acceptable in other languages and yet also something we would never settle for because we have a modern typed functional programming language at our disposal. This solution suffers from a grave problem: it lets the following program typecheck.

```haskell
main = print ((Modded (Modulus 3) 10) * (Modded (Modulus 4) 10))
```
The problem, as you may have guessed, is we're using different moduli to do the same calculation. At runtime this program will crash. We can try and "favor one side" of the computation, but that would be along the lines of adding Celsius and Fahrenheit together. No. We want this program to _not typecheck_ and we won't settle for less. We want this bug to never make it past a compiler error. We want our spaceship to make it to Jupiter.

A second, equally pressing problem, is that this solution is way too verbose. For example, there's a typo in the definition for multiplication.

## Typeclasses?

Let's work backwards. We want our definition to look like this:

```haskell
newtype Modded = Modded Int

instance Num Modded where
    Modded a + Modded b = modded (a + b)
    Modded a * Modded b = modded (a * b)

modded :: Int -> Modded
modded int = Modded (mod int modulus)
    where modulus = ???
```
But this is asking too much. There is no room in this representation to store a modulus! Previously we fixed the problem by sneaking an additional parameter into the `Modded` constructor (`data Modded = Modded Modulus Int`). It was our way of telling the compiler that we were going to represent the modulus with a value obtained during runtime. What if we instead told the compiler we were going to represent the modulus with a _type_, which can be obtained during compiletime?

```haskell
-- s represents our modulus ... somehow
newtype Modded s = Modded Int

modded :: Int -> Modded s
modded int = Modded (mod int modulus)
    where modulus = ???
```
