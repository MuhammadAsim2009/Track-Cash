# Design

## Principles
Clean, calm, minimal. One main action per screen. Big numbers, little clutter. Adding an expense takes 3 taps or fewer.

## Theme
Light and dark, user-switchable, saved locally. Material 3 with a custom green color scheme.

### Colors
| Role | Light | Dark |
|---|---|---|
| Primary | #059669 | #34D399 |
| Background | #F8FAFC | #0F172A |
| Surface / cards | #FFFFFF | #1E293B |
| Text primary | #0F172A | #F1F5F9 |
| Text secondary | #64748B | #94A3B8 |
| Income | #16A34A | #4ADE80 |
| Expense | #DC2626 | #F87171 |
| Warning (budget 80%) | #D97706 | #FBBF24 |
| Border | #E2E8F0 | #334155 |

## Typography
- Font: **Poppins** (headings, numbers) and **Inter** (body) via `google_fonts`.
- Balance / big numbers: Poppins SemiBold 32.
- Screen titles: Poppins SemiBold 20.
- Body: Inter Regular 14–16.
- Captions/labels: Inter Medium 12.

## Layout
- 8px spacing grid; screen padding 16px.
- Cards: 16px radius, soft shadow (light) / subtle border (dark).
- Custom floating notched bottom bar: `Home | Transactions | (+) | Budget | Udhaar`. "More" in the app bar menu.
- Bar dimensions & shape: horizontal margin 16px, bottom margin 12px + safe area, corner radius 28px, smooth cubic curved notch in top center.
- Screen bottom padding: centralized 100px + safe area padding wrapper (`TabScreenWrapper`) on all tab screens to prevent list items being obscured by the floating bar.

## Components
- Floating Notched Navigation Bar:
  - 4 tabs (Home, Transactions, Budget, Udhaar) with animated selection (200ms).
  - Active tab uses primary color for icon and label; inactive tabs use secondary text color.
  - Center 56px circular green `+` button in notch, slightly raised, triggers Add Transaction (Expense by default with Income toggle).
  - Light mode: white surface with soft shadow (`#000000` 10% opacity, blur 12, y: 4).
  - Dark mode: `#1E293B` surface with 1px `#334155` border (no shadow).
- Wallet card: icon, name, balance.
- Transaction tile: category icon, note, wallet, amount (green income / red expense).
- Budget progress bar: green → amber at 80% → red when exceeded.
- Udhaar tile: person, amount, due date chip (overdue = red).
- Currency format: `Rs 12,500`.

## States
Every list has an empty state (icon + one-line hint), a loading state, and an error state with retry.
