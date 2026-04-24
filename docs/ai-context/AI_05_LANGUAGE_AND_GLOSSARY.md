# AI_05 — Language and Glossary

This is the **canonical glossary** for Cap & Gown. Other docs reference this file rather than redefining terms.

---

## Terms

| Term | Definition |
|------|-----------|
| **BUID** | Belmont University ID. String identifier (e.g., `B00610448`). Primary key for `Graduate`. |
| **Graduate** | A degree candidate eligible to receive cap & gown regalia. |
| **Brag** | An optional recognition card associated with a graduate. A graduate may have multiple brags. |
| **Cord** | An honor cord a graduate is entitled to wear. Typed by `cord_type`. A graduate may have multiple cords. |
| **Hood color** | Color of the academic hood, derived from degree. Translated via `lib/degree_hood_translator.rb`. |
| **College code** | Short code for the academic college (e.g., `MB`). Translated via `lib/college_code_translator.rb`. |
| **Level code** | Degree level. `UG` = undergraduate, `GR-M` = master's, `GR-D` = doctorate. |
| **Print queue** / **to-print list** | Graduates with `checked_in IS NOT NULL AND printed IS NULL`. |
| **Bulk print** | Multi-graduate print or clear-print action driven by a comma-separated `buids` list. |
| **Check-in** | The act of confirming a graduate is present at distribution. Sets `checked_in = Time.now`. |
| **Clear** | Undo a state flag. `?checkin=clear` or `?print=clear` sets the flag back to `nil`. |

## Voice & Tone

See [`docs/development/LANGUAGE_STYLE_GUIDE.md`](../development/LANGUAGE_STYLE_GUIDE.md) for voice, tone, and copy decisions.

## Avoid

- "Student" in UI copy → use **graduate** (this app is about distribution day, not student records).
- "ID" alone → use **BUID** when referring to the identifier.
- "Receipt" or "ticket" for the printed sticker → use **sticker** or **label**.
