#  Plan

Review git diff and context.md. After so many iterations, I came to the conclusion of what I want to do.

Example behavior I'm seeking:

### Example

If plannedRunDate is nil:
For work that are of type .both, plannedRunDate is set to Date() +
period whenever the app is launched (both foreground or background)

For work that are of type .background, plannedRunDate is set to Date() +
 period whenever the app goes to background.

------
This setting, is independent of actual scheduling logic. It's only to
set the baseline.

So, let's A is .background, and B is .both  type. App launched.

B plannedRunDate is set to 55 min

startForegroundScheduling()

B, planneduRunDate is set to min(plannedRunDate, Date() + Period) = 55
min

15 min passes

app goes into background

A plannedRunDate is nil, it's set to Date() + period = 30min
B plannedRunDate is not nil, it's not changed, so the date is in 55min -
 15min = 40min

startBackgroundScheduling()

compare plannedRunDate. A is 30, B is 40min, so A is picked.

Schedule A in 30min background task.

15 more minutes passes
App goes into foreground

A plannedRunDate is not nil, it's already set to 30-15 = in 15min
B plannedRunDate is not nil, it's already set to 40-15min = 25min

Start foreground timer.
Only B is foreground task

Start timer in 25min.. and so on.

If we encounter negative plannedRunDate, we execute the task immediately
 and set it to Date() + period. When we complete a task, we immediately
set the task plannedRunDate to Date() + period.

## How we achieve it

### Overall architecture

- SyncScheduler: Central piece, similar to what we have with BackgroundWorkScheduler, it keeps registeredWork, plannedRunDates, and keeps lifecycleObservers
- BackgroundTaskRefreshDispatcher: similar to what we had before, it's responsible for working with BGTaskScheduler.
- ForegroundSyncDispatcher: keeps foregroundTimers, allows syncScheduler to schedule work, then it executes work, and tells

1. Return `BackgroundTaskRefreshDispatcher` 
2. 
