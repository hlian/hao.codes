---
layout: post
title: "The always-updated treasure map to Haskell"
author: hao
---

Many people coming into Haskell are daunted by number of choices they have to make: which package to use, which _package manager_ to use, which language extensions to turn on, which resources to read.

So here are some sensible default choices. I've noted wherever the answer is still up in the air. Most things are! Many problems in our world have good, but not great, solutions.

## Setting up a Haskell environment on OS X

Use [stack](http://docs.haskellstack.org/en/stable/README.html#quick-start-guide). Stack

* Is a sandbox-style package manager. For each project it creates a hermetic little world filled with the project's dependencies and the project itself.

* Sets up a "global" project, which is the default project you work in when you run stack outside a project.

* By the way, a project is any directory with a `*.cabal` or a `package.yaml` file or any subdirectory thereof. I highly recommend using `package.yaml` files, otherwise known as the [hpack][hpack] format. With `*.cabal` files you have to type the name of each module separately _and_ you have to maintain per-target dependencies. What a hassle.

[hpack]: https://github.com/sol/hpack/blob/master/package.yaml

* Also installs GHC (`stack setup`) for you.

* Also maintains your `PATH`. If you run `stack exec foo` or `stack ghci`, you're running `foo` and `ghci` in the context of your project's sandbox.

Awooga: OS X users will be tempted to use Homebrew to install Stack but that will compile it from source, which takes a good hour on a desktop and possibly longer on laptops. (I have never been patient enough to find out.) Best to [just unzip an official release](https://github.com/commercialhaskell/stack/releases).

## The community

Is the best part of Haskell. The community is incredibly kind and supportive. [/r/haskell](https://www.reddit.com/r/haskell) is a medium-traffic subreddit filled with library announcements, fascinating discussions, questions answered by experts, and much else besides. Try [Stack Overflow](http://stackoverflow.com/questions/tagged/haskell) too.

## Learning Haskell

* [Learn You a Haskell for Great Good!](http://learnyouahaskell.com)

* [Try Haskell! An interactive tutorial in your browser](http://tryhaskell.org)

* [What I Wish I Knew When Learning Haskell](http://dev.stephendiehl.com/hask/) by Stephen Diehl

* [Write You a Haskell](http://dev.stephendiehl.com/fun/) by Stephen Diehl

* [The original paper by Philip Wadler that proposed the Monad typeclass](http://homepages.inf.ed.ac.uk/wadler/papers/marktoberdorf/baastad.pdf) – surprisingly readable

* [Cryptopals](http://cryptopals.com/sets/1/) – not the worst way to learn Haskell, and you'll learn modern applied information security to boot (You will probably need [Crypto.Cipher.AES128](https://hackage.haskell.org/package/cipher-aes128/docs/Crypto-Cipher-AES128.html) or [Crypto.Cipher.AES.Haskell](https://hackage.haskell.org/package/cryptocipher/docs/Crypto-Cipher-AES-Haskell.html) to complete the first chapter.)

* [Chris Allen's "How to learn Haskell"](https://github.com/bitemyapp/learnhaskell), another collection of links. Has perhaps the best advice written about Haskell: _Don't sweat the stuff you don't understand immediately. Keep moving!_

## Creating a new package

```sh
$ cd ~/workspace
$ stack new hello
```

See also:

```sh
$ stack templates
```

## The pain of compilation

Compiling Haskell is _slow_. Add this to your global aliases (assuming you use zsh):

```sh
alias .fast='--fast --ghc-options="-j +RTS -A1024m -n2m -RTS"'
```

It will teach GHC to use (1) all your cores and (2) more memory while compiling.

Another useful global alias (assuming you use zsh):

```sh
alias .fw='--file-watch'
```

Usage:

* `stack build .fast .fw`
* `stack ghci .fast`
* `stack install lens .fast`

Another suggestion: rebind `;` to `:` in your terminal preferences. When Haskelling I never type semicolon but I sure do type colon all the time.

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

## IDEs: hdevtools or Intero

>  This is an active field of development!

* [hdevtools](https://github.com/hdevtools/hdevtools/) runs a GHCi process in the background and lets your editor interactively query it for typechecking and code-reloading purposes. Comes with integrations for Emacs, Vim, Atom, and Sublime. This is the one that I use.

* [Intero](https://github.com/commercialhaskell/intero) is an Emacs-specific IDE and a rising star. I have not used this much but people speak highly of it.

## HTTP client

Use [wreq](https://hackage.haskell.org/package/wreq).

## HTTP server

Use [warp](https://hackage.haskell.org/package/warp). It implements WAI. If you're coming from Python, WAI is Haskell's WSGI. Or Ruby's Rack. Or Perl's PSGI.

[WAI even supports HTTP/2 now](https://github.com/yesodweb/wai/pull/399/files).

## HTTP framework

>  This is an active field of development!

This is more divisive. I like to think of each web framework by what new technologies and abstractions they use. These three have all picked very interesting choices, making the Haskell web framework field very diverse:

* Snap: [Snap uses lenses](http://snapframework.com/docs/tutorials/snaplets-design) in a neat way that lets you attach additional information to the request at each middleware layer. I think I'm drastically oversimplying snaplets.

* Yesod: [Yesod has great documentation](http://www.yesodweb.com/book). It also uses conduits, which is a neat little library for modeling streams (with – and this is the hard part – reasonable memory management and error handling) in Haskell. It uses Template Haskell to remove some of the boilerplate of web programming.

* Servant: [Servant is newer but has a cool higher-kinded routes system](http://haskell-servant.github.io) where you can declare the type of your entire API with type-level programming.

This isn't like Python or Ruby's web framework ecosystem, where everybody has sort of decided to coalesce around a monolithic, invent-the-wheels framework (Django, Rails) with lots of smaller, more modular options (Camping, Sinatra, Flask). Lens, conduits, and type-level programming are all cutting-edge stuff.

## Web Sockets

Use [jaspervdj/websockets](https://hackage.haskell.org/package/websockets) for insecure port-80 Web Sockets; use Taylor Fausak's [wuss](https://hackage.haskell.org/package/wuss) to get TLS.

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

Lazy IO causes more heartache with resource management and error handling than you would expect. Try [pipes](https://hackage.haskell.org/package/pipes/docs/Pipes-Tutorial.html) or [conduit](https://www.fpcomplete.com/user/snoyberg/library-documentation/conduit-overview) instead, which lets you build out streaming data pipelines without leaking file handles or badly handling IO errors. Unfortunately they're both a little hard to use.

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

If [Hoogle](https://www.haskell.org/hoogle/) can't find it, try [Hayoo](http://hayoo.fh-wedel.de).

## Short functions

A good thing to watch out for is functions in Haskell that last for longer than five lines. These might take the form of long `do` blocks, or a mess of `let ... in ... `s and `where`s. These often signal that the function is doing too much. Whereas in other languages we might resign ourselves to the mess, in Haskell we can do better.

I find writing a clean function `f` involves asking myself:

* Is `f` is the composition of some series of functions? `f = foo . bar . baz` is one kind of function composition. But so is `f = foo >>= bar >>= baz` (and its categorical cousin `f = foo >=> bar >=> baz`).

* Is `f` a map over some structure? If I'm taking a list and producing a list, I usually reach for `map` and `filter`.

* If `f` folding a big structure into a smaller structure, which aggregates or summarizes the information in the big structure? If I'm taking a list and producing a single value, I usually reach for `foldr` and `filter`.

* Do I make an intermediate data structure first? For example, if I'm given a list of points and am asked to compute the midpoint between each two neighbors, I'd usually first call:

^
    ```haskell
    twoWindows :: [a] -> [(a, a)]
    twoWindows [] = []
    twoWindows [x] = []
    twoWindows x:y:xs = (x, y):twoWindows xs
    ```

    I could just inline this logic into my definition of `f`, but I'd rather pull the abstraction out and give it a name.

I think these are just the standard 1970s top-down programming techniques applied to Haskell.

## Horizon

Upcoming GHC developments we should be excited about:

* [Strict Haskell](https://ghc.haskell.org/trac/ghc/wiki/StrictPragma)

* [MonadFail proposal](https://prime.haskell.org/wiki/Libraries/Proposals/MonadFail)

* [Dependent Haskell](https://ghc.haskell.org/trac/ghc/wiki/DependentHaskell)

  * [Merging types and kinds](https://typesandkinds.wordpress.com/2015/08/19/planned-change-to-ghc-merging-types-and-kinds/)

  * [Type families](https://typesandkinds.wordpress.com/2015/09/09/what-are-type-families/)

## Great Haskell blogs

* [Well-Typed](http://www.well-typed.com/blog/)

* [Haskell for all](http://www.haskellforall.com) by Gabriel Gonzalez

* [Bartosz Milewski's Programming Cafe](http://bartoszmilewski.com)

* [Neighborhood of Infinity](http://blog.sigfpe.com) by Dan Piponi

* [Inside 736-131](http://blog.ezyang.com) by Edward Z. Yang

* [Simon Peyton Jones](http://research.microsoft.com/en-us/people/simonpj/) – don't be put off by the academic paper format, as spj is a highly capable technical writer

* [Edward Kmett's talks on YouTube](https://www.google.com/search?q=edward+kmett&oq=edward+kmett&tbm=vid)

## Parametricity a.k.a. theorems for free

Using types and typeclasses to generate and prove theorems about a function's invariants. This is like if all your life you carried around this intuition about how something works and then one day someone came along and validated all of it with mathematics and good writing.

* [@parametricity](https://twitter.com/parametricity)

* [Parametricity: Money for Nothing](http://bartoszmilewski.com/2014/09/22/parametricity-money-for-nothing-and-theorems-for-free/) by Bartosz Milewski

* [Parametricity Tutorial (Part 1)](http://www.well-typed.com/blog/2015/05/parametricity/) by Edsko de Vries

* [Theorems for free!](http://ttic.uchicago.edu/~dreyer/course/papers/wadler.pdf) by Philip Wadler

## Opting into strictness

Confused about `seq` and weak-head normal form? Read [Roman Cheplyaka's blog post on forcing lists](https://ro-che.info/articles/2015-05-28-force-list).

## Fiber

The older you get, the more you'll appreciate a moderate amount of fiber in your daily diet.

## Monospace font

Try Ubuntu Mono!

## Updates to this document

* 2015 Nov 30: the initial draft was published after a rousing
  discussion in my friends and I's #haskell Slack channel.

* 2016 Jan 3: added Web Sockets mention after a fun day with Slack's
  real-time messaging API.

* 2016 Aug 18: hdevtools and intero mentioned. Typos fixed.
