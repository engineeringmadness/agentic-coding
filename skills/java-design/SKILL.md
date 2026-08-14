---
name: java-design
description: Write well-designed Java by applying Venkat Subramaniam's object-oriented and functional design principles. Use this skill whenever writing, reviewing, refactoring, or designing Java code — including creating classes/interfaces, implementing features, converting imperative loops to streams, structuring packages, or making any Java design decision. Trigger on any Java code task, even when the user does not explicitly ask for "design" help, because good design is not a separate step from writing code.
---

# Java Design

A guide to writing well-designed Java, synthesizing Venkat Subramaniam's core design principles for software developers. Two complementary threads run through everything here: **object-oriented design** (how to structure types and their relationships) and **functional design** (how to express behavior with less accidental complexity). They are not competing paradigms — modern Java blends both, and the best code does too.

## The one idea that matters most

> A design is good if the cost of changing it is minimum.

Every principle below exists to lower the cost of change. Software is never written once — it is always rewritten. So design for the second, fifth, and tenth visit to the code, not the first. When you evaluate any decision, ask: *when this needs to change, how much will it cost?*

Two kinds of complexity compete for that cost:

- **Inherent complexity** lives in the problem domain. You cannot remove it, but a good design *hides* it behind clean abstractions so you don't wrestle with it everywhere.
- **Accidental complexity** is self-inflicted — it comes from the solution you chose (concurrency machinery, boilerplate, leaky abstractions). A good design *eliminates* it.

Be ruthless about accidental complexity. But first, learn to recognize it, because of a trap we all fall into:

> Do not confuse **familiar** with **simple**.

A `for` loop with four mutable variables is *familiar*, not *simple*. A stream pipeline may feel *unfamiliar* yet be genuinely *simpler*. Judge code by whether it keeps you focused, solves only the real problem at hand, fails less, and is easy to understand — not by whether it looks like code you've written a thousand times.

## How to use this skill

When writing or modifying Java, move through these phases. They aren't rigid gates — let them inform your instincts:

1. **Understand the real problem.** Only solve problems you actually know about. If a requirement is vague, clarify it before coding — surprises discovered late are expensive.
2. **Write the simplest thing that works.** Favor YAGNI: don't build for hypothetical futures. You can always add extensibility on the *second* occurrence (the rule of three is your friend), when you have real evidence of what's needed.
3. **Structure for cohesion and low coupling** — see the OO principles.
4. **Express behavior declaratively** — see the functional principles.
5. **Make it verifiable.** A design you can't automatically test is a design you can't safely change or postpone decisions in. Write tests; they are the safety net that makes every other principle practical.
6. **Refactor on the way out.** Software is rewritten. Review what you wrote with fresh eyes, delete and redo where it's bad, and remove duplication the second time a pattern appears.

Read the reference files when you need the deeper reasoning and worked examples behind a principle:
- `references/oo-design.md` — the SOLID principles, cohesion/coupling, OCP via polymorphism, when inheritance is a trap, DIP with lambdas.
- `references/functional-design.md` — declarative style, pipelines, lazy evaluation, the immutability mandate, and spotting bad functional code.

---

## Object-oriented design principles

### High cohesion, low coupling

This is the foundation everything else rests on. A cohesive unit of code is narrow and focused — it does one thing and one thing well. Like things belong together; unlike things stay apart. Cohesive code changes *less frequently* (because it has only one reason to change), which directly lowers cost.

Coupling is the degree of connectivity between units. Every dependency increases it. The goal is to *remove* coupling where you can, and make what remains *loose*:

- Depending on a **concrete class** is tight coupling.
- Depending on an **interface** is loose coupling.
- **Inheritance** is the worst form of coupling in class-based Java — it's rigid and binds you to the parent's full contract. Treat it as a last resort, not a default.
- **Cyclic coupling** (A depends on B depends on A) is poison — break it.

A good design has **high cohesion and low coupling**. Evaluate every class and method against this pair.

### Single Responsibility Principle (SRP)

SRP is cohesion made explicit: a class or method should have exactly one primary responsibility. The giveaway that you've violated it is the word **"and"** — "this class validates input *and* persists it *and* sends email." Split it.

**Long methods are the number-one offender.** They are the diagonal opposite of good design: low cohesion, high coupling, hard to test, hard to read, hard to reuse, and they breed duplication (you can't extract the part you need, so you copy-paste). When you see a long method peppered with comments explaining each section, those comments are signposts for `extract method`. Extract until each method reads as one step at a single level of abstraction.

### Single Level of Abstraction Principle (SLAP)

Within a method, keep all statements at the same level of abstraction. Code should read like a well-told story: high-level steps first ("went to the park, then a movie"), with details available by descending into extracted methods — never mixed in the same body. When a method mixes "send the report" with "open a socket, write bytes, flush" in the same breath, it fails SLAP. This is the *composed method* pattern: a method is composed of calls to other well-named methods, each at its own level. The method names *become* the documentation.

### Don't Repeat Yourself (DRY)

Every piece of knowledge in a system should have one unambiguous, authoritative representation. DRY covers two things: **duplication of code** (obvious) and **duplication of effort** (subtle — when one business change forces edits in five places that aren't copies of each other but all derive from the same fact). Both are expensive and error-prone.

Balance DRY with YAGNI: don't preemptively extract abstractions. The first time you write something, just write it. The *second* time you reach for the same logic, that's the signal to refactor and remove the duplication. Waiting for the real second use prevents premature abstractions that are often wrong.

### YAGNI — You Aren't Going To Need It (yet)

Don't implement something until you have a clear reason to. We are smarter tomorrow than today — we'll have more information, more data points, better judgment. Postponing decisions to the last responsible moment buys you better-informed choices.

This is *not* procrastination. Procrastination is skipping what should be done now. YAGNI is the courage to defer what genuinely *can* wait. When deciding whether to implement a feature or design extension now:

- If implementing now costs more than later → postpone.
- If the costs are equal → postpone (you'll know more tomorrow).
- If implementing now costs less → ask how *probable* it is. High probability: do it now. Low: postpone.

YAGNI is only safe with good automated tests — without a feedback loop, postponement becomes recklessness, because you can't verify a late change didn't break things.

### Open-Closed Principle (OCP)

A module should be **open for extension but closed for modification**: you should be able to add new behavior without editing existing code. The enemies of OCP are conditionals that branch on type — chains of `if/else` with `instanceof`, or switch statements that must be edited every time a new type appears. When the only way to support a new type is to open a method and add another branch, OCP is broken.

The tools that make OCP possible are **abstraction and polymorphism**. A new type should be added by creating a new class that implements an existing interface, not by editing a method. Note a Java-specific wrinkle: `new` is *not* polymorphic. That's why factories exist — to restore polymorphic creation. When you see copy/creation logic that branches on concrete type (`if (x instanceof TurboEngine)`), push the polymorphic behavior *into* the type hierarchy (e.g., a `copy()` method overridden by each subclass) rather than branching externally.

Apply YAGNI *before* OCP. Don't make everything infinitely extensible — that breeds complexity. Extensibility requires knowing both the software and the domain, so collaborate with domain experts: ask what's *actually* likely to change and its probability. Design for extension only where the evidence justifies the cost. Introduce extensibility on the second occurrence (refactor toward OCP then), not speculatively on the first.

### Liskov Substitution Principle (LSP)

Use inheritance **only** for substitutability — when an object of the derived class must be usable anywhere the base is expected, with the user never knowing the difference. If your reason for inheriting is "to reuse some methods," that's not substitutability; use **composition or delegation** instead.

The contract is strict: a derived class's services must **require no more and promise no less** than the base's. You can be more permissive (e.g., widen a `protected` method to `public`, or throw fewer exceptions), but never more restrictive. Java enforces part of this at compile time — you can't narrow visibility, can't throw new checked exceptions, and a `List<Derived>` does not extend `List<Base>` (because mixing them would violate invariants).

The classic violation is `Stack extends Vector`: a Stack's invariant (LIFO only) is destroyed the moment someone treats it as a Vector and inserts/removes arbitrarily. When a subtype breaks the base's invariants, every user must add type checks (`if (x instanceof Derived)`), which then breaks *their* OCP. Violating LSP cascades into violating OCP in the consuming code. Prefer composition: `Stack` should *use* a `Vector` internally, not *be* one.

When you need a class's behavior but not its substitutability, delegate. In Java this is often typed by hand or generated by an IDE's "replace inheritance with delegation" refactor; the trade-off is minor DRY/OCP friction (you maintain the delegating methods), which is almost always preferable to a false `extends`.

### Dependency Inversion Principle (DIP)

A class should not depend on another concrete class. Both should depend on an **abstraction** (interface). This inverts the dependency direction from concrete-to-concrete to concrete-to-interface, lowering coupling and making the code testable (you can swap real for mock).

DIP pairs naturally with OCP: where you're tempted to write `if/else` to switch behaviors, instead inject a strategy through an interface. And with Java 8+, you can make single-method strategy interfaces **functional interfaces** and pass lambdas as implementations — far lighter than anonymous inner classes or class hierarchies. Use this to keep designs nimble.

Use DIP deliberately, not everywhere. Every interface has a cost (indirection, more files). Reach for it when you need to decouple, swap implementations (testing, alternate strategies), or avoid type-branching. Don't sprinkle interfaces on every class "just in case" — that's accidental complexity and a YAGNI violation.

### Interface Segregation Principle (ISP)

SRP applied to interfaces: keep interfaces narrow and focused. Don't force a class to implement methods it doesn't need because they sit on a fat interface. Split a bloated interface (`Clock` that does timekeeping *and* alarms *and* radio) into cohesive role interfaces (`Timepiece`, `Alarm`, `Radio`) and let a class implement the ones that apply. Clients depend only on the narrow interface they actually use.

### Self-documenting code; comment the why, not the what

Code is like a joke: if you have to explain it, refactor it — don't slap a comment on it. Comments that describe *what* code does are usually covering up unreadable code, and they rot: the code changes, the comment doesn't, and now it actively misleads. Make the code readable enough that the *what* is obvious (good names, short methods, SLAP). Reserve comments for *why* — the intent and constraints that aren't visible in the code itself.

---

## Functional design principles

Modern Java's streams and lambdas let you write in a functional style. Functional programming is **declarative style plus higher-order functions**. It's not an all-or-nothing switch — use it where it reduces accidental complexity.

### Prefer declarative over imperative

Imperative code tells *what* and *how* — every loop counter, every mutation, every `break` is a detail dumped on the reader. Declarative code tells *what* and delegates the *how*:

```java
// Imperative — details on your face, fails SLAP
boolean found = false;
for (int i = 0; i < names.size(); i++) {
    if (names.get(i).equals("Nemo")) { found = true; break; }
}

// Declarative — one level of abstraction, details encapsulated
boolean found = names.contains("Nemo");
```

Declarative code honors SLAP: at this level you ask "is it there?" and the *how* lives one level down, available on demand but not in your face. Reach for the higher-level operation (`contains`, `stream().filter(...)`, `Collectors.groupingBy`) over hand-rolled loops. This is how you eliminate accidental complexity.

### Functional composition and the pipeline pattern

Model data as flowing through a **pipeline** of transformations — `stream().filter().map().collect()`. Each step is a small, focused function; you compose them like you compose objects. This makes the data's journey readable and each piece independently testable. When a transformation is one-to-many (e.g., each input number becomes its neighbors), reach for `flatMap`, not nested loops.

### Lazy evaluation

Stream pipelines are **lazy**: intermediate operations (`filter`, `map`) do no work until a terminal operation (`collect`, `findFirst`, `count`) pulls results, and they do the *minimum* work needed. A `findFirst` after a `filter` stops at the first match. Lean on this — don't eagerly materialize collections mid-pipeline. Let the pipeline fuse and short-circuit.

### The immutability mandate

Lazy evaluation and parallel streams **rely on immutability for correctness**. This is not stylistic preference — it's existential. If intermediate operations mutate shared state, the pipeline will run efficiently and give you the *wrong* answer, which is worse than being slow. Prefer:

- Immutable collections (`List.of`, `Map.of`, unmodifiable views) and records for value types.
- Pure functions in stream operations — no side effects.
- `Collectors.toUnmodifiableList()` over mutating a list you then return.

### Never mutate inside intermediate operations

This deserves its own callout because it's the most common functional-code crime (and one AI tools reproduce because they were trained on bad code):

```java
// WRONG — filter is a read-only operation; mutating here is a serious bug
Set<Character> seen = new HashSet<>();
return word.chars()
    .filter(c -> seen.add((char) c))   // side effect inside filter!
    .findFirst();
```

`filter`, `map`, and other intermediate operations must be **pure and side-effect-free**. Mutating external state inside them breaks laziness, breaks parallelism, and produces nondeterministic results. If you need stateful logic, use the dedicated operations designed for it (`Collectors.groupingBy`, `Collectors.toMap`, `reduce`) rather than smuggling mutation through a `filter`.

### Use higher-order functions, not boilerplate

Higher-order functions take, create, or return functions. In Java this means lambdas and method references. When a strategy interface has a single abstract method, make it a `@FunctionalInterface` and pass a lambda — this is the lightweight realization of DIP and the strategy pattern. Favor method references (`String::toUpperCase`) over their lambda equivalents where they aid readability.

### Restraint and naming

- **Don't write more code than the problem requires.** There's a tendency (especially in AI-generated code) to add defensive null checks, lowercase normalization, or extensibility hooks that the requirements never asked for. Each is accidental complexity and a place for bugs. Solve the real problem; nothing more.
- **Use meaningful names.** Single-letter parameters (`w`, `x`) are a relic of terse imperative code; in a stream pipeline they destroy readability. Name parameters by what they represent.
- **Don't confuse unfamiliar with complex.** A stream pipeline may feel harder to read than a `for` loop only because it's less familiar to you. Give it a fair evaluation on simplicity before retreating to the familiar imperative form.

---

## Bridging OO and functional in modern Java

The two threads weave together. A few concrete blends:

- **Strategy via lambda, not class hierarchy.** Where you'd once define an interface + several implementing classes for a strategy, define a functional interface and pass lambdas or method references. DIP stays, the boilerplate leaves.
- **Polymorphism for structure, functions for behavior.** Use OO to model the nouns and their substitutable relationships (types, interfaces, composition). Use functional style to express the verbs (transformations, queries) inside those types.
- **Records for immutable value types.** Records give you cohesive, immutable, equality-by-value types with almost no boilerplate — ideal for the data flowing through your pipelines and for DIP's abstractions.
- **Keep optionals honest.** Return `Optional<T>` rather than null to make absence explicit at the type level; don't use `Optional` for fields or parameters, only return types.

## Quick design checklist

Before you consider Java code done, run through this:

- [ ] Does each class/method have **one responsibility**? Any "and" in its description is a split candidate.
- [ ] Are methods **short and at one level of abstraction**? Extract until they read as a story.
- [ ] Is coupling **loose** — interfaces over concrete classes, composition over inheritance? Any `instanceof` branching is an OCP smell.
- [ ] Is inheritance used **only** for substitutability, never just for code reuse?
- [ ] Is knowledge represented **once** (DRY)? Duplicated the second time you needed it, then refactored?
- [ ] Did you **avoid building for hypothetical needs** (YAGNI)? Extensibility added on real evidence, not speculation?
- [ ] Are loops expressed **declaratively** where it reduces complexity — streams over hand-rolled iteration?
- [ ] Is data **immutable** by default, and are stream operations **pure** with no mutation in `filter`/`map`?
- [ ] Does the code **document itself**? Comments explain *why*, not *what*.
- [ ] Is it **testable** — can you verify a change automatically? Without that, postponement is unsafe.
