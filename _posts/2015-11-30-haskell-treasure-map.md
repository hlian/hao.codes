---
layout: post
title: "The always-updated treasure map to Haskell"
author: hao
---

I think many people coming into Haskell are daunted by how many choices they have to make. Here are good default choices to make. I've noted wherever the answer is still up in the air. Most things are! Many problems in the Haskell world have good, but not great, solutions. A common tension is between power and usability. You could be the person who writes the next great abstraction. I believe in you.

## Setting up a Haskell environment on OS X

>  This is an active field of development!

Use [stack](http://docs.haskellstack.org/en/stable/README.html#quick-start-guide). Earlier this year I would've said `brew install ghc cabal`, but things move fast in Haskell land. Now stack will even install GHC for you.

## Reddit

Everybody hangs out at [/r/haskell](https://www.reddit.com/r/haskell). You'll see anything from questions from new users to discussion about the latest ICFP papers. The community is incredibly kind and supportive. If you want something less noisy than IRC or a mailing list, try subscribing to the subreddit.

## Creating a new package

```sh
$ cd ~/workspace
$ stack new hello
```

## Ensuring a fast development environment

Adding this to your `~/.stack/global/stack.yaml` is a good way of speeding up compilation for development:

```yaml
ghc-options:
    # Turn off optimizations for packages
    "*": -0O
```

The downside is that you need to turn it off for production builds. But if you're like me, you do production builds on a different machine.

## Editor environment

You can't go wrong with my [Haskell Emacs scratchpad](https://github.com/hlian/emacs-scratchpad-haskell). Emacs and Vim are both pretty good choices. Really you need these things:

* Syntax highlighting

* Live parsing and typechecking

* hlint's suggestions

* Autocompletion of horribly long module names

* Being able to send code to an interactive GHC REPL

* Restarting the REPL when your `.cabal` file changes

* Being able to go from

  ```haskell
  f x = x
  ```
  
  to
  
  ```haskell
  f :: a -> a
  f x = x
  ```
  
  with one keypress.

With the right packages, Emacs and Vim have all these features.

## ghc-mod

>  This is an active field of development!

Is a research project. It's its own executable `ghc-mod(1)` that you can build and install with `stack install ghc-mod`. But it's also the name of the Emacs/Vim packages that talks to the executable, which is very confusing.

## HTTP client

Use [wreq](https://hackage.haskell.org/package/wreq).

## HTTP server

Use [warp](https://hackage.haskell.org/package/warp). It implements WAI. If you're coming from Python, WAI is Haskell's WSGI. Or Ruby's Rack. Or Perl's PSGI.

## HTTP framework

>  This is an active field of development!

This is more divisive. I like to think of each web framework by what new technologies and abstractions they use. These three have all picked very interesting choices, making the Haskell web framework field very diverse:

* Snap: [Snap uses lenses](http://snapframework.com/docs/tutorials/snaplets-design) in a neat way that lets you attach additional information to the request at each middleware layer. I think I'm drastically oversimplying snaplets.

* Yesod: [Yesod has great documentation](http://www.yesodweb.com/book). It also uses conduits, which is a neat little library for modeling streams (with – and this is the hard part – reasonable memory management and error handling) in Haskell. It uses Template Haskell to remove some of the boilerplate of web programming.

* Servant: [Servant is newer but has a cool higher-kinded routes system](http://haskell-servant.github.io) where you can declare the type of your entire API with type-level programming.

This isn't like Python or Ruby's web framework ecosystem, where everybody has sort of decided to coalesce around a monolithic, invent-the-wheels framework (Django, Rails) with lots of smaller, more modular options (Camping, Sinatra, Flask). Lens, conduits, and type-level programming are all cutting-edge stuff.

## JSON

Use [Aeson](https://hackage.haskell.org/package/aeson/docs/Data-Aeson.html).

## Unicode text

Use [Data.Text](http://hackage.haskell.org/package/text/docs/Data-Text.html). It's built on bytestrings and is fast and supports the bare minimum Unicode slicing and dicing. For more Unicode support, see [text-icu](http://hackage.haskell.org/package/text-icu).

## Binary data

Use [Data.ByteString](https://hackage.haskell.org/package/bytestring). If you need to represent text, upgrade yourself immediately to text.

## Lazy text or bytestrings?

I would say avoid them unless you really know what you're doing. I say this as somebody who doesn't know what he's doing.

## Lazy IO?

>  This is an active field of development!

Lazy IO causes more heartache with resource management and error handling than you would expect. If you want your file handles to close at sensible times, use [pipes](https://hackage.haskell.org/package/pipes/docs/Pipes-Tutorial.html) or [conduit](https://www.fpcomplete.com/user/snoyberg/library-documentation/conduit-overview). Unfortunately they're both a little hard to use.

## Lenses

>  This is an active field of development!

You're going to keep hearing about lenses because the lens package has achieved remarkable success in the past couple of years, both in terms of creativity and popularity. [This series of blog posts](http://artyom.me/lens-over-tea-1) takes the time to explain and derive lenses. Lenses tutorials have the same problem as monad tutorials. The reason lenses and monads exist is long-time Haskellers all noticed the same problem, and a lot of (abstract) thought went into thinking of a solution. The original sin of lenses is functionally updating a complicated data structure. The solution is ... complicated.

Some lens insights:

* Prisms, getters, setters, traversals, and uppercase-L `Lens` in the lens package all compose with `.` It all typechecks and type-inferences. This seems like it was easy to get right but it _wasn't_ and that's the secret genius of the lens package. _Against all odds, they got all this stuff working with `.`._

* If you compose a bunch of lens together, you get back the lowest common denominator on [this UML diagram](https://hackage.haskell.org/package/lens). So composing a setter with anything automatically makes it the result a setter. And you can't compose a setter with a getter – you need a `Lens`. And a `Lens` composed with a traversal is always a traversal. And only compositions of isomorphisms will yield an isomoprhism. _Against all odds, they got all this UML diagram to work exactly as you think it would._

* 99% of lens usage boils down to `bigDataStructure operator (lens1 . lens2 . lens3)`, where operator is one of `^.`, `^?`, or `^..`.

* Stop packing and unpacking your strings into bytestrings and vice versa. Use [Data.Text.Lens](https://hackage.haskell.org/package/lens/docs/Data-Text-Lens.html) and [Data.ByteString.Lens](https://hackage.haskell.org/package/lens/docs/Data-ByteString-Lens.html).

* Stop calling `toStrict/fromStrict` and `toChunks/fromChunks` to convert between strict and lazy bytestrings (and texts). Use [Control.Lens.Iso](https://hackage.haskell.org/package/lens/docs/Control-Lens-Iso.html#t:Strict) instead.

## Prelude

The default prelude is super annoying because you keep importing tiny minimodules like `Data.Monoid` and `Data.Maybe` to get their helpers. [The base-prelude package](https://hackage.haskell.org/package/base-prelude/docs/src/BasePrelude.html) does all this for you, but you have to turn off implicit preludes (`-XNoImplicitPrelude`).

## Pointfree

[blunt](http://blunt.herokuapp.com) is a little web app that gives you the pointfree version of any function. Be prepared to encounter headache-inducing oddities like `(.) . (.)` or the `Applicative` instance for `(->) r`.

## Searching by types

If [Hoogle](https://www.haskell.org/hoogle/) can't find it, try [Hayoo](https://www.haskell.org/hoogle/?q=hPutStrLn).

## Short functions

A good thing to watch out for is functions in Haskell that last for longer than five lines. These might take the form of long `do` blocks, or a mess of `let ... in ... `s and `where`s. These often signal that the function is doing too much. Whereas in other languages we might resign ourselves to the mess, in Haskell we can do better.

I find writing a clean function `f` involves asking myself:

* Is `f` is the composition of some series of functions? `f = foo . bar . baz` is one kind of function composition. But so is `f = foo >>= bar >>= baz` (and its categorical cousin `f = foo >=> bar >=> baz`).

* Is `f` a map over some structure? If I'm taking a list and producing a list, I usually reach for `map` and `filter`.

* If `f` folding a big structure into a smaller structure, which aggregates or summarizes the information in the big structure? If I'm taking a list and producing a single value, I usually reach for `foldr` and `filter`.

* Do I make an intermediate data structure first? For example, if I'm given a list of points and am asked to compute the midpoint between each two neighbors, I'd usually first call:

    ```haskell
    twoWindows :: [a] -> [(a, a)]
    twoWindows [] = []
    twoWindows [x] = []
    twoWindows x:y:xs = (x, y):twoWindows xs
    ```
  
    I could just inline this logic into my definition of `f`, but I'd rather pull the abstraction out and give it a name.
  
I think these are just the standard 1970s top-down programming techniques applied to Haskell.

## Fiber

The older you get, the more you'll appreciate a moderate amount of fiber in your daily diet.

## Monospace font

Try Ubuntu Mono!