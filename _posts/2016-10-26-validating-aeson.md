---
layout: post
title: "Validating Aeson with nst/JSONTestSuite"
author: hao
---

While we sit with bated breath, waiting for the latest Apple laptop
and clearing out space in our storage containers for USB-C converters,
I recommend reading Nicolas
Seriot's
[Parsing JSON is a Minefield](http://seriot.ch/parsing_json.html); the
article exhaustively mines the JSON specification for ambiguities and
presents a suite of tests to run against several well-known JSON
parsers. It punctures the myth that JSON is well-specified by any
means of the imagination. Chalk it up
to
[yet another example (Mark Pilgrim's classic blog post on RSS specifications)](https://web.archive.org/web/20110718035220/http://diveintomark.org/archives/2004/02/04/incompatible-rss) of
taking shortcuts in specifications and then having to pay it back
tenfold.

It is insane that Douglas Crockford thinks having an unversioned
specification is somehow a _good_ thing. Is this how Douglas Crockford
apologizes? Does Douglas Crockford not know the difference between an
apology and an argument that something is a good thing?

Aside: the article also yet _another_ successful usage of American
Fuzzy Lop, the software project most likely to achieve sentience and
take over the world one day.

Anyway
[I ran the test suite on Aeson 0.11.2.1](http://hao.codes/static/json-test-suite/parsing.html).
This is unfortunately a rather boring blog post since there are few
notable things to point out from the results. One obvious takeaway is
that Aeson liberally accepts floating-point numbers, even when they
might be invalid by the specification – see the chunk of results
starting with `n_number_-2..json`. That seems fine to me. I think only
about five people in the world fully understand floating-point
numbers, and it seems like a great convenience for users to not
quibble too much over the details. Aeson even goes out of its way to
represent numbers with the numeric type from the `scientific` package,
which allows for arbitrary precision. (The user, of course, can
convert back down to the type of number relevant at hand, be it `Int`
`Integer` `Float` or otherwise.)

The other, more worrying takeaway, is that Aeson rejects these two
otherwise-valid inputs:

* <code><u>FFFE</u>[<u>00</u>"<u>00E900</u>"<u>00</u>]<u>00</u> <=> [""]</code>

  Aeson fails with the message <code>Failed reading: not a valid json value</code>.

* <code>["\uFFFF"]</code>

  Aeson fails with the message <code>Failed reading: Cannot decode byte '\\x8f': Data.Text.Internal.Encoding.decodeUtf8: Invalid UTF-8 stream</code>.

These are both valid inputs (the first one being a test of UTF-16
decoding, and the second one being a pretty simple case), and these
errors seem to be bugs in the Aeson parser code. However! It looks
like
a [recent pull request](https://github.com/bos/aeson/pull/477/files),
four days old as of writing, addresses the second point. The first
point might be moot – does Aeson even guarantee UTF-16/UTF-32
decoding? Those two encodings do seem baroque in 2016, and it is
unclear if implementing support for them is worth the tradeoff for
performance. Aeson is popular, after all, due to its impressive
performance optimizations.

Anyway that's what I did today instead of actual work. Hopefully this
was interesting to you and further cements this website as place where
we can talk about increasingly esoteric bits of Haskell that are
relevant to a increasingly smaller amount of people.
