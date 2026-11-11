# Changelog


## Unreleased


### Chores

- Merge v2.0.1 back to release/v2.0.1

- Merge v2.0.1 back to development

- Merge v2.0.1 back to feature/main


### Features

- Add neutral foundation and strict brand accent roles


## v2.0.1 - 2026-11-11


### Bug Fixes

- Split-public-content-by-subject (#43)

- Keep-demo-layout-stable-and-soften-transitions (#44)

- Restore-chat-order-copy-and-local-timestamps (#45)

- Refine-chat-reading-and-composer-layout (#46)

- Preserve-isolated-memory-nodes-and-frame-graph (#47)

- Keep-composer-labels-readable-and-compact (#46)

- Remove-footer-credit-and-decorative-background (#48)


### Chores

- Merge v2.0.0 back to release/v2.0.0

- Merge v2.0.0 back to development

- Merge v2.0.0 back to feature/main

- Merge #43 split-public-content-by-subject

- Merge #44 keep-demo-layout-stable-and-soften-transitions

- Merge #45 restore-chat-order-copy-and-local-timestamps

- Merge #46 refine-chat-reading-and-composer-layout

- Merge #47 preserve-isolated-memory-nodes-and-frame-graph

- Merge #46 keep-composer-labels-readable-and-compact

- Merge #48 remove-footer-credit-and-decorative-background

- Prepare development for v2.0.1

- Prepare v2.0.1

- Release v2.0.1


## v2.0.0 - 2026-11-11


### Bug Fixes

- Loading-language (#38)

- Landing-role-language (#39)

- Landing-header-layout (#40)

- Landing-final-action (#41)

- Preserve-browser-path-on-startup (#42)


### Chores

- Merge v1.2.0 back to feature/main

- Add Flutter web project skeleton (#26)

- Merge #26 add Flutter web project skeleton

- Merge #27 design-system

- Merge #28 app-shell

- Merge #29 landing-page

- Merge #30 chat-screen

- Merge #32 memory-graph-and-cards

- Merge #33 persona-schema-forms

- Merge #34 usage-timing-stats-events

- Merge #38 loading-language

- Merge #35 messages-states-accessibility

- Merge #39 landing-role-language

- Merge #40 landing-header-layout

- Merge #41 landing-final-action

- Merge #36 prepare the production web build and deployment

- Merge #42 preserve-browser-path-on-startup

- Prepare v2.0.0 (#36)

- Merge #36 v2.0.0 preparation

- Prepare development for v2.0.0

- Finalize v2.0.0 changelog

- Release v2.0.0


### Documentation

- Update for #31


### Features

- Design-system (#27)

- App-shell (#28)

- Landing-page (#29)

- Chat-screen (#30)

- Add chat list and temporary chat banner (#31)

- Memory-graph-and-cards (#32)

- Persona-schema-forms (#33)

- Usage-timing-stats-events (#34)

- Messages-states-accessibility (#35)

- Prepare the production web build and deployment (#36)


## v1.2.0 - 2026-11-09


### Bug Fixes

- Compute X-Asodya-App-Proof header for unlimited proxy access

- Stop incognito draft leak and cross-conversation stream bleed

- Attach CSRF token to authenticated requests (403 on every chat)

- Correct token exchange gateway endpoint path to /apps/api/v1/exchange

- Attach CSRF token to authenticated requests (403 on every chat)

- Check the real session cookie instead of a stale localStorage flag

- Make the attachment-unsupported tooltip generic, not stale

- List actually-supported attachment types in the tooltip instead of a vague warning

- Drop the negative framing, just list supported attachment types

- Browser back button leaving the app instead of closing the graph screen

- Style every markdown element the bubble actually renders

- Conversation options menu invisible on touch devices

- Stop tracking a leftover agent worktree as an embedded repo


### Chores

- Scaffold Flutter multi-platform project

- Add encrypt and url_launcher packages for Asodya SSO

- Add file_picker and speech_to_text for chat attachments and voice input

- Update copy to reflect experimental MVP neural workspace across all languages

- Default endpoints to live Asodya Auth and API cloud services

- Replace Flutter default web branding with Cortex identity

- Prepare v1.2.0 (#25)

- Consolidate v1.2.0

- Prepare development for v1.2.0


### Features

- Implement adaptive monochrome chat UI locked to Tier 0

- Implement Asodya unified authentication via auth_apps SSO

- Add playful landing page with chromatic particle background

- Route through SessionGate between landing page and chat

- Stream chat completions and native execute through api_for_apps proxy

- Replace mocked delayed reply with real streaming and memory recall

- Wire memory recall toggle from the prompt dock into chat flow

- Add local-dev-only live log streaming panel

- Configure flutter_localizations with en/pt/th ARB files

- Add AppPreferencesService and AppPreferencesScope

- Localize UI strings and wire the theme/language switcher

- Model attachments, web search grounding and incognito capability flags

- Add attachment/voice services and route incognito + web search through ChatService

- Wire incognito chat, web search, attachments and voice recording into the UI

- Localize incognito, web search, attachment and voice strings

- Add resilient SSE reconnection with continue-generation retry

- Render fenced code blocks with a copy toolbar

- Add smart sticky auto-scroll with a scroll-to-bottom button

- Add per-chat draft persistence via DraftStore

- Implement monochrome neural workspace, clear all, and enforce mandatory auth sso

- Implement full 3-card architectural grid and hero layout on landing screen

- Improve language selector UI and display build timestamp version in footers

- Implement full 3-language translations (EN, PT, TH) across entire landing and chat UI

- Add standardized app_dev_run.sh and app_prod_deploy.sh with Cloudflare deployer

- Enrich SSO app context metadata and branding payload

- Wire up client-error telemetry, instrument auth exchange failures

- Implement issue #11's audio-message and attachment-rendering spec

- Implement all Option 2 UI/UX design refinements (#11)

- Feat: guest-mode removal, Memory Engine pill removal, conversation
persistence frontend wiring, and remove live-log frontend feature

Bundles the remaining live-edited work on this branch plus the
live-log frontend removal (issue #15, frontend half only, backend
route in cortex_api stays untouched for direct local use):

- Guest mode (continueAsGuest, guestModeStorageKey) fully removed.
- Memory Engine pill removed from the prompt dock.
- ChatService now fetches real conversation history from cortex_api's
  GET /conversations and GET /conversations/{id} instead of mock data.
- telemetry_panel.dart and cortex_logs_socket_adapter.dart deleted,
  along with their button in both chat screens and related settings/
  translations.

Verified: dart analyze clean (2 pre-existing harmless lint warnings
only), full test suite (35 tests) passes.

- Add cookie diagnostic report on successful auth exchange

- Conversation CRUD, real audio recording, and chat UX polish

- Draggable nodes, collapsible conversation clusters, reset-positions button

- Reconstruct historical attachments on conversation reload

- Port support tickets from certifications, add generic error CTA

- Add a copy button to every message bubble


### Refactoring

- Standardize proxy prefix to /apps/cortex/v1


### Tests

- Verify AppPreferencesController persists theme and locale

- Cover incognito memory-off enforcement and needs_web/attachments wiring


### merge

- Feature/4-auth-landing into feature/main

- Feature/3-cortex-api-integration into feature/main

- Fix/8-app-proof-header into feature/main

- Feature/5-i18n-theme-switcher into feature/main

- Feature/6-chat-features into feature/main

- Feature/7-resilience-features into feature/main


