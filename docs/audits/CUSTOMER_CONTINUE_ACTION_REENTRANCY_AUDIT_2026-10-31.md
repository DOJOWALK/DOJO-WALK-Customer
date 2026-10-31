# Customer Continue Action Re-entrancy Audit — 2026-10-31

## Scope
Static review of `lib/features/booking/screens/choose_walk_screen.dart` on branch `chore/remove-app-language-file`, commit `a9b4c49d0118f1ef44f4345d132ec485f712290c`.

No Firebase, Backend, API, or other repository was accessed or changed.

## Finding: Continue action relies on widget disable state only

The Continue button is rendered with:

```dart
onPressed: _isContinuing ? null : _continueToDogSelection
```

The handler `_continueToDogSelection()` does not independently return when `_isContinuing` is already true. It performs validation and asynchronous work before eventually setting `_isContinuing = true`.

A second callback invocation before the disabled-button rebuild is applied can therefore enter the handler concurrently. That can duplicate profile reads and potentially start more than one navigation attempt. The button state is a useful UI guard, but it is not a complete handler-level re-entrancy guard.

## Recommended Customer-only correction

At the very beginning of `_continueToDogSelection()`, add:

```dart
if (_isContinuing) return;
```

Keep the existing disabled button and `finally` reset. Add a widget test that triggers two Continue taps while login/profile navigation is pending and asserts only one navigation attempt occurs.

## Verification status

- Static code inspection: completed.
- Runtime reproduction: not run.
- Automated regression test: not added.
- Code fix: not applied in this audit.
- Backend/Firebase: untouched.

## Related CI for inspected source commit

Commit: `a9b4c49d0118f1ef44f4345d132ec485f712290c`

- Customer UI Validation: SUCCESS — run 41183506220.
- Customer Web Build Validation: SUCCESS — run 41183506236.
- Customer Android Validation: SUCCESS — run 41183506309.

These CI results validate the commit as built; they do not prove the re-entrancy scenario is covered.
