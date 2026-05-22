# AI Translation Engine

AI-driven localization for WooCommerce iOS. Translates English strings in
`WooCommerce/Resources/en.lproj/*.strings` into all supported locales using
the Anthropic Claude API.

The 15 locales currently shipping AI translations were bootstrapped using
this engine (see [PR #17220](https://github.com/woocommerce/woocommerce-ios/pull/17220)).
Going forward, this engine runs incrementally on every PR that touches the
English source.

## Quick start

```bash
# Bootstrap a brand-new locale (all 5141 keys)
ANTHROPIC_API_KEY=sk-... bundle exec rake -f fastlane/ai_translation/Rakefile \
  translate:bootstrap LOCALE=hi

# Translate only what's missing in an existing locale (PR-time, fast)
ANTHROPIC_API_KEY=sk-... bundle exec rake -f fastlane/ai_translation/Rakefile \
  translate:incremental LOCALE=hi

# Verify key parity vs en.lproj (no API calls)
bundle exec rake -f fastlane/ai_translation/Rakefile translate:verify LOCALE=hi

# Print a Markdown health report for all locales
bundle exec rake -f fastlane/ai_translation/Rakefile translate:report > report.md
```

`LOCALE=` defaults to every locale in `SUPPORTED_LOCALES` (currently the 15
new ones); set it to scope a run.

## Environment

| Variable | Required | Purpose |
|----------|----------|---------|
| `ANTHROPIC_API_KEY` | yes (unless `OFFLINE=1`) | The Anthropic API key. Already provisioned as a Buildkite secret with this name. |
| `WOO_AI_TRANSLATION_BASE_URL` | no | Override the Anthropic base URL (e.g. for the Automattic AI gateway). |
| `MODEL` | no | Override the model (default `claude-haiku-4-5`). |
| `LIMIT` | no | Translate only the first N keys (smoke testing). |
| `OFFLINE=1` | no | Use the deterministic `StubClient` — no API calls, predictable output. Useful for testing the pipeline without spend. |

## Architecture

```
fastlane/ai_translation/
├── bin/
│   └── translate_locale.rb       # CLI entry point
├── lib/woo_ai_translation/
│   ├── anthropic_client.rb       # Anthropic Messages API wrapper (+ StubClient)
│   ├── byte_sizer.rb             # Script-aware batch sizing
│   ├── constants.rb              # Version, model IDs, prompt version
│   ├── ios_resources.rb          # .strings parser + writer
│   └── translator.rb             # Batched JSON-in/JSON-out translator with split-retry
├── spec/                         # Minitest specs
├── scripts/                      # One-off bootstrap utilities (assemble, gap-fill)
├── Rakefile                      # Rake task wrappers
└── translate-progress.json       # Audit checkpoint for the original bootstrap run
```

### Why a separate `byte_sizer`

Each backend has an output-token cap. Non-Latin scripts (Devanagari, Thai,
Cyrillic, CJK) cost 2–3 bytes per character in UTF-8 versus 1 byte for
Latin. A 1500-entry batch that's fine in French overflows the cap in Hindi.

`ByteSizer.recommended_batch_size(locale:)` returns a safe batch count
given the configured `max_output_tokens` (default 8192). Callers can
override with `--batch N` for experiments.

The bootstrap of the 15 initial locales used 500-key sub-batches for
non-Latin scripts; the auto-sizer codifies that lesson so future runs
don't repeat the trial-and-error.

### Translation pipeline

1. **Parse** the source `.strings` file → list of translatable units (key,
   source, comment).
2. **Batch** into chunks (`ByteSizer`-sized by default).
3. For each batch, call the **client** with: system rules + per-locale
   style hint + JSON payload of `{id, source, context}`.
4. **Validate** the JSON response covers every requested id; on parse or
   coverage failure, split the batch in half and retry. A single-key
   failure is logged and left untranslated.
5. **Placeholder check**: count `%@`, `%1$@`, `%d`, etc. in source vs
   translation. Mismatches are flagged as `placeholder_errors` and the
   translation is rejected.
6. **Write** the assembled `.strings` file with header + unit comments.

### `--incremental` mode

`bin/translate_locale.rb --incremental` (and `rake translate:incremental`)
loads the existing target locale file, identifies the keys that are:

- missing entirely, or
- present but with an empty value, or
- present but with the English source as the value (placeholder),

then translates only those. Existing translations are preserved verbatim.

This is what the CI step calls on every PR that touches `en.lproj`. A typical
PR adds 1–10 strings, so the incremental call costs cents and finishes in
seconds.

## Adding a new locale

1. Add the locale code to `SUPPORTED_LOCALES` in `Rakefile`.
2. Add the locale display name to `LOCALE_NAMES` in `bin/translate_locale.rb`.
3. Add the locale to `knownRegions` in `WooCommerce/WooCommerce.xcodeproj/project.pbxproj`.
4. Run the bootstrap:

   ```bash
   ANTHROPIC_API_KEY=sk-... bundle exec rake \
     -f fastlane/ai_translation/Rakefile \
     translate:bootstrap LOCALE=<new-code>
   ```

5. Manually write `WooCommerce/Resources/<new-code>.lproj/InfoPlist.strings`
   (only 11 keys; not yet auto-translated by this engine — see TODO below).
6. Open a PR. The diff will be large (~5141 new entries); apply whatever
   size-override label your Danger config uses.

## Removing a locale

Delete the `<code>.lproj` directory, remove the entry from `knownRegions`,
and remove from `SUPPORTED_LOCALES` and `LOCALE_NAMES`.

## Known limitations / TODOs

These are tracked for follow-up PRs:

- **Parser is O(n²)** on 1 MB+ files. `IosResources::Parser.parse_file` can
  take ~150 s on the full 5141-key Polish file. `--incremental` is unaffected
  (small slices). For `translate:verify` over all locales this manifests as
  multi-minute waits. Replace the char-by-char scanner with `StringScanner`.
- **No manifest cache**. Each run re-translates the full payload; resuming
  a partial run isn't supported. Manifests would also enable content-hash
  detection of which source keys changed.
- **No glossary validator yet**. Brand-name and terminology rules are
  inlined in the system prompt. PR 3 will add `glossary/<locale>.yml` files
  and a hard validator.
- **InfoPlist.strings is not auto-translated**. The 11 entries are easy
  enough to hand-write per locale during bootstrap. A small extension to
  the bootstrap task could cover it.
- **No sub-agent backend**. Without an API key, the current path is to
  delegate via Claude Code chat sub-agents (slow and rate-limited). A
  `SubAgentClient` adapter could automate this, but the API path is
  strictly better; not building it for now.

## Test the engine offline

```bash
cd fastlane/ai_translation
ruby spec/ios_resources_test.rb    # parser/writer round-trip (28 tests)
ruby spec/byte_sizer_test.rb       # batch sizing (9 tests)

# Smoke test the CLI with the deterministic stub client
OFFLINE=1 LIMIT=5 bundle exec rake -f Rakefile translate:bootstrap LOCALE=hi
```
