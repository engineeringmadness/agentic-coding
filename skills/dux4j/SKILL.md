---
name: dux4j
description: Build state-managed Java applications using the Dux4J library (a Redux/Flux-style store for Java). Use this skill whenever the user wants to create a store, define state, write reducers, add middleware, or attach subscribers with Dux4J — including any mention of "dux4j", "DuxSlice", "DuxSliceBuilder", "ReflectionDuxSliceBuilder", "ReducerBlock", "@AutoStore", or Redux-style state management in Java. Trigger even when the user does not name the library explicitly but is asking for centralized/app state management, a Redux-like store, slices, or unidirectional data flow in a Java project.
---

# Dux4J — Redux-style state management for Java

Dux4J is a Java port of Redux/Flux. State lives in a single store; you change it by dispatching actions through reducer functions, and you observe changes via subscribers. This skill covers the two recommended ways to build a store:

- **Approach 1 — Dux Slice API** (`DuxSliceBuilder`): explicit, code-driven reducer wiring. Best for simpler store layouts with less complex reducer logic.
- **Approach 2 — Auto Reflection API** (`ReflectionDuxSliceBuilder`): classpath-scanned reducers. Best for application-global state or modularized reducer logic.

The older v1 `DuxStore` constructor exists but is not covered here — prefer the Slice or Reflection builders. Both approaches below produce the same `Slice<T>` runtime object, so dispatch, middleware, subscribers, and time-travel behave identically.

## Maven dependency

```xml
<dependency>
    <groupId>dev.engineeringmadness</groupId>
    <artifactId>dux4j</artifactId>
    <version>3.6.0</version>
</dependency>
```

## Core concepts (shared by both APIs)

These building blocks are identical regardless of which builder you choose. Understanding them once makes both approaches clear.

### State

State is a POJO implementing `org.flux.store.api.v1.State`. The interface requires a `clone()` method because the store clones the current state before handing it to a reducer — this protects live state from direct-mutation surprises and makes time-travel (undo/redo) possible.

```java
import org.flux.store.api.v1.State;

public class UserProfile implements State {
    private String name;
    private String email;

    public UserProfile(String name, String email) {
        this.name = name;
        this.email = email;
    }

    // getters and setters...

    @Override
    public UserProfile clone() {
        try {
            return (UserProfile) super.clone();
        } catch (CloneNotSupportedException e) {
            throw new RuntimeException(e);
        }
    }
}
```

Why `clone()` matters: the reducer receives a *copy* of the state, mutates it, and returns it. The store diffs the result against the previous state (using reflection-based diffing) and only commits + notifies subscribers if something actually changed. A broken clone either makes every dispatch appear unchanged or corrupts the snapshot history.

### Actions

An `Action<T>` is an immutable `{ type, payload }` pair. The `type` is a string naming the event; the `payload` carries the data the reducer needs. You rarely construct actions by hand with a Slice — `slice.getAction(type)` returns a `Consumer` that builds the action for you. When you need one directly, use the factory:

```java
import org.flux.store.api.v1.Action;
import org.flux.store.utils.Utilities;

Action<String> action = Utilities.actionCreator("setName", "Karan Gupta");
```

### Reducers

A reducer is a pure function: `(action, state) -> state`. Based on the action's type, it updates the relevant fields on the (cloned) state and returns it. Reducers **must return the state** — forgetting the `return` leaves the store holding null.

```java
import org.flux.store.api.v1.Reducer;

Reducer<UserProfile> setNameReducer = (action, state) -> {
    state.setName(action.getPayload().toString());
    return state;
};
```

The payload is accessed via `action.getPayload().toString()` — the `Reducer` interface takes a raw `Action`, so cast or serialize as appropriate for your payload type.

### Dispatching via a Slice

Both builders produce a `Slice<T>`, which exposes:

- `T getState()` — current state (synchronized access).
- `Consumer getAction(String type)` — returns an action dispatcher. Calling `.accept(payload)` builds and dispatches the action.
- `void goBack()` / `void goForward()` — time-travel (undo/redo) over recorded state changes.

The Slice is type-safe: requesting an action type that has no reducer registered throws `InvalidActionException`. This catches typos at call time rather than silently doing nothing.

```java
Consumer setName = slice.getAction("setName");
setName.accept("Manoj Gupta");          // dispatches a setName action

slice.getAction("updateEmail");        // throws InvalidActionException — no such reducer
```

### Subscribers

A subscriber is a `Consumer<T>` — it receives the new state whenever a dispatch actually changes state. Subscribers are invoked **asynchronously** (via `CompletableFuture`), so they are fire-and-forget: one subscriber throwing will not disrupt the store or other subscribers. Don't rely on them for synchronous validation — use middleware for that.

### Middleware

Middleware intercepts actions before they reach the reducer. The signature is:

```java
void run(Store<T> store, Consumer<Action> next, Action action)
```

A middleware can inspect, log, transform, or replace the action, then call `next.accept(action)` to continue — or omit the call to short-circuit (reject the action entirely). **Footgun: every code path that should let the action through must call `next.accept(...)`**, otherwise the action silently never reaches the store.

The Slice builders accept a single middleware via `setMiddleware(...)`. To chain several, compose them with `Utilities.compose(...)` — it threads the action through each middleware in sequence, letting each stage mutate it before the last calls the real dispatcher.

```java
import org.flux.store.api.v2.Middleware;
import org.flux.store.utils.Utilities;

Middleware<UserProfile> loggingMiddleware = (store, next, action) -> {
    System.out.println("Dispatching: " + action.getType());
    next.accept(action);
};

Middleware<UserProfile> transformMiddleware = (store, next, action) -> {
    if ("Tom Marvolo Riddle".equals(action.getPayload().toString())) {
        next.accept(Utilities.actionCreator(action.getType(), "Lord Voldemort"));
    } else {
        next.accept(action);
    }
};

Middleware<UserProfile> pipeline = Utilities.compose(loggingMiddleware, transformMiddleware);
```

---

## Approach 1 — Dux Slice API (explicit wiring)

Best for per-client / per-session state where you want full control over which reducers handle which action types. This is the recommended default.

Use `DuxSliceBuilder` to assemble the slice. Each reducer is registered with `addReducer(actionType, reducer)`. Action-type matching is **case-insensitive**.

```java
import org.flux.store.api.v2.Slice;
import org.flux.store.main.v2.DuxSliceBuilder;

Slice<UserProfile> slice = new DuxSliceBuilder<UserProfile>()
        .setInitialState(new UserProfile("Karan Gupta", "karan@hello.com"))
        .addReducer("setEmail", (action, state) -> {
            state.setEmail(action.getPayload().toString());
            return state;
        })
        .addReducer("setName", (action, state) -> {
            state.setName(action.getPayload().toString());
            return state;
        })
        .setMiddleware(pipeline)                              // optional
        .addSubscriber(state -> System.out.println(state))    // optional, repeatable
        .build();
```

`DuxSliceBuilder` methods:

| Method | Purpose |
| --- | --- |
| `setInitialState(T)` | Seed state (required). |
| `addReducer(String type, Reducer<T>)` | Register a reducer for an action type. Call once per action type. |
| `setMiddleware(Middleware<T>)` | Single middleware (optional). Compose multiple with `Utilities.compose`. |
| `addSubscriber(Consumer<T>)` | Add a subscriber (optional, repeatable). |
| `build()` | Returns the assembled `Slice<T>`. |

Then dispatch and read state:

```java
Consumer setEmail = slice.getAction("setEmail");
setEmail.accept("manoj@hello.com");
System.out.println(slice.getState().getEmail());  // manoj@hello.com
```

## Approach 2 — Auto Reflection API (classpath-scanned reducers)

Best for application-wide / global state where reducers are organized as standalone classes and you want to avoid hand-wiring a big builder. Inspired by Spring's component scanning.

Instead of `addReducer`, you place each reducer in its own class that:

1. Implements `ReducerBlock<T>` — which extends `Reducer<T>` and adds `String getType()` (the action type it handles).
2. Is annotated with `@AutoStore` (a marker annotation).
3. Has a public no-arg constructor (the builder instantiates it via reflection).

```java
import org.flux.store.api.v1.Action;
import org.flux.store.api.v3.AutoStore;
import org.flux.store.api.v3.ReducerBlock;

@AutoStore
public class SetNameReducer implements ReducerBlock<UserProfile> {
    @Override
    public String getType() { return "setName"; }

    @Override
    public UserProfile reduce(Action action, UserProfile state) {
        state.setName(action.getPayload().toString());
        return state;
    }
}

@AutoStore
public class SetEmailReducer implements ReducerBlock<UserProfile> {
    @Override
    public String getType() { return "setEmail"; }

    @Override
    public UserProfile reduce(Action action, UserProfile state) {
        state.setEmail(action.getPayload().toString());
        return state;
    }
}
```

Then build with `ReflectionDuxSliceBuilder`, pointing it at the package to scan:

```java
import org.flux.store.main.v3.ReflectionDuxSliceBuilder;

Slice<UserProfile> slice = new ReflectionDuxSliceBuilder<UserProfile>()
        .setInitialState(new UserProfile("Karan Gupta", "karan@hello.com"))
        .setBasePackage("com.myapp.reducers")
        .setMiddleware(pipeline)                              // optional
        .addSubscriber(state -> System.out.println(state))    // optional
        .build();
```

`ReflectionDuxSliceBuilder` methods:

| Method | Purpose |
| --- | --- |
| `setInitialState(T)` | Seed state (required). |
| `setBasePackage(String)` | Root package to scan for `@AutoStore` `ReducerBlock`s (required). |
| `setMiddleware(Middleware<T>)` | Single middleware (optional). Compose multiple with `Utilities.compose`. |
| `addSubscriber(Consumer<T>)` | Add a subscriber (optional, repeatable). |
| `build()` | Discovers reducers via reflection, then assembles the same `Slice<T>` as the v2 builder. |

Dispatching and reading state is identical to Approach 1 — both builders produce the same `Slice<T>`:

```java
Consumer setName = slice.getAction("setName");
setName.accept("Manoj Gupta");
```

### Reflection gotchas

- **Collision on duplicate types.** Reducers are keyed by `getType()` into a map. Two `ReducerBlock`s returning the same type string in the scanned package collide — one silently wins (scan order is undefined). Give each a distinct `getType()`, or scope `setBasePackage` to a narrower package containing only the reducers you want.
- **No-arg constructor required.** The builder calls `clazz.getDeclaredConstructor().newInstance()`. A reducer with constructor parameters throws a `RuntimeException` at build time.
- **`@AutoStore` is a bare marker.** Despite some docs showing `@AutoStore("MyStore")`, the annotation takes no arguments in the current codebase — there is no multi-store / named-store support yet. All discovered reducers go into one store.
- **Scan cost.** Reflection scans the classpath, so keep the base package as narrow as possible for faster builds and to avoid accidental collisions.

---

## Choosing between the two

- **Per-user / per-session state** → Dux Slice API (Approach 1). Each client gets its own `Slice` instance with exactly the reducers it needs.
- **Application-global state** → Auto Reflection API (Approach 2). Reducers are decoupled classes; the store assembles itself from the classpath.

Both share the same downstream behavior: middleware, async subscribers, time-travel (`goBack()` / `goForward()`), and the type-safe `getAction` dispatch.
