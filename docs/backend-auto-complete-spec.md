# Backend-driven task auto-complete — spec for `fieldguard-be`

## Why

Today the **app** completes a task when the agent leaves the shop geofence:
on exit it sends `PATCH /api/v1/tasks/:id { status: "COMPLETED" }`. The visit
record itself is uploaded separately and reliably (retry queue), but the
completion PATCH depends on the app being alive/online. We added an
offline-retry for it, but it's still app-dependent: if the app is
uninstalled, logged out, or the PATCH permanently fails, the task can stay
`IN_PROGRESS` forever.

**Move the completion decision to the backend.** The backend already receives
every visit via `POST /api/v1/geofence-visits`. When a *valid* visit arrives
for a task that is `IN_PROGRESS`, the server should complete the task itself.
The app's only job becomes "upload the visit" — which is already kill-proof.

## Change: `POST /api/v1/geofence-visits`

When a visit is stored (first write — not an idempotent duplicate retry),
evaluate auto-completion:

```
on POST /geofence-visits (visit):
  store visit (dedupe on visit.visitId — unchanged)

  task = tasks.find(visit.taskId)
  if task == null: return 201        # visit kept, nothing to complete

  # Guard rails — only auto-complete a genuine, current visit:
  if task.status != 'IN_PROGRESS':   return 201   # already done/cancelled
  if task.shop_id != null
     and visit.shopId != null
     and task.shop_id != visit.shopId: return 201  # visit at a different shop
  if visit.stayDurationSeconds < 45: return 201    # drive-by (matches app's min-stay)

  # Complete it:
  task.status        = 'COMPLETED'
  task.completed_at   = visit.exitedAt
  task.remarks        = task.remarks ?? 'Auto-completed on geofence exit'
  save(task)
  # (optionally) emit the same socket/notification you already use for task updates
  return 201 with { visit, task }    # see response below
```

### Response shape (important for the app)

Return the **updated task** alongside the stored visit so the app can refresh
its UI immediately instead of polling:

```json
{
  "visit": { ...stored visit... },
  "task":  { ...full task object, same shape as GET /tasks/:id... }
}
```

If `task` is present and `status == "COMPLETED"`, the app drops its own
PATCH and just refreshes from this object.

### Request body the app already sends (camelCase)

```json
{
  "visitId": "uuid",            // idempotency key — dedupe on this
  "taskId": 27,
  "shopId": 14,                 // omitted when null; backfill from task.shop_id
  "enteredAt": "2026-05-25T12:40:45.778Z",
  "exitedAt":  "2026-05-25T12:42:12.365Z",
  "stayDurationSeconds": 86,
  "exitEstimated": false,       // true => exit was estimated (app-kill / perm loss)
  "enterLatitude": 27.6757, "enterLongitude": 85.4042,
  "exitLatitude": 27.6753,  "exitLongitude": 85.4041
}
```

## Edge cases the backend must handle

- **Idempotency:** the app retries the same `visitId` until it gets a 2xx.
  Dedupe on `visitId`; a duplicate must NOT re-complete or error — return the
  same `{ visit, task }`. (App already treats any 2xx as success.)
- **`exitEstimated: true`:** still auto-complete (the agent did visit; exit
  time is just an estimate). If you want stricter behaviour, you *may* skip
  auto-complete for estimated exits and require a real one — but the app's
  current min-stay logic already filtered drive-bys, so completing is safe.
- **Task already COMPLETED/CANCELLED:** never flip it back; keep the visit.
- **shopId mismatch:** keep the visit (it's still a real visit record) but do
  NOT complete the task — the agent visited a different shop.
- **Multiple visits for one task:** only the first transition to COMPLETED
  matters; later visits just store.

## App-side follow-up (handled in the Flutter repo)

Once the backend completes on visit upload:

- The app keeps showing the instant "Task completed" notification on exit
  (good UX), but can stop owning the PATCH. Two options:
  1. **Belt-and-braces (recommended first):** keep the app PATCH as-is; the
     backend completing first just makes the app's PATCH a harmless no-op
     (task already COMPLETED → backend returns 200, app refreshes). The
     offline-retry then becomes a rarely-needed fallback.
  2. **Backend-authoritative:** remove the app PATCH entirely; rely on the
     `POST /geofence-visits` response carrying the completed task, plus a
     refresh. Simpler app, but the app must refresh its task list when a
     queued visit finally uploads (we already have the `onVisitUploaded`
     hook for exactly this).

Recommend shipping option 1 with the backend change, then moving to option 2
once the backend behaviour is confirmed in production.
