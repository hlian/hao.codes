---
layout: post
title:  "You could have invented Haskell's I/O"
author: hao
---

You are a modern functional language without side effects and you want to add a POSIX-y API for reading and writing from the standard streams. A naive first approach would be an event loop, like WinAPI or iOS or any GUI framework.

```haskell
data Event =
   YourProgramJustStarted
 | Stdin String

data Request =
   ReadStdin
 | WriteStdout String
```

Pop quiz: what should the type of `main` be?

* `Event -> Request` is a good first guess. It lets us write this program that reads from stdin:

    ```haskell
    main :: Event -> Request
    main YourProgramJustStarted = ReadStdin
    main _ = undefined
    ```

    So far so good. (And pure!) But we can’t actually do anything with the string we read … we never get access to it! No dice.

* `[Event] -> Request`. Remember that in Haskell `[Event]` doesn’t mean finite list of events, it means possibly infinite stream of events. Now we can handle as many events as we want! Here’s a program that reads a string from stdin and spits it back out:

    ```haskell
    main :: [Event] -> Request
    main [YourProgramJustStarted, Stdin s] =
        ReadStdin `then` WriteStdout s
    ```

    But, uh, there isn’t a way to implement `then`. It has type `then :: Request -> Request -> Request`, and there’s no obvious way to combine two requests into one request. The Haskell-ese way of saying this would be that `Request` doesn't seem to admit a monoid instance.

* `[Event] -> [Request]`. Since lists worked so well for us last time, let’s try it again:

    ```haskell
    main :: [Event] -> [Request]
    main [YourProgramJustStarted, Stdin s] =
       [ReadStdin, WriteStdout s]
    ```

    Here’s a more complicated one that reads two integers and adds this and prints out the result:

    ```haskell
    main :: [Event] -> [Request]
    main [YourProgramJustStarted, Stdin a, Stdin b] =
      [ ReadStdin
      , ReadStdin
      , (WriteStdout . show) (integerOf a + integerOf b)
      ]
    ```

    It may seem weird to you that an element in the return value (ReadStdin) decides the value in the parameter (Stdin s) — if so, remember that a Haskell runtime that executes main is allowed to commit the carnal sin of side effects. It can pass you just the first event, read from your first response, and only then pass the second event. Haskell’s lists are lazy, so this semantically jives. Lazy evaluation and an effectful runtime are the two epiphanies here. (Put it like this: If this were strict, this would break immediately: you’d have to have the entire list at call-time to main. PLUS you couldn’t have an infinite list, and infinite lists are beautiful.)
