# 🛡️ Inflinix

**A load-bearing credit memory for AI agents that lend to each other.**

Inflinix turns [Accred](https://accred.sh) into a dynamic credit engine
for onchain agent fleets. Agents that can remember a counterparty's track record
across sessions can extend *uncollateralized* credit; agents that forget must
demand 150%+ collateral from everyone, every time. Meritor is that memory.

> Built for the Accred Hackathon (oct 2026). Apache-2.0.

---

## The one-sentence version

Recall a counterparty's repayment history → change its collateral tier → change
a real USDg disbursement on robinhood. Delete the memory and the exact same agent,
making the exact same request, is refused.

## Why this is load-bearing, not decorative

The credit score is a **pure function of recalled memory**. There is no cache in
front of the logic that memory merely accelerates - the memory *is* the input.
Concretely:

- **Fail-closed by construction.** The `MemoryBackend` contract has no graceful
  degradation path. An unreachable substrate raises `MemoryUnavailable`, which
  propagates to the decision boundary and becomes an explicit 0-trust rejection.
  It is never caught-and-defaulted to an empty profile, because an empty profile
  reads as "new counterparty, clean record" - which would let an outage silently
  approve credit.
- **The deletion test.** `inflinix wipe --yes` erases the Accred namespace.
  After it, every credit decision collapses to `UNKNOWN` / 150% / denied. Nothing
  else in the system changes.

## The fresh-session beat

Every step below is a **separate process**. Nothing survives in RAM between them.
`INFLINIX_SESSION_ID` marks the logical session boundary.

| Step | Process | Result |
|---|---|---|
| Seed 0xALPHA's prior history | - | 3 sessions of clean settlement, backdated |
| 0xBETA (never seen) requests $50 | session A | **DENIED**, 150% collateral, `memory-backed: False` |
| 0xALPHA requests the same $50 | session A | **APPROVED**, **0% collateral**, PLATINUM |
| 0xBETA works + repays | session A | one clean event written |
| 0xBETA returns | **session B, fresh process** | **APPROVED**, 120% - the record changed the decision |
| Time-travel 0xALPHA | session B | GOLD as of 10 days ago, PLATINUM today |
| `wipe --yes` | - | Sibyl Memory erased |
| 0xALPHA repeats the request | **session C, fresh process** | **DENIED** - memory was the only variable |

Run it:

```bash
./demo/fresh_session_demo.sh
```

## The four memory primitives (and two more on Pro)

Meritor uses Sibyl Memory as more than a key-value store, because the 40%
criterion rewards coordination and dynamic-storage patterns over plain recall.

| Primitive | Sibyl surface | What it carries |
|---|---|---|
| **entities** | `set_entity` / `get_entity` | the counterparty profile; tier mirrored into `status` for portfolio sweeps by risk band |
| **events** | `write_event` / `read_events` | the append-only credit journal - what makes the score reconstructible, not just current |
| **state** | `set_state` / `get_state` | the collateral policy in force, and live exposure |
| **search** | `search_entities` (FTS5) | "which counterparties have a dispute on record" without a table scan |
| **temporal** | journal replay | `profile_as_of(agent, instant)` rebuilds the score at any past moment |
| **reflection** | journal → `set_reference` | a consolidation pass over the journal that caps a deteriorating agent's tier in future sessions (hand-rolled; free-tier) |

> Reflection is hand-rolled rather than using Sibyl's native `learn()` on
> purpose: `learn()` is gated to paid tier strings the hackathon Pro grant does
> not set (`_PAID_ONLY_TIERS` in the SDK has no `"pro"`), so it would raise for
> us and for a judge re-running the demo. Our pass uses only journal reads and
> reference writes, which every tier has.

## Web frontend

A landing page and an interactive **credit desk**, served locally and backed by
the *mockup* engine -

```bash
pip install -r requirements.txt          # includes fastapi + uvicorn
python -m uvicorn web.server:app --port 8848
open http://127.0.0.1:8848               # landing page; the desk is at /desk
```

The API is live against the engine: `GET /api/agents`, `POST /api/decision`,
and `POST /api/memory/wipe` | `/restore` (the deletion test over HTTP).

## Tests

```bash
pip install pytest && python -m pytest -q
```

The suite locks the invariants that make memory load-bearing: no uncollateralized
credit without recalled memory, a memory outage is never mistaken for a clean
slate, and a single good session cannot reach the 0-collateral tier.

## Prior Work declaration

This repository was built for the accred Hackathon during the 48 hours build
window.

## License

[Apache-2.0](LICENSE).
