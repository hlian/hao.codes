---
layout: post
title:  "You could have invented Haskell's I/O"
author: hao
---

## Dilemma

Dilemma: you are a lazy, pure, typed functional language and you want
to be able to read standard input.

In an impure language, like C, this isn't a big deal. Those languages
have a `read` that look like

```c
// Reads up to newline from standard input, and returns it as a string.
// (You'll have to free the string manually, I guess.)
char *read(void) {
  // ...
}
```

`(void)` is our way of telling the compiler that `read` takes no
arguments. Which means `read` starts with nothing!

Nothing but the C environment, that is, which includes all sorts of
useful things: global variables, system calls, `malloc(3)`, `free(3)`,
`rand(3)`, all of libc, and so on.

In you --- a pure language --- a function that takes no arguments
starts with _nothing_. And this time we mean actually nothing. A pure
language cannot, by definition, create side effects. Off limits are
global variables and system calls and all of libc.

You probably find this highly restrictive. But purity is not simply a
tax: it gives us equational reasoning, and a faster compiler, and
stronger types.

So, anyway, whatever: unless we are more clever, there is only one way
to implement `read` with this type:

```haskell
-- Reads up to newilne from standard input, and returns it as a string.
read :: Bytes
read = utf8Encode "hello, world"
```

(I am assuming some familiarity with ML/Haskell-like syntax here. I am
often uncertain of the amount of explaining that goes into a good
post. Every dispatch from the frontier seems to require two other
dispatches.)

We can vary the string, but it always has to be a constant. And so we
abandon the idea of pure I/O.…

... or we can be more clever.

## Being more clever

We said earlier that you lack an "environment," for some definition of
that word, in `read` and alos every other functin, and we ascribed
this handcuff to purity. This is not quite true.

There is exactly _one_ place where you do have an environment. In C,
it is _everywhere_: you can call `malloc(3)` from anywhere and the C
runtime knows exactly what you mean. But, for you, you only have
_one_.

And that place is your `main` function.

In C we are used to `main` functions that are very dumb.

```c
// Please return an exit code.
int main(void) {
  // ...
}
```

You might think that you have to do the same thing in your language,
and ask executable programs to implement an entry point with the same
type.

```haskell
main :: Int
main = undefined
```

But why? Without the baggage of C's `int main(void)` we might
adventure onward and explore more interesting types.

For example, what if `main` could ask the runtime to do something?

```haskell

data Request =
  | ReadStdIn

main :: Request
main = ReadStdIn
```

Cute, and pure. But you'll notice immediately a big problem: `main`
can ask questions, but it can never hear answers. You might at this
point try:

```haskell
submitRequest :: Request -> Bytes
submitRequest = undefined

main :: Int
main = submitRequest ReadStdin
```

But you'll end up with the same problem as before: there is no way to
implement `Request -> Bytes` in a pure language, besides all the
trivial useless ways.

You might then ask: can we send the bytes to `main` directly? We did
make a big fuss about `main` having some sort of "environment." And
the answer is yes!

```haskell
data Request =
  | ReadStdin
  | Exit Int

data Event =
  | ProgramJustStarted
  | ReadStdinComplete Bytes

main :: Event -> Request
main ProgramJustStarted = ReadStdin
main (ReadStdinComplete bytes) = Exit 0
```

You now have I/O in a completely pure way. And they said it couldn't
be done.

## Troubling rumors from the edge of civilization

An astute reader might criticize your library design on the point that
it seems impossible to read from stdin more than once. (After all, how
would you distinguish between different reads?)

As a computer scientist, you solve problems by either caching,
counting, or naming. In this case, counting seems best:

```haskell
data Event =
  | ProgramJustStarted
  | ReadStdinComplete Int Bytes

main :: Event -> [Request]
main ProgramJustStarted = ReadStdin
main (ReadStdinComplete 0 bytes) = ReadStdin
main (ReadStdinComplete 1 bytes) = Exit 0
```

Ah, thinks the astute reader. She has implemented allowed me to read
`bytes` and so I have two `bytes` variables but I could never use
both.

This problem is _very interesting_. The problem of sequencing and
interleaving computation is something on which you could spend an
entire novel; you could lead an entire seminar on the problem, and how
humans have tackled it. Generals have led soldiers to battle on much
simpler problems. The problem transcends both creation/art and
death/war.

But there's something simple at hand that you can reach for, which is
lists.

## Lists?

You and I, we have been using `[a]` very innocently so far, to
represent a list of values of type `a`. But we are a _lazy_ language.
And in a _lazy_ language, lists are actually much closer to _streams_.

In a _lazy_ language, all the values in a list may not be determined
at the time the list is passed into a function. So you could have this
program:

```haskell
data Event =
  | ProgramJustStarted
  | ReadStdinComplete Int Bytes

main :: [Event] -> [Request]
main [ProgramJustStarted, ReadStdinComplete a, ReadStdinComplete b] =
  [ ReadStdin
  , ReadStdin
  , Exit 0
  ]
```

And here's how you could run such a program, if you were the runtime
(and the metaphorical conceit of this post is that you are, so just go
with it):

* Pass `(ProgramJustStarted : thunk) :: [Event]` to this program's `main`.

* Take the `head` of `main`'s list of requests.

* If the request is `Exit Int`, exit with that exit code.

* Else if the request is `ReadStdin`, make a system call to read `bytes` from your local friendly POSIX-compliant operating system. Then expand thunk out by one step: `(ProgramJustStarted : ReadStdinComplete bytes) :: Event`. Then repeat.

The key here is that the list is _eventually_ all three events.[^pattern-matching]

[^pattern-matching]:

    Haskell users might point out here that this requires lazy
    pattern-matching, whereas Haskell implements strict pattern
    matching, so at this point the weblog post begins to deviate from
    Haskell. And but so _Is this really Haskell I/O?_. To which we
    say, take it down a notch.

    Haskell jumps into lazy pattern matching if you prepend a tilde to
    your patterns. We have simply elided the tildes here.

We cautiously venture that this might actually work.

## It does

It does! This is, at its core, the design of I/O library in the [Haskell 1.0 Report (see section 7 and figure 3 of this _highly interesting, "you should read the entire thing and not just section 7"-type paper)](http://research.microsoft.com/en-us/um/people/simonpj/papers/history-of-haskell/history.pdf).[^tildes]

[^tildes]:

    See, I told you tildes were the way to go.

    Honestly, if you read the PDF at this link you could skip this
    entire post. As an understatement: Simon Peyton-Jones is a good
    writer. His being one of the architects of Haskell and GHC is just
    icing.

    But: if you want to translate the code from this post into code
    from the paper, let me help you a little:

    * In Haskell and in the paper, tildes start lazy pattern matching,
      but prevent the nice square-bracket syntax we've been using.

    * The paper is doing the correct thing ending with an underscoer
      e.g. `x : y : _`, which allows more events than we were
      expecting. Our program would simply crash if more events were
      sent than we expected.

    * spj has aliased `Behaviour` to `[Response] -> [Request]`,
      which is equivalent to our `[Event] -> [Request]`. Thus
      `main :: Behaviour`.

    * `ProgramHasStarted` is actually `Success`.

Let's round out this longwinded weblog post with something useful: a
program that reads two integers from standard input and prints the sum
to standard out.

```haskell
data Handle =
  | StandardIn
  | StandardOut
  | File FilePath -- this could work! but I'll elide the details

data Event =
  | ReadComplete Handle Bytes
  | PrintComplete

data Request =
  | Read Handle
  | Print Handle Bytes

-- I mean, why not?
integerOf :: Bytes -> Int
integerOf bytes = case (reverse . utf8Decode bytes) of
  | "0" -> 0
  | "1" -> 1
  | "2" -> 2
  | "3" -> 3
  | "4" -> 4
  | "5" -> 5
  | "6" -> 6
  | "7" -> 7
  | "8" -> 8
  | "9" -> 9
  -- and so on

show :: Int -> Bytes
show = undefined -- same thing, but in reverse

main :: [Event] -> [Request]
main [ YourProgramJustStarted
     , ReadComplete StandardIn a
     , ReadComplete Stdin b] =
  [ Read StandardIn
  , Read StandardIn
  , (Print StandardOut . show) (integerOf a + integerOf b)
  ]
```

It may seem to you strange that we are able to define a list of requests whose values depend on the list of events whose values depend on said list of requests whose values depend on....

Why is that possible? And how is possible in such few lines of code?

Perhaps we should stop teaching C and Java as first languages.

In any case, this is as good a stopping point as any. Next time let's
talk about continuations and, after that, monads.
