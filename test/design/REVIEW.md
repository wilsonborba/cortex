# Redesign review

Review date: 2026-11-12. Scope: issues #49 to #58.

The independent reviewer inspected representative rendered images in both themes,
including narrow and wide layouts, Thai and Brazilian Portuguese, long transcript
content, long memory content and all Engineering widths. The reviewer did not
write the implementation. No remaining visual defect was found in those images.
This is representative review, not a claim that every PNG was inspected.

| Screen | Visual review |
| --- | --- |
| Shell and account menu | PASS |
| Settings | PASS |
| Transcript: empty, finished and long | PASS |
| Transcript: running, thinking and error | PASS |
| Composer: empty, text, files, running and over limit | PASS |
| Memory canvas and short/long card | PASS |
| Memory list and stack | PASS |
| Public Memory example | PASS |
| Personas list: data, empty and no match | PASS |
| Personas form: new, edit and errors | PASS |
| Engineering | PASS |

## Review list

| Check | Result |
| --- | --- |
| No gradient, glow or colored shadow | PASS |
| No card around every content block | PASS |
| One primary action in a work view | PASS |
| Accent only on the primary action and selected markers | PASS |
| Consistent Fluent UI System Icons (#60), no emoji icons | PASS |
| Synthetic screenshots, no real account or chat data | PASS |
| Work text aligns to the start | PASS |
| Busy buttons keep their label footprint | PASS, automated |
| Send and Stop keep the same action slot | PASS, automated |
| No token animation or layout motion | PASS, source and automated checks |
| Long data and 200 chats at all four required widths | PASS, automated |
| Shell, composer, settings and memory card at 200% text | PASS, automated |
| Keyboard chat, stop, copy, memory, settings, theme and logout flow | PASS, automated |

The centered empty-chat greeting is required by #53. New chat becomes a secondary
navigation action when Chat or Personas has its own primary action. Other work
views retain the default primary New chat action. This resolves the conflicting
primary-action requirements using the final review rule in #58.

## Evidence

The PNG files in `goldens/` cover both themes and widths 390, 768, 1024 and 1440.
The earlier 1300 px evidence remains. Shell, account menu, settings and the most
text-heavy composer states also cover EN, PT-BR and Thai.

Run `flutter test` for the golden, layout, scale and keyboard checks.
`flutter_test_config.dart` loads the real fonts and runs
`scripts/check_design.sh` as part of that command. The design guard also rejects
all six forbidden-pattern probes used during verification.

The release web graph benchmark uses 200 synthetic nodes and ten runs.
Measured first run: 54 ms; median: 33.801 ms; maximum: 54 ms.
The limit is 200 ms. Its entry point is `test/memory/graph_benchmark.dart`.

Production activation is separate from this visual review.
