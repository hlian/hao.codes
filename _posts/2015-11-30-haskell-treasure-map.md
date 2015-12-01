---
layout: post
title: "The always-updated treasure map to Haskell"
author: hao
---

## Setting up a Haskell environment on OS X

Use [stack](http://docs.haskellstack.org/en/stable/README.html#quick-start-guide). Earlier this year I would've said `brew install ghc cabal`, but things move fast in Haskell land. Now stack will even install GHC for you.

## Creating a new package

```sh
$ cd ~/workspace
$ stack new hello
```

## Editor environment

You can't go wrong with my [Haskell Emacs scratchpad](https://github.com/hlian/emacs-scratchpad-haskell). Emacs and Vim are both pretty good choices. Really you need these things:

* Syntax highlighting

* Live parsing and typechecking

* hlint's suggestions

* Autocompletion of horribly long module names

* Being able to send code to an interactive GHC REPL

* Restarting when your `.cabal` file changes

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

Emacs and Vim have all these features once you install ghc-mod.

## ghc-mod

Is a research project. It's its own executable `ghc-mod(1)` that you can build and install with `stack install ghc-mod`. But it's also the name of the Emacs/Vim packages that talks to the executable, which is very confusing.

## HTTP client

Use [wreq](https://hackage.haskell.org/package/wreq).

## HTTP server

Use [warp](https://hackage.haskell.org/package/warp). It implements WAI. If you're coming from Python, WAI is Haskell's WSGI. Or Haskell's Rack. Or Perl's PSGI.

## HTTP framework

This is more divisive. I like to think of each web framework by what new technologies and abstractions they use. These three have all picked very interesting choices, making the Haskell web framework field very diverse:

* Snap: [Snap uses lenses](http://snapframework.com/docs/tutorials/snaplets-design) in a neat way that lets you attach additional information to the request at each middleware layer. I think I'm drastically oversimplying snaplets.

* Yesod: [Yesod has great documentation](http://www.yesodweb.com/book). It also uses conduits, which is a neat little library for modeling streams (with – and this is the hard part – reasonable memory management and error handling) in Haskell. It uses Template Haskell to remove some of the boilerplate of web programming.

* Servant: [Servant is newer but has a cool higher-kinded routes system](http://haskell-servant.github.io) where you can declare the type of your entire API with type-level programming.

This isn't like Python or Ruby's web framework ecosystem, where everybody has sort of decided to coalesce around a monolithic, invent-the-wheels framework (Django, Rails) with lots of smaller, more modular options (Camping, Sinatra, Flask). Lens, conduits, and type-level programming are all cutting-edge stuff.

## JSON

Use [Aeson](https://hackage.haskell.org/package/aeson/docs/Data-Aeson.html).

## Lenses

It takes forever to understand lenses. [This series of blog posts](http://artyom.me/lens-over-tea-1) actually takes the time to explain and derive lenses, but lenses tutorials have the same problem as monad tutorials. The reason lenses and monads exist is that lots of people used Haskell for a long time and all noticed the same problem, but a lot of (abstract) thought went into thinking of a solution. The end result is something that is very hard to explain but, with time and experience, will definitely click with you and then you'll wonder why more languages aren't powerful enough to express lenses.
