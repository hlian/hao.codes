## Type-level API specification might be some kind of reprieve for the tired and overworked web programmer of 2016

Nowhere is the excess of late 2000s-to-2010s programming more evident than the moment when you are asked to scroll through and pick a web framework framework out of a list. Varying in language, size, and culture, there is no logical process you could come up with that would help you pick the one best web framework for any project. Instead the programming community has resorted to a kind of identity politicking: using framework X says something about you and thank goodness because someone who wouldn't use framework X would be extremely Y and Z.

I want to cast all this aside and tell you, the weary web programmer, no matter what choice you make you will have made the wrong one. That these frameworks are built on a singular idea that leads them down the wrong road, making you work harder and longer than you have to when you could be with your loved ones. That most of these frameworks (but not all!) have cut corners – accepting received wisdom when it is in fact of received foolhardiness – on one of the most important, most fundamental parts of figuring out how to write a web service: _routing_.

## Routing

Defining routing is tricky. Routing is many things, but the first one that comes to mind probably the idea of playing traffic cop to the HTTP request path. When a request comes in, we have to determine which function to call. Most frameworks let you declare the hierarchy of routes at runtime, whether through an embedded domain-specific language or something similar. Here as our canonical example is the first couple of lines for a Rails app trying to route a reddit-like online community website:

```ruby
Barnacles::Application.routes.draw do
  constraints do
    scope :format => "html" do
      root :to => "home#newest",
        :protocol => "https://",
        :as => "root"

      get "/rss" => "home#index", :format => "rss"
      get "/hottest" => "home#index", :format => "json"
      get "/hottest/page/:page" => "home#index", :format => "json"
```

But wait that's not all. The dual side of routing happens on the client side, where you the tired programmer must transcribe all the API URLs the moment you go write the API client, making sure each one is spelled correctly and all the types and preconditions are lined up. Keep in mind you have to do this for each client you end up writing: one for JavaScript on the browser, one for the Ruby gem you want to write, and so forth. This is the kind of Sisyphaen work that produces a high ringing note in your ear and introduces distance between you and your significant other.

```js
function getRSS() {
  fetch("/rss").then(function(s) {
    return XML.parse(s);
  });
}

function getHottestPage(pageNo) {
  assertInt(pageNo);
  fetch("/hottest/page/" + pageNo).then(function(s) {
    return JSON.parse(s);
  });
}
```

At some point you will _also_ have to copy down the routes in your application into your API documentation, the act of converting beautiful code into messy paragraphs that never seem to mean what you want them to mean. Most people, understandably, skip this part altogether. I would argue this is a _third_ kind of routing: the hierarchy of your web service has been rendered into server-side code, and it has been rendered into client-side code, and now it is being rendered into English.

We have imprisoned ourselves in this hall of mirrors and like every prison it is of one of our own construction. It seems to me that we are operating at the wrong level of abstraction. In Rails (and similar frameworks) we choose to specify our routes through runtime code. That code, and the in-memory data structures it builds, contains all sorts of information that we need access to and that we then duplicate on the client side and in the documentation. But it is inherently locked up on the server.

We could instead have the server run the routes in special modes, where for example Rails spits out a JS client in the "JS client mode" or English documentation in the "documentation mode." Write the code to write the code, if you will. Extend the interpreter for the routing DSL to support these modes. Implement a plugin system. Work really hard to make a small amount of people happy. But this then shifts the burden to the people working on the framework by dramatically expanding the scope of what the routing library should look like.

It would be nice if we had some sort of intermediate language, a halfway point between the time we write down the routes in a module and the time that code is executed to trun the server.

So let me tell you about a third way. A story of types and functions. A story of _type-level_ programming. And let me use a smidgen of Haskell to illustrate it. An esoteric language, to be sure, but one that is concise enough and beautiful enough to warrant it. (I will try to explain line by line what is happening. I want this to be relevant to all curious readers.)

## Types and their constructors

Types are Legos. Out of the box the library for a typed language comes with types like `Int` and `Float` and `Char`. The functional programmer thinks for a while and then accretes these types to form bigger types. Like `type String = [Char]` (a list of characters is a string) or `type Point = (Float, Float)` (a 2D point is an X and a Y) or `type Predicate a = a -> Bool` (a filtering predicate takes something and returns a thumbs up thumbs down).

These operators, `[]` and `(,)` and `->`, are type _constructors_. Not types themselves but operators we use with types to create more types. We accrete these types into larger and more complicated beasts right up until we end up with a working application. 

Modern strongly-typed functional programming languages like Haskell or Scala go one step further. We can not only use the built-in constructors but also create new ones. This is what allows us to embed a domain-specific language at the _type level_. And this, along with a little elbow grease, should be enough to allow us to specify API routes.

So assume for one moment that we are building a weather API. For that will need at least two new type operators: one to encode the slash (the route `weather/nyc`) and one to encode disambiguation (`weather/nyc` or `weather/paris`):

```haskell
{-# language DataKinds     #-}
{-# language PolyKinds     #-}
{-# language TypeOperators #-}

data head :> tail
data head :| tail
infixr 8 :|
infixr 9 :/

data Weather =
  Weather { highTemp :: Float
          , lowTemp :: Float
          , sunny :: Bool
          }

data GET a

type API =
  "weather" :> GET [Weather]
            :> ("nyc" :> GET Weather
                "paris" :> GET Weather
                "atlantis" :> GET Weather)
```

In our API specification, we have four endpoints:

* `GET /weather` will return weather from all cities as a list of weather objects. We will soon see how to translate this into a serialization format (like the oh-so-popular JSON).

* `GET /weather/<city>` will return the weather specific to city as a single weather object, as long as the city is either NYC or Paris or _the lost city_.

These first three lines

```haskell
{-# language DataKinds     #-}
{-# language PolyKinds     #-}
{-# language TypeOperators #-}
```

enable compiler-specific extensions to the Haskell language (the compiler being [GHC](ghc)). `DataKinds` lets us use strings as a type, which has all sorts of fascinating implications that you should go out and read about. `PolyKinds` pushes the compiler to infer the correct _kind_ for `type API`, "kind" being the in-word for "the type of a type." `TypeOperators` is a syntactic extension that lets us conjure up new infix operators `:>` and `:|`.

```haskell
data head :> tail
data head :| tail
infixr 8 :|
infixr 9 :/
```

Here `data` is a terribly-named keyword that declares `:>` and `:|` to be two new type constructors, each taking two arguments. And, for lack of a better vocabulary, I called them a head and a tail. They are assigned the right operator precedences so we can avoid writing parentheses unnecessarily.

```haskell
data Weather =
  Weather { highTemp :: Float
          , lowTemp :: Float
          , sunny :: Bool
          }
```

This defines our `Weather` type to be a three-tuple of a high temp, a low temp, and a sunniness flag. This naturally translates to a JSON object with three fields, but that will come later.

```haskell
data GET a

type API =
  "weather" :> GET [Weather]
            :> ("nyc" :> GET Weather
                :| "paris" :> GET Weather
                :| "atlantis" :> GET Weather)
```

Finally our type. This uses our type constructor and our weather type and the list constructor to form a quasi-tree structure. At this present moment this type is completely inert. It neither lets us implement a server nor does it generate the JS code we want. The problem is that we have given ourselves a diction and a syntax but no semantics. To attach meaning to `:>` or `:|` we will have to turn to _typeclasses_.

## Typeclasses

To write an HTTP server 

Here we are going to ratchet up the Haskell factor a little. A typeclass is a relatively new innovation in the programming-language world that lets us write safe, generic code that works over many types.

```haskell
{-# language OverloadedStrings #-}
{-# language TypeFamilies      #-}

import qualified Network.HTTP.Types as HTTP
import qualified Network.Wai as WAI

class ToApplication api where
  type Server api
  server :: Proxy api -> Server api -> WAI.Application
```




```haskell
{-# language OverloadedStrings #-}
{-# language TypeFamilies #-}

import Data.Proxy

import qualified Data.Aeson as Aeson
import qualified Network.HTTP.Types as HTTP
import qualified Network.Wai as WAI
import qualified Network.Wai.Handler.Warp as WAI

class ToApplication api where
  type Server api
  server :: Proxy api -> Server api -> WAI.Application

instance Aeson.ToJSON resource => ToApplication (GET resource) where
  type Server (GET resource) =
    IO resource
  server Proxy resourceM =
    application
    where
      application _ respond =
        respond
          . WAI.responseLBS HTTP.status200 headers
          . Aeson.encode =<< resourceM
      headers =
        [("Content-type", "application/json")]
```

If we were to stop right now, we could still encode an HTTP service with one endpoint:

```haskell
type LonelyAPI = GET UTCTime

main :: IO ()
main =
  WAI.run 2016 (serve (Proxy :: Proxy LonelyAPI) getCurrentTime)
```

This works!

```haskell
$ curl -i "http://localhost:2016/"
HTTP/1.1 200 OK
Transfer-Encoding: chunked
Date: Mon, 08 Aug 2016 18:53:43 GMT
Server: Warp/3.2.6
Content-type: application/json

"2016-08-08T18:53:43.813072Z"%
```

The fact that it works is not too surprising. We have the Hello, world! tutorial app for WAI and smuggled it inside our convoluted typeclass. If you view our `API` type as a tree with branches and leaves, then calling `server :: ToApplicationapi => Proxy api -> Server api -> Application` is akin to asking the compiler to recursively visit the nodes of the tree and our `ToApplication (GET resource)` instance is the recursive base case. It is at the base case that we determine the monad to use: here it is `IO resource`, and we could conceive of more pragmatic real-world monads such as `ExceptT SqlError IO resource` or `Reader SqlPool IO resource`.

Our two non-base recursive cases are handling `:/` and `:|`.

```haskell
{-# language ScopedTypeVariables #-}

import Control.Exception
import Control.Lens

data RoutingStop =
  RoutingStop
  deriving (Show)

instance Exception RoutingStop

instance (KnownSymbol parent, ToApplication children) => ToApplication (parent :/ children) where
  type Server (parent :/ children) =
    Server children
  toApplication Proxy next =
    application
    where
      application request respond =
        case WAI.pathInfo request of
          (h:t) | h ^. unpacked == symbolVal (Proxy :: Proxy parent) -> do
            let subrequest = request { WAI.pathInfo = t }
            toApplication (Proxy :: Proxy children) next subrequest respond
          _ ->
            -- Route directory does not match with `parent`
            throw RoutingStop

instance (ToApplication head, ToApplication tail) => ToApplication (head :| tail) where
  type Server (head :| tail) =
    Server head :| Server tail
  toApplication Proxy (goLeft :| goRight) =
    application
    where
      headApplication =
        serve (Proxy :: Proxy head) goLeft
      tailApplication =
        serve (Proxy :: Proxy tail) goRight
      application request respond =
        catch (headApplication request respond) $ \(_ :: RoutingStop) ->
          tailApplication request respond
```


[to be written]

## pieces of writing that probably won't make it

https://www.andres-loeh.de/Servant/servant-wgp.pdf

> Static type systems are the world’s most successful application of formal methods. Types are simple enough to make sense to programmers; they are tractable enough to be machine-checked on every compilation; they carry no run-time overhead; and they pluck a harvest of low-hanging fruit. It makes sense, therefore, to seek to build on this success by making the type system more expressive without giving up the good properties we have mentioned.

> Every static type system embodies a compromise: it rejects some “good” programs and accepts some “bad” ones. As the dependently-typed programming community knows well, the ability to express computation at the type level can improve the “fit”; for example, we might be able to ensure that an alleged red-black tree really has the red-black property. Recent innovations in Haskell have been moving in exactly this direction.

> But, embarrassingly, type-level programming in Haskell is almost entirely untyped, because the kind system has too few kinds (⋆, ⋆ → ⋆, and so on). Not only does this prevent the programmer from properly expressing her intent, but stupid errors in type-level programs simply cause type-level evaluation to get stuck rather than properly generating an error. In addition to being too permissive (by having too few kinds), the kind system is also too restrictive, because it lacks polymorphism. The lack of kind polymorphism is a well-known wart; see, for example, Haskell’s family of Typeable classes, with a separate (virtually identical) class for each kind.

So begins the paper "[Giving Haskell a Promotion][0]."

[0]: http://research.microsoft.com/en-us/people/dimitris/fc-kind-poly.pdf

Types are wonderful creatures, often misunderstood. As the types for a language are strengthened, the compiler is able to reject more programs with mistakes (e.g. preventing `null` dereferences) and yet simultaneously accept more valid programs (e.g. Java 5, which introduced auto-boxing/unboxing; e.g. #2 the different composition operators for Scala `monocle` optics vs. the single `.` for Haskell `lens` optics). For writing programs in production and at scale, we at Originate have found modern typed functional programming languages – which possess many of the smartest typecheckers – to be successful many times over.

In recent times Haskell has sprouted a new kind of typechecking: typechecking at the type level. Kindchecking, if you will (the type of a type is called the "kind" of a type). In Haskell types without any parameterization assigned the star kind `*`. Three examples:

```haskell
  % stack ghci
λ> data Impossible
λ> :kind Impossible
Impossible :: *
λ> data Neutral = Aeroplane | Avery
λ> :kind Neutral
Neutral :: *
```

Perhaps the worst-kept secret of Haskell is that it is actually two languages stapled together. The first language lets us smash values together to produce new values while the typechecker does the grunt work of preventing crashes and other undesirable behavior.

[An example: `2 :: Int`, `(+) :: Int -> Int -> Int`, and `3 :: Int` together make `5 :: Int`. Another example: `putStrLn :: String -> RealWorld -> (RealWorld, ())` and `"hello, world" :: String` together make a side effect of type `RealWorld -> (RealWorld, ())`. To be cute, we abbreviate that type as `IO ()`.]

This language that we have is convenient for building up and ripping apart data structures at runtime, but suppose we want to do the same at compiletime. How might we represent numbers and strings at compiletime? How might we build a binary tree, or represent business logic, or even model an HTTP service? For that we turn to Haskell's type-level programming facilities.

At the type level, rather than values with types we have _types_ with _kinds_. Just as every value as a type, every type has a kind.

```haskell
  % stack ghci
λ> data Impossible
λ> :kind Impossible
Impossible :: *
λ> data Neutral = Aeroplane | Avery
λ> :kind Neutral
Neutral :: *
λ> :kind Neutral -> Impossible
Neutral -> Impossible :: *
```

By default, types introduced by `data`/`newtype` without parameters have kind `*`.

```haskell
  % stack ghci
λ> newtype Phantom a = Phantom Int
λ> :kind Phantom
Phantom :: * -> *
λ> newtype State st a = State (st -> (st, a))
λ> :kind State
State :: * -> * -> *
```

Types with one parameter have kind `* -> *`. Types with two parameters have kind `* -> * -> *`. Note that 






In Haskell, just as we declare values to have types, we can declare types to have _kinds_.

```
data Count a b c = Zero | One a | Two a b

> :type Zero
Zero :: Count a b c

> :type One
One :: a -> Count a b c

> :type Two
Two :: a -> b -> Count a b c
```

Here we see three data constructors with three different arities. When we query their types in the REPL we see that the types of these data constructors are indexed by the variables we declared in `data Count`.

As types is to values what kinds are to types, we might ask at this point how to do the same thing at the kind level.



We might type a traditional HTTP service as

```
service :: IO ()
```

This however is unsatisfying.

We might try to extract the pure part of this service as

```
service :: Request -> Response
```

But still we fail to encode routing and method and serialization.

How might we represent an HTTP service more fully?

We might turn to type-level programming.

One thing we can do in recent versions of GHC is express trees at the type level.

```
data a :> b
```

This declares a new type `(:>)` with kind `(:>) :: * -> * -> *`.

~a brief interlude about types and kinds~

Note that it is impossible construct a value with type `a :> b`. It _only_ exists at the type level. It _only_ exists at compile time.




Remember that we were able to pattern match on the service's routes.

```haskell
data Route a =
    Get a
  | String :> Route a
  | Route a :| Route a

newtype Depth = Depth Int

display :: Show a => Route a -> IO ()
display (Get a) =
  putStrLn ("leaf " <> show a)
display (parent :> child) = do
  putStrLn ("parent " <> parent)
  f child
display (left :| right) = do
  putStrLn "left"
  f left
  putStrLn "right"
  f right
```

We have not lost this ability. At the type-level, we have typeclasses.

```
import Models (Gizmo, Jinky, Widget)

data Get a

class Display a where
  display :: Proxy a -> IO ()

instance Display (Get a) where
  display Proxy =
    putStrLn ("leaf " <> show ???)

instance Display (parent :> child) where
  display Proxy = do
    display (Proxy :: Proxy parent)
    display (Proxy :: Proxy child)

instance Display (parent :| child) where

type Service =
     ("gizmos" :> Get [Gizmo])
  :| ("jinkies" :> Get [Jinky])
  :| ("widgets" :> Get [Widget])

main =
  display (Proxy :: Proxy Service)
```

Let us break this down:

* `display` in `main` is inferred to have type `display :: Proxy Service -> IO ()`
* this expands out to be `display :: Proxy (("gizmos" :> Get [Gizmo]) :| ...) -> IO ()`
* `display :: Proxy a -> IO ()` from `class Display` unifies with this type
* we get a hit for `instance Display (parent :| child)` where `a ~ parent :| child`, `parent ~ "gizmos" :> Get [Gizmo]` and `child ~ (jinkies :> Get [Jinky]) :| ...`

In the `Display` class we use `Proxy` (from `Data.Proxy`) as a way to index our function by the type passed into `display`'s first argument.

~ideally we would just call display as `display @Service` with -XTypeApplications~



I think what characterizes HTTP work, above all other work, is the amount of paperwork you have to fill out before you can even get any where.

• At the backend you have to structure your service as a tree of "routes," each of which terminate with a verb (get, post, delete, put) and take low-entropy input (either URL query parameters or free-form request body bytes). These dovetail into other essential, and soul-crushingly boring, problems like (1) how do I convert my data structures (high entropy) to and from JSON (low entropy)? or (2) .






From what little I remember of high-school Advanced Placement Physics AB, I believe every HTTP service is a sort of thermodynamic cycle – some machine that takes in a smattering of URL query parameters and JSON (low-entropy data), deserializes it into data structures complected with business logic and software architecture (high entropy), does work, and serializes the work as the response (low entropy, once more).

Among Haskell packages, Servant has quickly established itself as a very good framework for writing web apps. Servant, like Rails before it, is an opinionated web framework. It believes in the idea that we _can_ and we _should_ code at the type level. That _type-level programming_ is the tool by which we will end up with shorter, safer, and more robust programs. Because, as we will soon see, Servant's pushes you the programmer to declare your web service as a single type. We will attempt to spell out how this works and why it is a marvelous new idea in this blog post.

A word of warning: the code snippets below are in Haskell and I will assume you have some knowledge of a modern functional programming language. However, the idea of type-level programming is broad and applicable to all practitioners of software engineering. As we go through I will try and explain the quirks of Haskell syntax where they arise, and my hope is that a curious reader with no background in Haskell could walk away with something gained from reading this unusually long blog post.

Being able to represent data at the type level is something that, I confess, I am wholly enamored with. For those of us who have programmed for an unhealthy amount of time, this is somewhat of a holy grail. Though type-level programming has been around for a long time (see: Coq, released the year _Lethal Weapon 2_ came out) what is happening right now with GHC Haskell is unique. For the first time we are marrying the principles of dependently-typed functional programming languages with a production-quality runtime friendly to systems programming _and_ a healthy even thriving community of people and libraries. Something exciting is happening. This is our time. This is our _clear eyes full hearts_. So, thesis: in this blog post we will attempt to sketch how one might represent a web service, something fairly complicated and practical, at the type level and – in the process – de-mystify type-level gymnastics.

## Type-level functions

A simple and common kind of type-level primitive is the function. Though we often do not call it that, it is indeed possible to build type-level functions, and we tend to do it without second thought when we build algebraic data types. For example, lists:

```haskell
data [a] = [] | a:[a]
```

A list takes a type from the "usual" "universe" of types (`Int`, `Int -> Float`, `IO (Int -> Float)`, ...) and returns another type (`[Int]`, `[Int -> Float]`, `[IO (Int -> Float)]`, ...). We put these words into scare quotes to heavily signify that To abbreviate this idea, we say it has _kind_ `* -> *`.

```haskell
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

We will attempt to force ourselves to think of this as a type-level function because, as we will see, the analogy between values and types and types and kinds (an SAT analogy, for alumni of the U.S. education system) is one that will anchor us to reality as matters get hairier.

So, to beat the analogy to death:

* Our Lispy cons-list is a higher-order type parametrized by the element type. So it has kind `* -> *`.

* When we specify the type of element kind, we reduce the arity of its kind to `*`. This is like calling a function.

* A function like `\x -> x * 2` is parametrized by the number `x`. So it has type `Num a => a -> a`.

* When we call the function with a number, we reduce the arity of its type to `Num a => a`.

Can we explicitly construct type-level functions? Something like this, perhaps:


```haskell
type Pair = \a -> (a, a)
```

This, as opposed to the usual `type Pair a = (a, a)`, would truly clarify the analogy and render it vivid and beautiful. However, theory tells us that type-level lambdas result in terrible type inference. For this reason we will not find them in Haskell.

## Numbers and strings

As of recent GHC versions we also have natural numbers and strings. They live in the `GHC.TypeLits` module and require a `DataKinds` extension:

```haskell
> :set -XDataKinds
> :kind "hello"
"hello" :: GHC.TypeLits.Symbol
> :kind 3
3 :: GHC.TypeLits.Nat
```

Note that we have strayed outside the "usual" "universe," the kind `*`. Unlike the types we know and love in `*`, nothing inhabits these types. There is no value `x` such that `x :: Symbol` or `x :: Nat`. If you were to look up the definitions you would see:

```haskell
data Nat
data Symbol
```

No constructors to speak of. They run, skip, and holler when we typecheck our program

Prior to programming in Coq and Haskell, I thought of types as inert little creatures that were typechecked and then erased by the compiler. They were nice to have around and I adored them, but they did little outside of, as we saw above, being smushed together for function abstraction and application.

Let us dispel that notion:

```haskell
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

```haskell
> import Data.Proxy
> :{ let f :: Proxy (3 ^ x) -> Proxy x;
   |     f Proxy = Proxy
   :}

> :type f (Proxy : Proxy 27)
f (Proxy :: Proxy 27) :: Proxy 3

> f (Proxy :: Proxy 27)
Proxy
```

Here we see the compiler's solving the equation `3 ^ x = 27`. We did this by convincing the compiler to solve the constraint `Proxy (3 ^ x) ~ 27`, which generates the subconstraint `3 ^ x ~ 27`, which (thanks to internal GHC smarts) results in `x ~ 3`. To drive the point home, let us find the logarithm for `28` and `3 ^ 1024 = 3733918...`.

```haskell
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
f (Proxy :: Proxy 3733918[snip]6481) :: Proxy 1024
```

It is perhaps this, above all else, that illustrates so clearly what we mean when we say that we can make the type checker perform work for us at compile time. We are used to the idea that types are inert little things, that either unify successfully or end up with a type error. But in GHC Haskell we see that types are considerably smarter and more cunning. They can encode functions, numbers, and strings. They can do a little math. And, as we will see, they can represent the structure of a web service.

So, to recap:

* We have been creating type-level functions all this time without knowing it.
* Most day-to-day types, the types with values that inhabit them and that take part in runtime computation, have kind `*`.
* There are other kinds besides `*`, like `Nat` (natural numbers) and `Symbol` (strings).
* The types that inhabit `Nat` are type-level natural numbers.
* The types that inhabit `Symbol` are type-level strings.




## Let's build a Servant

Our goals will be Servant's goals:

* A design powered by type-level programming. We should (1) be able to specify the entire HTTP web service as a single type, which we call `type API` with kind `k`; (2) use this kind to Write a type-level function `ServerT` with kind `k -> *`; and (3) have the HTTP server `server` be a value of type `server :: ServerT API`.

* Use real types to model resources, pushing the serialization and deserialization of high-entropy type like JSON or a bytestring to a separate layer. We do not want to see `Data.Aeson.Value` or `Data.ByteString.ByteString` in our `API` declaration.

* Conform to the Web Application Interface (the `type Application = Request -> (Response -> IO ResponseReceived) -> IO ResponseReceived` type) that Haskell frameworks use, so we can take advantage of existing HTTP server libraries like `warp`. We want to avoid parsing HTTP requests and writing HTTP responses in this (already overlong) blog post.

First, we will need a type-level way to link together the different endpoints of our service:

```haskell
{-# language DataKinds #-}
{-# language PolyKinds #-}
{-# language TypeOperators #-}

data head :| tail = head :| tail
infixr 8 :|
```

With the `DataKinds` extension, we are declaring _two_ things here:

* A data constructor with type `(:|) :: head -> tail -> head :| tail`
* A type-level function with kind `(:|) :: * -> * -> *`

Unfortunately they both have the same name.

We will also need a way to encode URL hierarchy for each endpoint:

```haskell
data parent :/ children =
  Slash children
infixr 9 :/
```

Altogether:

We should now be able to write a rudimentary service for a web service with the following endpoints:

* `GET /time`, which returns the UTC time
* `GET /about`, which returns a static string

```haskell
import Data.Time

data GET a

type API =
     "time" :> GET UTCTime
  :| "about" :> GET String
```

While this is a fairly good encoding of our HTTP service, it suffers from a big problem. Nobody knows how to convert `API` into an `Application`. To do so, we'll need to:

* Pattern-match on `:|`, using the request path from the HTTP request to determine which branch to go down
* Pattern-match on `:/`, consuming the request path as we go along
* Throw a 404 should routing fail
* Convert `API` into an `Application`

This is a substantial about of type-level computation to do. If this were at the value level, we could `case`-match on `:|` and `:/`. For types we will have to turn to a surprising friend – typeclasses. Typeclasses, designed to be a safe way to write generic functions that act over an open set of types, turn out to be the analog to pattern matching at the type level. The secret is that typeclasses are a fantastic way of generating constraints. As we saw above, from playing around with logarithms, we can use the constraint solver to decompose types.

For instance, this typeclass will take the type of an API and generate a WAI Application.
