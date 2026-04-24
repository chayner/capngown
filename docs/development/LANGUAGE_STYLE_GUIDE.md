# Language Style Guide

Voice, tone, and word choices for Cap & Gown.

---

## Voice

- **Warm and celebratory.** Graduation is a milestone. The UI should feel like a celebration, not a DMV.
- **Plain.** Volunteers may be using the app for the first time on distribution day. No jargon.
- **Confident.** Short sentences. Active voice. "Check in" not "Please proceed to check in."

## Tone by Context

| Context | Tone |
|---------|------|
| Successful check-in | Warm, congratulatory ("Welcome, {firstname}!") |
| Print confirmation | Concise ("Sticker printed.") |
| Errors | Calm, helpful, no blame ("We couldn't find a graduate with that BUID. Try a name search?") |
| Empty states | Friendly, instructive ("No one's in the print queue yet. Start by checking someone in.") |

## Word Choices

| Use | Don't Use | Why |
|-----|-----------|-----|
| **Graduate** | Student | This app is about distribution day; "graduate" honors the moment |
| **BUID** | ID, student ID | BUID is the canonical Belmont term |
| **Sticker** / **label** | Receipt, ticket | What's actually printed |
| **Check in** (verb), **check-in** (noun) | Sign in, register | Matches the action |
| **Print queue** | Print list, queue | Matches the URL/route name |
| **Bulk print** | Mass print, batch print | Matches the action |
| **Brag** | Brag card | Per Belmont's existing terminology |
| **Cord** | Cord card, honor cord (in copy use just "cord") | Matches the model |

## Capitalization

- **Sentence case** for buttons, headings, and form labels: "Check in", "Print queue", "Stats".
- **Title Case** only for proper nouns: "Belmont Cap & Gown", "Massey College of Business".

## Punctuation

- No exclamation points except in genuine celebration moments (successful check-in).
- Oxford comma. Always.
- No emoji in production UI. (Internal tooling/admin can use sparingly if it adds clarity.)

## Numbers

- Spell out one through nine in body copy. Use numerals in stats / data displays.
- Percentages: one decimal place (`87.3%`).

## Errors

Format: **What happened. What to do.**

- ✅ "We couldn't find that BUID. Try searching by name."
- ❌ "Error: Graduate not found."

## Empty States

Format: **What's empty. How to fill it.**

- ✅ "No one's in the print queue. Check a graduate in to get started."
- ❌ "No records."
