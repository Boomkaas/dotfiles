# Graph Report - Dotfiles  (2026-08-30)

## Corpus Check
- 297 files · ~210,038 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 416 nodes · 1216 edges · 81 communities (4 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Status Bar & UI Panels
- NixOS System & Modules
- NixOS System & Modules (2)
- NixOS System & Modules (3)
- NixOS System & Modules (8)
- NixOS System & Modules (11)
- NixOS System & Modules (12)
- NixOS System & Modules (13)
- NixOS System & Modules (14)

## God Nodes (most connected - your core abstractions)
1. `runStreamWatchdog()` - 15 edges
2. `updateHUDStatus()` - 14 edges
3. `startClaimProcess()` - 12 edges
4. `handleDirectoryPage()` - 11 edges
5. `handleStreamPage()` - 11 edges
6. `cancellableSleep()` - 10 edges
7. `setState()` - 10 edges
8. `handleCampaignsPage()` - 10 edges
9. `startClaimProcess()` - 10 edges
10. `scanFreeGamesPage()` - 9 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (81 total, 5 thin omitted)

### Community 0 - "Status Bar & UI Panels"
Cohesion: 0.08
Nodes (49): device, label, sub-cs, actions, control-center-margin-bottom, control-center-margin-left, control-center-margin-right, control-center-margin-top (+41 more)

### Community 1 - "NixOS System & Modules"
Cohesion: 0.24
Nodes (33): applyStreamPageOptimizations(), autoClaimAllButtons(), autoSwitchStreamer(), cancellableSleep(), checkChannelStatusGQL(), checkDSTCampaignStatus(), clearAllTimers(), createHUD() (+25 more)

### Community 8 - "NixOS System & Modules (8)"
Cohesion: 0.43
Nodes (17): advanceQueue(), cancellableSleep(), clearAllTimers(), clearState(), closeClaimerTab(), createHUD(), getState(), handleGamePage() (+9 more)

### Community 11 - "NixOS System & Modules (11)"
Cohesion: 0.80
Nodes (4): format_time_remaining(), get_quota(), main(), make_bar()

## Knowledge Gaps
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Should `Status Bar & UI Panels` be split into smaller, more focused modules?**
  _Cohesion score 0.07764705882352942 - nodes in this community are weakly interconnected._
- **Should `NixOS System & Modules (2)` be split into smaller, more focused modules?**
  _Cohesion score 0.07389162561576355 - nodes in this community are weakly interconnected._
- **Should `NixOS System & Modules (3)` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Should `Status Bar & UI Panels (4)` be split into smaller, more focused modules?**
  _Cohesion score 0.07692307692307693 - nodes in this community are weakly interconnected._
- **Should `Status Bar & UI Panels (5)` be split into smaller, more focused modules?**
  _Cohesion score 0.07692307692307693 - nodes in this community are weakly interconnected._
- **Should `Status Bar & UI Panels (6)` be split into smaller, more focused modules?**
  _Cohesion score 0.07692307692307693 - nodes in this community are weakly interconnected._
- **Should `Status Bar & UI Panels (7)` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._