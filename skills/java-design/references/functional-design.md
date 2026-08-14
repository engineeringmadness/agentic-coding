# Functional Design — Principles in Depth

Deep reference for the functional design principles in the main SKILL.md, drawn from Venkat
Subramaniam's functional-programming talk. Read this when you need the reasoning behind declarative
style, laziness, the immutability mandate, or how to spot bad functional code (including
AI-generated).

## Table of contents
1. [Imperative vs. declarative](#1-imperative-vs-declarative)
2. [What functional programming actually is](#2-what-functional-programming-actually-is)
3. [Functional composition](#3-functional-composition)
4. [The familiar-vs-simple trap (again)](#4-the-familiar-vs-simple-trap-again)
5. [The three tenets: pipeline, laziness, immutability](#5-the-three-tenets-pipeline-laziness-immutability)
6. [Never mutate in intermediate operations](#6-never-mutate-in-intermediate-operations)
7. [Higher-order functions in Java](#7-higher-order-functions-in-java)
8. [flatMap for one-to-many](#8-flatmap-for-one-to-many)
9. [Restraint, naming, and reading AI-generated code](#9-restraint-naming-and-reading-ai-generated-code)

---

## 1. Imperative vs. declarative

**Imperative style** tells *what* to do *and how* to do it — every step, every detail. Searching a
list by hand:
```java
boolean found = false;
for (int i = 0; i < names.size(); i++) {     // size? length? < or <=? i++ or ++i?
    if (names.get(i).equals("Nemo")) {         // .equals or == ?
        found = true;
        break;                                  // don't forget the break!
    }
}
```
This is *familiar*, but the details are "on your face." To know what it does you must read every
line; you get tangled in accidental complexity (off-by-one, equality semantics, control flow). It
feels like the uncle who traps you in a three-hour conversation the moment you say hello.

**Declarative style** tells *what*, not *how*, and delegates the how to library functions:
```java
boolean found = names.contains("Nemo");
```
Here you don't care *how* `contains` works — it's encapsulated. If you ever need to know, you can
descend into it, but it's not in your face. This **honors SLAP**: at your level you ask "is it
there?" and the mechanism lives one level down. Declarative code reduces accidental complexity.

## 2. What functional programming actually is

Functional programming is **declarative style + higher-order functions.** The relationship:
- Not everything declarative is functional (`contains` is declarative but not functional).
- Everything functional is declarative.

Functional style is built *on top of* declarative style, adding the ability to pass, create, and
return functions — treating **code as data.** Just as you compose objects (a pen = tube + spring +
tip + housing), you compose functions into bigger functions. This gives a different, complementary
way to model a system: object decomposition *and* functional composition.

## 3. Functional composition

Compose small functions into a pipeline: `source → filter → map → reduce/collect`. Each stage is a
focused transformation; you reason about the whole as a series of steps rather than a tangle of
loops and mutations. This is the functional analog of the OO composed-method pattern — small pieces,
clearly named, at one level of abstraction.

## 4. The familiar-vs-simple trap (again)

This is the single biggest barrier to adopting functional style. When you first see:
```java
names.stream()
     .filter(name -> name.length() == 5)
     .map(String::toUpperCase)
     .toList();
```
...it feels "hard." But that judgment is usually about *familiarity*, not *simplicity*. You can't
fairly call something complex if you don't yet understand it. The imperative loop you've written ten
thousand times is *familiar*; it may well be *more complex*. Become familiar first, *then* evaluate
simplicity. (Analogy: a script you can't read looks complex, but that's *your* ignorance, not the
script's complexity.)

## 5. The three tenets: pipeline, laziness, immutability

Functional programming is functional **composition + lazy evaluation**, and lazy evaluation
**relies on immutability for correctness.** These three are inseparable:

**Pipeline pattern.** Data flows and transforms through a pipeline of functions, like water through
a filter and a heater — each stage transforms the data as it passes. Design so the data's journey is
visible as a sequence of transformations.

**Lazy evaluation.** Intermediate operations (`filter`, `map`, `flatMap`) do *no work* until a
terminal operation (`collect`, `findFirst`, `count`, `reduce`) pulls results — and they do the
*minimum* work needed. A `findFirst` after a `filter` stops at the first match; the rest of the source
is never processed. Laziness makes pipelines efficient (less work, less garbage). Lean on it — don't
eagerly materialize intermediate collections that defeat the pipeline's fusion and short-circuiting.

**Immutability (the existential one).** Why do functional programmers insist on immutability? Not
because it's fashionable — because **laziness (and parallelism) depend on it for correctness.** If
operations have side effects or mutate shared state, the pipeline runs efficiently and delivers the
*wrong answer* — worse than being slow. So:
- Prefer immutable collections and records for values.
- Keep functions in stream operations **pure** (no side effects).
- Mutating state that a lazy/parallel stream reads or writes produces nondeterministic results.

> Immutability is not a stylistic preference in functional code — it's what makes laziness correct.

## 6. Never mutate in intermediate operations

The most common functional-code crime, and one AI tools reproduce because they were trained on bad
code. Intermediate operations (`filter`, `map`, `flatMap`, `sorted`) must be **pure and
side-effect-free.**

```java
// WRONG — mutating external state inside filter; non-deterministic, breaks under laziness/parallelism
Set<Character> seen = new HashSet<>();
return word.chars()
           .mapToObj(c -> (char) c)
           .filter(c -> seen.add(c))     // SIDE EFFECT inside a read-only op!
           .findFirst();
```

`filter` is a *read-only* operation — it decides what passes through; it must never change the world.
Mutating `seen` there breaks laziness (you can't predict when/if the lambda runs) and parallelism
(race conditions). If you need stateful logic, use the operations *designed* to carry state safely:
- `Collectors.groupingBy` / `Collectors.toMap` / `Collectors.toSet` for accumulation.
- `reduce` for folding.
- `Stream.distinct()` rather than hand-rolling a `seen` set.

```java
// RIGHT — use the built-in stateful operation
return word.chars()
           .mapToObj(c -> (char) c)
           .distinct()                   // or Collectors if you need grouping
           .findFirst();
```

The smell test: if a lambda passed to `filter`/`map` mutates anything outside itself, it's wrong.

## 7. Higher-order functions in Java

Higher-order functions take, create, or return functions. In Java this means **lambdas** and
**method references.** A single-method interface is a **functional interface** (`@FunctionalInterface`),
and a lambda is its instance. This is the lightweight bridge to OO design:
- A strategy that once required an interface + N implementing classes becomes a functional interface
  + N lambdas/method references. Same DIP/strategy decoupling, a fraction of the boilerplate.
- Favor method references (`String::toUpperCase`) over the equivalent lambda
  (`s -> s.toUpperCase()`) when they're clearer — they name the operation without restating the
  parameter.
- Keep lambdas short and pure; if a lambda grows, extract it into a named method and reference it.

## 8. flatMap for one-to-many

When each input element maps to *multiple* outputs (a one-to-many transformation), use `flatMap`,
not nested loops or a manual accumulator. Example — given numbers, produce each number's neighbors:
```java
// Given [7, 12, 21] → [6, 8, 11, 13, 20, 22]
List<Integer> neighbors = numbers.stream()
    .flatMap(n -> Stream.of(n - 1, n + 1))
    .toList();
```
`flatMap` flattens the streams-of-streams into one pipeline. Recognizing the one-to-many shape and
reaching for `flatMap` is a key functional instinct — one that doesn't come automatically and that
takes a little experience to spot.

## 9. Restraint, naming, and reading AI-generated code

Functional code (especially AI-generated) tends to over-generate. Evaluate output against these
lenses:

- **Don't write more than the problem requires.** AI often adds defensive null checks, lowercase
  normalization, or empty-string filtering that the requirements never mentioned. Each is accidental
  complexity and a bug surface. Solve the real problem; nothing more. (Why does AI do this? It
  mirrors what most humans write — and humans write more than needed, for "extensibility" or to
  impress. Don't reward that.)
- **Use meaningful names, not single letters.** `w -> w.charAt(0)` is far less readable than
  `word -> word.charAt(0)`. Single-letter parameters are a relic of terse imperative code and destroy
  pipeline readability. Always name parameters by what they represent.
- **Verify correctness, not just style.** AI may produce a `flatMap` for a one-to-many problem
  (good instinct) but include the original element when only neighbors were asked (wrong). Check
  the output actually does what was requested.
- **Never tolerate mutation inside intermediate operations.** This is the clearest red flag. If
  generated code mutates state in a `filter`/`map`, reject it — it's a serious bug, not a style
  nit.
- **Try more than one source and converge.** Different models produce inconsistent output. Comparing
  two or three solutions often surfaces the right shape and reveals where each went wrong. The goal
  isn't to trust any single output but to converge on something acceptable through evaluation.
- **Don't blame the language for the code's flaws.** When AI produces a convoluted "solution" and
  then claims "this problem is a poor fit for Java" or "Java is inherently stateful," that's the
  model covering for its own poor solution. The language is rarely the problem; the implementation
  is. A correct, simple functional solution almost always exists.
