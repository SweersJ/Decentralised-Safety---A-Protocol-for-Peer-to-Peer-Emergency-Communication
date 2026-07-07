# Counterexample Trace Matrices — `fair_receive_message`

TLC found a lasso counterexample (States 1–11, then stuttering) for the liveness property:

```
fair_receive_message.implies(eventually_all_received)
```

---

## `nextMsgId` progression

| State | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
|-------|---|---|---|---|---|---|---|---|---|----|----|
| `nextMsgId` | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |

---

## `messageState` — pending messages per (sender → receiver) channel

Each cell shows the set of message IDs queued in that channel.

| Channel (sender → receiver) | S1 | S2 | S3 | S4 | S5 | S6 | S7 | S8 | S9 | S10 | S11 |
|-----------------------------|----|----|----|----|----|----|----|----|-----|-----|-----|
| **A → A** | {} | {} | {} | {} | {} | {} | {} | {} | {} | {} | {} |
| **A → B** | {} | {} | {1} | {1,2} | {1,2} | {1,2} | {1,2} | {1,2,6} | {1,2,6} | {1,2,6,8} | {1,2,6,8} |
| **B → A** | {} | {0} | {0} | {0} | {0,3} | {0,3,4} | {0,3,4,5} | {0,3,4,5} | {0,3,4,5,7} | {0,3,4,5,7} | {0,3,4,5,7,9} |
| **B → B** | {} | {} | {} | {} | {} | {} | {} | {} | {} | {} | {} |

### Step-by-step action log

| Transition | Action | New message ID |
|------------|--------|----------------|
| S1 → S2 | B sends to A | 0 |
| S2 → S3 | A sends to B | 1 |
| S3 → S4 | A sends to B | 2 |
| S4 → S5 | B sends to A | 3 |
| S5 → S6 | B sends to A | 4 |
| S6 → S7 | B sends to A | 5 |
| S7 → S8 | A sends to B | 6 |
| S8 → S9 | B sends to A | 7 |
| S9 → S10 | A sends to B | 8 |
| S10 → S11 | B sends to A | 9 |
| S11 → S12 | Stuttering | — |

---

## `ackPayload` — acknowledgement payloads

Always empty throughout the entire trace:

| Channel (receiver → sender) | All States |
|-----------------------------|-----------|
| **A → A** | {} |
| **A → B** | {} |
| **B → A** | {} |
| **B → B** | {} |

---

## `received` — messages delivered to each node

Always empty throughout the entire trace:

| Node | All States |
|------|-----------|
| **A** | {} |
| **B** | {} |

---

## Observation

The counterexample shows that only `sendMessage` actions fire. Although `fair_receive_message` requires `receiveMessage` to be weakly fair (i.e., it must eventually fire when continuously enabled), the system never takes a `receiveMessage` step before stuttering. Both channels accumulate messages indefinitely while `received` stays empty, violating the liveness guarantee.
