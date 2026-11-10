# Changelog


## Unreleased


### Chores

- Merge v1.2.0 back to feature/main

- Add Flutter web project skeleton (#26)

- Merge #26 add Flutter web project skeleton

- Merge #27 design-system

- Merge #28 app-shell


### Features

- Design-system (#27)

- App-shell (#28)

- Landing-page (#29)


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


