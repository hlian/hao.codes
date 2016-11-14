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

Anyway
[I ran the test suite on Aeson 0.11.2.1](http://hao.codes/static/json-test-suite/parsing.html).
Aeson, if you're not familiar, is the de facto JSON library for
Haskellers. It serves to highlight many of the great qualities of
modern functional programming. For one, Aeson is an example of what
you can build
with
[attoparsec, an incredibly efficient library of bytestring-parsing combinators][2]:
a safe, well-typed, extremely fast sea-worthy library. I find using
Aeson to be a joy.

[1]: http://www.serpentine.com/blog/2014/01/09/new-year-new-library-releases-new-levels-of-speed/
[2]: https://hackage.haskell.org/package/attoparsec

Aeson scores mostly positively, which does not make for a great blog
post but does make for good news for those of us who have deployed
Aeson to production. There are however a few minor unpleasant things
to point out from the test suite's results.

## Floating-point numbers, our close friend

One obvious takeaway is that Aeson liberally accepts floating-point
numbers, even when they might be invalid by the specification – see
the chunk of results starting with `n_number_-2..json`. These numbers
are accepted by Aeson without question:

* `-01`
* `-2.`
* `0.e1`
* `2.e+3`
* `2.e-3`
* `2.e3`
* `-012`
* `1.`
* `012`

These numbers are all invalid JSON, [believe it or not][b]. For
decoding, this seems fine to me. Encoding is the one I worry about: I
can see Aeson generating these strings and then another parser
crashing or failing on the resulting input. That could lead to some
particularly nasty 3 AM page to your weary ops team. Fortunately, it
does seem particularly rare that you would generate these sorts of
numbers on purpose – I imagine very few number formatters would choose
to output something as horrendous as these examples. This is more
damning of the specification than anything: why the JSON specification
insists on not versioning itself, and why the JSON specification
insists on its own version of representing floating point numbers, is
beyond me.

Perhaps the recommendation here should be this: do not try to
represent real numbers in JSON this way. Resort instead to using a
rational number (in JSON it could be a tuple of the numerator and the
denominator), at least for anything serious.

[b]: http://seriot.ch/parsing_json.html#22

## Unicode, our close friend

The other, more worrying, takeaway is that Aeson rejects these two
otherwise-valid inputs:

* <code><u>FFFE</u>[<u>00</u>"<u>00E900</u>"<u>00</u>]<u>00</u></code>

  This is `["é"]`, encoded as UTF-16. Aeson fails with the message <code>Failed reading: not a valid json value</code>.

* <code>["\uFFFF"]</code>

  Aeson fails with the message <code>Failed reading: Cannot decode byte '\\x8f': Data.Text.Internal.Encoding.decodeUtf8: Invalid UTF-8 stream</code>.

(The underlines are a clever syntax I am borrowing from the original
blog post but are a little hard to explain. Each set of two underlined
characters indicates the hexadecimal representation of a byte. While I
could have pasted the raw UTF-16 bytes into the source code of this
blog post, most of the characters would have been invisible. For
example, <u>FFFE</u> is the byte-ordering mark but it has no visible
representation. Instead what Nicholas did is write out the hex. Think
of it as a partial hexdump – normal characters are preserved, but
anything extraordinary is converted into this underlined hexadecimal
format. This is _different_ from the backslash escape, which indicates
literal text for the JSON parser to unescape – no byte trickery here.)

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

## Stray observations

* By the way, some of Nicholas's tests came out of the American Fuzzy
  Lop fuzzer, which traces the assembly instructions taken by a binary
  on a given input in order to reduce and mutate said input. An
  elegant, simple idea. We can thus point to this article as yet
  _another_ successful usage of AFL, the software project most likely
  to achieve sentience and take over the world one day.

* What a shame that Mark Pilgrim's weblog no longer exists. It was
  such a tentpole of technical writing back in the early days when
  people blogged on individual websites and we could stitch together
  new posts with RSS feeds. People took the time to put little touches
  on their websites; before MovableType came along a lot of people
  built their own commenting systems, which usually had fun little
  features and personality quirks. Everybody laid out their archives a
  little differently. You could tell which website was whose from a
  glance. Weblogging used to be harder, but it also used to be more a
  labor of love.
