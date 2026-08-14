# Object-Oriented Design — Principles in Depth

Deep reference for the OO design principles in the main SKILL.md, drawn from Venkat
Subramaniam's "Core Design Principles for Software Developers." Read this when you need the
reasoning, the failure modes, or worked Java examples behind a principle.

## Table of contents
1. [What "good design" means](#1-what-good-design-means)
2. [KISS, and simple vs. familiar](#2-kiss-and-simple-vs-familiar)
3. [YAGNI — postpone to the last responsible moment](#3-yagni--postpone-to-the-last-responsible-moment)
4. [Cohesion](#4-cohesion)
5. [Coupling](#5-coupling)
6. [DRY — code and effort](#6-dry--code-and-effort)
7. [Single Responsibility Principle](#7-single-responsibility-principle)
8. [SLAP and the composed method](#8-slap-and-the-composed-method)
9. [Long methods](#9-long-methods)
10. [Open-Closed Principle](#10-open-closed-principle)
11. [Liskov Substitution Principle](#11-liskov-substitution-principle)
12. [Dependency Inversion Principle](#12-dependency-inversion-principle)
13. [Interface Segregation Principle](#13-interface-segregation-principle)
14. [Comments and self-documenting code](#14-comments-and-self-documenting-code)

---

## 1. What "good design" means

A design is good if the **cost of changing it is minimum**. The catch: you often only discover a
design is bad *when it's time to change it*, which is too late. So proactively subject designs to
change as you build them, and evolve toward easier-to-change.

Software is never written once; it is always rewritten. Any software that is relevant *must* change.
If someone claims they wrote it once and never touched it again, their project was cancelled.

Prerequisites for good design are mostly non-technical:
- **Let go of ego.** You cannot be perfect. Ego is like cholesterol — keep the good parts (pride,
  passion) and shed the parts that stifle progress.
- **Be unemotional** about solutions. Stay attached to *solving the problem*, not to *your* solution.
  Invite challenge: "do this, or come up with something better."
- **Review design and code constantly.** Reviewing others' code helps them and teaches you. Tactical,
  ongoing reviews beat grandiose ones.

## 2. KISS, and simple vs. familiar

Keep it simple. Complexity is the thing to fear most — it makes code hard to change, and we create it
astonishingly fast. Simplicity means:
- Keeps you focused (doesn't distract with details).
- Solves only the real problem you know about (don't code for problems you don't understand yet).
- Fails less (resilient, robust).
- Easier to understand (for people who share the context).

**Inherent vs. accidental complexity.** Inherent complexity belongs to the problem domain — you can't
remove it, but you can *hide* it. Accidental complexity comes from your solution and snowballs: a
solution brings complexity, you add another solution to manage that, which brings more. Concurrency
machinery (manual threads, locks, synchronization) is the canonical example — often the problem didn't
demand that solution. Step back and ask: *what problem am I actually trying to solve?* Maybe a
different solution avoids the consequences entirely.

A good design **hides inherent complexity and eliminates accidental complexity**.

**The familiar trap.** Don't confuse *simple* with *familiar*. A `while` loop with four mutable
variables is familiar, not simple. Something unfamiliar might be far simpler. You can only judge
simplicity once you're familiar enough to evaluate it — so don't dismiss an unfamiliar idiom as
"complex" just because you haven't used it.

## 3. YAGNI — postpone to the last responsible moment

You Aren't Going To Need It (yet). We implement far more than we need. Postpone until you have a clear
reason, because we are smarter tomorrow — more information, more data points, better judgment.

Decision rule for "implement now vs. later":
- Cost now > cost later → **postpone**.
- Cost now == cost later → **postpone** (you'll know more).
- Cost now < cost later → ask how **probable** the need is. High probability: do now. Low: postpone.

Ken Beck: "Courage is postponing the decisions of tomorrow to tomorrow." This is courage, not
procrastination. Procrastination is skipping what should already be done.

**Why we don't postpone — fear.** We're scared to change late. But fear comes from a poor feedback
loop. If testing is manual, any late change is terrifying ("are you crazy?"). With strong automated
tests, a late change is "give it a try." So **a good design is automatically verifiable.** Tests are
the safety net that makes YAGNI, refactoring, and postponed decisions all safe. Without them you can
only curl up and hope.

Example: Venkat used SQLite during a 6-month build precisely to keep the schema agile, postponing the
real DB choice until two weeks before production — when every other decision was settled. When the
switchover tests failed, a single data-type fix (found via the error message) resolved it, validated
by the test suite. The tests made the late, scary change safe.

**Implement one collaborator first.** If you need seven similar classes plus a top-level class, design
*one* collaborator and the top-level together first (multiple instances of the one class), learn how
they fit, *then* add the rest. Don't build all seven blind. It's like fitting a cabinet: tighten
pieces just enough to hold, align everything, *then* tighten — over-tightening one piece early
misaligns the rest.

## 4. Cohesion

A piece of code is cohesive when it is **narrow, focused, and does one thing well.** Like things
together; unlike things apart. (Kitchen utensils in the kitchen; socks with socks.)

Why it matters: cohesive code **changes less frequently**. A module doing seven things changes every
day; a module doing one thing changes only when that one thing changes. Less frequent change = lower
cost, and less risk of breaking unrelated behavior when you do edit it.

## 5. Coupling

Coupling is the **degree of connectivity** among things — what you depend on.

- **Remove** coupling first if you can. Often we assume a dependency is necessary when a redesign
  eliminates it entirely. ("Knock out before you mark out" — don't mock a dependency you could have
  removed.)
- **Loosen** what remains. Depend on an **interface** (loose) rather than a **class** (tight).
- Avoid **cyclic coupling** (A→B→A) — extremely hard to maintain.

**Inheritance is the worst coupling.** Class-based Java inheritance is rigid; it binds you to the
parent's full contract and implementation. Prefer composition/delegation. You can't remove *all*
dependencies (the system wouldn't run), but minimize and loosen.

Good design = **high cohesion, low coupling.**

## 6. DRY — code and effort

Don't Repeat Yourself. It covers *two* duplications:
1. **Code** — the obvious copy-paste.
2. **Effort** — when one underlying change forces edits in many places that aren't literal copies but
   all derive from the same fact. E.g., a schema change ripples to the model, DAO, controller, view,
   config. Or validation written separately in Java (server) and JS (client) because "they're
   different languages." That's duplicated *effort* even though the code differs.

Every piece of knowledge in a system should have a **single, unambiguous, authoritative
representation.** (The Pragmatic Programmers.)

Why care: the "future you" thanks you. And the team that re-discovers the same bug every two months
because it's copy-pasted in a dozen places. Tools like CPD (copy-paste detector) or Simian can find
duplicated code, including convoluted copies.

**Balance with YAGNI:** don't create abstractions or extract functions preemptively. Write it once;
on the *second* real occurrence, refactor to remove the duplication. This avoids premature
abstractions that are often wrong.

## 7. Single Responsibility Principle

SRP is cohesion stated as a rule: a class or method has exactly one primary responsibility. The
**"and"** is the giveaway — "this method validates *and* persists *and* notifies" means it's doing too
much. Split it. Violating SRP often cascades into violating other principles.

## 8. SLAP and the composed method

**Single Level of Abstraction Principle:** within a method, keep statements at one level of
abstraction. Code should read like meaningful human speech — high-level first ("went to the park,
then a movie"), with detail available on demand by descending into extracted methods, never jumbled
in the same body. Mixing "generate the report" with "write bytes to a socket" in one method fails
SLAP.

The **composed method pattern:** a method is composed of calls to other well-named methods, each at
its own level. The sequence of calls *is* the documentation — the method names tell the story. A
scratch placeholder word for "what's my abstraction here?" can be promoted to the method name.

## 9. Long methods

Long methods are the number-one design problem. They are the diagonal opposite of good design:
**low cohesion, high coupling.** They are:
- Hard to test (huge permutation space).
- Hard to read, remember, debug (the debugger is a "victim").
- Hard to reuse → you copy-paste → they breed duplication.
- Have many reasons to change.
- Can't be optimized by the JVM or anything else.

How long is too long? Line counts are a losing argument. The real test is **SLAP**: can you see the
whole method at one level of abstraction? The comments scattered through a long method ("// now do
X", "// then handle Y") are extract-method signposts — each comment marks a method waiting to be
born. Extract until the method reads as a sequence of well-named steps.

## 10. Open-Closed Principle

A module should be **open for extension, closed for modification** — you can add behavior without
editing existing code. Given a choice between "edit existing code" and "add a new module," always
prefer adding: it's the path of least resistance and doesn't risk existing working code.

**Abstraction and polymorphism** make OCP possible. The enemy is type-branching: `if/else` chains
with `instanceof`, or switches that must be edited for each new type. When adding a type forces you
to open and edit a method, OCP is broken.

**`new` is not polymorphic in Java.** (Nor C++/C#; Ruby's `new` is.) That's the whole reason factories
exist — to restore polymorphic creation. Watch for copy/creation that branches on concrete type and
push the behavior into the hierarchy.

Worked example (copying a Car's Engine):
```java
// BROKEN OCP — adding an engine type forces editing this constructor
public Car(Car other) {
    this.year = other.year;
    if (other.engine instanceof TurboEngine)
        this.engine = new TurboEngine((TurboEngine) other.engine);
    else
        this.engine = new Engine(other.engine);   // loses subtype!
}
```
Adding a `PistonEngine` means reopening `Car` and adding another branch — and the duplication spreads
wherever this decision appears. Fix it with a polymorphic `copy()`:
```java
class Engine {
    private final ... ;
    protected Engine(Engine other) { /* copy fields */ }
    public Engine copy() { return new Engine(this); }   // polymorphic creation
}
class TurboEngine extends Engine {
    @Override public TurboEngine copy() { return new TurboEngine(this); }
}
// Car no longer branches on type:
public Car(Car other) {
    this.year = other.year;
    this.engine = other.engine.copy();   // dispatches to the right subtype
}
```
Now `Car` is closed for modification when a new `Engine` subtype is added. Keep the duplicated
`copy()` bodies DRY (e.g., reflection or a shared helper) if they're truly identical.

**Caveats:**
- A class is only extensible for what you *designed* it to be extensible for. Nothing is infinitely
  extensible. ("Infinite extensibility" comes from divine power or a lie.)
- More extensibility = more complexity. Apply **YAGNI first**: don't speculatively design for
  extension. Extensibility requires knowing both the **software** (cost of change) and the **domain**
  (what's likely to change). Collaborate with domain experts: ask what's probable and the
  consequences. Introduce extension on the *second* real occurrence, refactored toward OCP then — not
  on the first speculative pass.

## 11. Liskov Substitution Principle

Use inheritance **only** for substitutability: a derived object must be usable anywhere a base is
expected, with the user never knowing the difference. If your reason to inherit is "reuse a few
methods," that's not substitutability — use **composition or delegation**.

The contract: a derived class's services must **require no more and promise no less** than the base's.
- You *may* be more permissive (e.g., `protected` → `public`, throw fewer exceptions).
- You *may not* be more restrictive.

Java enforces part of this at compile time:
- Can't narrow visibility (e.g., `public` base method → `protected` derived: compile error).
- Can't throw new checked exceptions not declared by the base (would surprise callers' catch blocks).
- `List<Derived>` does **not** extend `List<Base>` — if it did, you could add a `Base` to a
  `Derived` collection and break its invariants.

**The `Stack extends Vector` violation.** A `Stack`'s invariant is LIFO (push/pop only). But because
it extends `Vector`, any code expecting a `Vector` can insert/remove arbitrarily, destroying the
invariant — and may even throw a runtime exception at the surprised caller. The user of the base
(`Vector`) now *does* know the difference, which is exactly what LSP forbids. Fix: `Stack` should
**use** a `Vector` internally (composition), not **be** one.

**When you need behavior but not substitutability — delegate.** If class `B` wants `A`'s `f1`/`f2`
plus its own `f3`, don't `extends A` (that commits to substitutability you may not intend). Instead,
hold a private `A` and delegate:
```java
class B {                       // NOT extends A
    private final A a = new A();
    public void f1() { a.f1(); }
    public int  f2() { return a.f2(); }
    public void f3() { /* B's own responsibility */ }
}
```
Trade-off: this can lightly violate DRY (you restate the delegating signatures) and OCP (rename `f1`
in `A` and `B` breaks). But that local friction is far preferable to a false `extends` that forces
*every consumer* to add `instanceof` checks — which then violates *their* OCP. Prefer to contain the
sin in your own class rather than spreading it to all callers. IDE "replace inheritance with
delegation" refactors generate this for you; some languages (e.g., Groovy's `@Delegate`) synthesize
it at the bytecode level so you never maintain it by hand.

## 12. Dependency Inversion Principle

A class should not depend on another concrete class; **both should depend on an abstraction**
(interface). This inverts the dependency from concrete→concrete to concrete→interface, lowering
coupling and enabling substitution (real vs. mock in tests).

DIP is what you've already used whenever you swapped a real object for a mock in TDD. It pairs with
OCP: where you'd write `if/else` to switch behaviors, inject a strategy through an interface
instead. The **strategy pattern** is DIP made concrete — you depend on an interface and provide
alternate implementations.

**Modern lightweight realization (Java 8+):** for a single-method strategy, make the interface a
**functional interface** and pass **lambdas** (or method references) instead of anonymous inner
classes or class hierarchies. The design stays decoupled, the boilerplate evaporates.

Use DIP deliberately. Every interface has a cost (indirection, more files, cognitive overhead). Reach
for it when you genuinely need to decouple, swap implementations, or eliminate type-branching. Don't
interface-ify every class "just in case" — that's accidental complexity and a YAGNI violation.

## 13. Interface Segregation Principle

SRP at the interface level: don't build fat interfaces. A `Clock` that exposes timekeeping, alarms,
*and* radio forces every implementer to provide all three, and every client to see methods it
doesn't care about. Split into focused role interfaces:
```java
interface Timepiece { void setTime(LocalTime t); LocalTime getTime(); }
interface Alarm      { void setAlarm(LocalTime t); LocalTime getAlarmTime(); }
interface Radio      { void setStation(double f); }
class ClockRadio implements Timepiece, Alarm, Radio { ... }   // only this class needs all three
```
Clients depend only on the narrow interface they use — a class needing just alarms depends on
`Alarm`, never seeing radio methods.

## 14. Comments and self-documenting code

- **Comment the *why*, not the *what*.** The code already says what it does (or should). If it
  doesn't, *refactor* it readable — don't paper over bad code with a comment. Comments describing
  *what* rot fast: the code changes, the comment doesn't, and it becomes an active lie.
- **Code is like a joke:** if you have to explain it, refactor it; never "explain the joke." Extract
  methods and name them well so the names carry the meaning. The composed-method call sequence
  becomes self-documenting.
- Reserve comments for *intent and constraints* that aren't expressible in the code itself — the
  *why* this exists, the invariant a method assumes, the non-obvious business reason behind a
  threshold.
