# Default style guide

Fallback when no per-locale style guide is provided.

**Tone:** Concise, friendly, action-oriented. Match the tone of modern mobile commerce apps.

**Register:** Use whichever 2nd-person register is conventional for the target locale's mobile-app ecosystem. Avoid formal honorifics unless required (e.g., legal disclaimers).

**Numerals:** Arabic digits (1, 2, 3). Do not localize to script-specific numeral systems (e.g., Devanagari १२३, Thai ๑๒๓) — the app's number formatting expects Arabic input.

**Brands:** Keep all brand names verbatim — see `glossary/common.yml`.

**Placeholders:** Preserve every `%@`, `%1$@`, `%d`, `%.0f`, `\n`, `\t`, etc. exactly. Never reorder positional placeholders.

**Markup:** Preserve HTML tags (`<b>`, `<a href="...">`, `</a>`) and their attributes. Translate only the visible text inside them.

**Length:** Aim for translations close to the source length. Mobile UI has limited space.
