In the Haskell ecosystem, servant has quickly risen through the ranks and established itself as an excellent framework for writing web apps. Moreover, it has been able to export a successful new _point of view_ regarding the structure and interpretation of computing. And that point of view is this: if we can push ourselves to represent our programs at the _type level_ we will end up with shorter, more robust, and more capable programs.

I confess that I am enamored about this. As someone who has been programming for far too long, safer and richer programs with less typing is the software engineering holy grail. Any steps we can take toward that we should take. At night my friends and I lay in bed with the thought of errors buzzing in our head. Mistakes that could have been prevented by the judicious application of types.

So, thesis: in this blog post we will attempt to sketch how one might represent a web service, something fairly complicated and practical, at the type level and – in the process – de-mystify type-level gymnastics and present it as something analogous to value-level programming (which normal people would just call _programming_).

## Abstraction and application

A simple and common kind of type-level primitive is the function. Though we often do not call it that, it is indeed possible to build type-level functions, and we tend to do it without second thought when we build algebraic data types. For example, lists:

```
data [a] = [] | a:[a]
```

A list takes a type from the "usual" "universe" of types (`Int`, `Int -> Float`, `IO (Int -> Float)`, ...) and returns another type (`[Int]`, `[Int -> Float]`, `[IO (Int -> Float)]`, ...). To abbreviate this idea, we say it has _kind_ `* -> *`.

```
> :kind Int
*
> :kind Int -> Float
Int -> Float :: *
> :kind IO (Int -> Float)
IO (Int -> Float) :: *
> :kind []
[] :: * -> *
> :kind [Int]
[Int] :: *
```

As the Lispy cons-list type, `[]` is a higher-order, indexed by the type of the element we want in the list. When we specify that type we reduce its kind to just `*`, as we saw with `:kind [Int]`.

We can even construct these functions more explicitly with type families:

```
> :{
   | type family MyList a where
   |   MyList Int = [Int];
   |   MyList Float = [Float]
   | :}
> :kind MyList
MyList :: * -> *
> :kind MyList Int
MyList Int :: *
> :kind! MyList Int
MyList Int :: *
= [Int]
> :kind MyList Char
MyList Char ::*
> :kind! MyList Char
MyList Char ::*
= MyList Char
```

Here we ask the compiler to not only kind-check our type expressions (`:kind`) but to also _normalize_ the representation (`:kind!`). Note that `MyList Char` kind-checks even though there is no such type `t` such that `t ~ MyList Char`. In other words, we were able to a partial function at the type-level just as we are able to define partial functions (like `head`) at the value level.

The worst thing that could happen with a partial function at the type level, however, is a compile-time error, which truly qualifies as a Nice Thing.

## Literals and primitives

As of recent GHC versions we also have natural numbers and strings. They live in the `GHC.TypeLits` module and require a `DataKinds` extension:

```
> :set -XDataKinds
> :kind "hello"
"hello" :: GHC.TypeLits.Symbol
> :kind 3
3 :: GHC.TypeLits.Nat
```

Note that we have strayed outside the "usual" "universe," the kind `*`. Unlike the types we know and love in `*`, nothing inhabits these types. There is no value `x` such that `x :: Symbol` or `x :: Nat`. If you were to look up the definitions you would see:

```
data Nat
data Symbol
```

No constructors to speak of. They run, skip, and holler when we typecheck our program

Prior to programming in Coq and Haskell, I thought of types as inert little creatures that were typechecked and then erased by the compiler. They were nice to have around and I adored them, but they did little outside of, as we saw above, being smushed together for function abstraction and application.

Let us now dispel that idea once and for all:

```
> :set -XTypeOperators
> import GHC.TypeLits
> :browse
type family (*) (a :: Nat) (b :: Nat) :: Nat
type family (+) (a :: Nat) (b :: Nat) :: Nat
type family (-) (a :: Nat) (b :: Nat) :: Nat
type family (^) (a :: Nat) (b :: Nat) :: Nat
[snip]
> :kind! 3 + 3
6 :: Nat
> :kind! 3 ^ 3
27 :: Nat
```



Here we see that we add, multiply, subtract, and exponentiate type-level naturals.[^ints] We can even ask the constraint solver to solve logarithms:

```
> import Data.Proxy
> :{
   | let f :: Proxy (3 ^ x) -> Proxy x;
         f Proxy = Proxy
  :}

> :type f (Proxy : Proxy 27)
f (Proxy :: Proxy 27) :: Proxy 3
> f (Proxy :: Proxy 27)
Proxy
> :type f (Proxy :: Proxy 28)
f (Proxy :: Proxy 28) :: ((3 ^ x) ~ 28) => Proxy x
> f (Proxy :: Proxy 28)
    Couldn't match expected type ‘28’ with actual type ‘3 ^ x0’
    The type variable ‘x0’ is ambiguous
    [snip]
> :type f (Proxy :: Proxy 3733918487410200435329597541848665882254¶
                          0977678373400775063693172207904061726525¶
                          1229993688938803977220468765065431475158¶
                          1087270545921608585813513369828091873141¶
                          9174859426258093880701995195640428557181¶
                          8041046681288797402925517668012340617298¶
                          3965747316191523867230462351259348960585¶
                          9058828465479354050593620237654780744273¶
                          0582144527058988756251452817793413352141¶
                          9207446230275187291854328623757370639854¶
                          8531947641692626381997288700690701389925¶
                          6524297198527698749274196276811060702333¶
                          710356481)
f (Proxy :: Proxy [snip]) :: Proxy 1024
```

Here we let a function `f` be a trivial `Proxy` expression that makes the type type-check, and it only exists to placate the compiler. We could have defined `f` as `let f = undefined`. If Haskell were to allow type-only functions, we would have used that instead.

[^ints]: Though possible, GHC lacks a built-in representation of integers and other numbers. The Peano represenation of naturals sits in the comfortable intersection of simple and useful, and for now the need for a full type-level number stack is small.

So, to recap:

* We have been creating type-level functions all this time without knowing it.
* There are other kinds besides `*`, like `Nat` and `Symbol`.
* The types that inhabit `Nat` are type-level natural numbers.
* The types that inhabit `Symbol` are type-level strings.
* The constraint solver can find proofs of constraints constructed with type-level numbers. Typechecking is just proof search, baby.
