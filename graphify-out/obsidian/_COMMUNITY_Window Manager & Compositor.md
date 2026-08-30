---
type: community
cohesion: 0.25
members: 8
---

# Window Manager & Compositor

**Cohesion:** 0.25 - loosely connected
**Members:** 8 nodes

## Members
- [[configmangoanimation.conf]] - concept - config/mango/animation.conf
- [[configmangoautostart.conf]] - concept - config/mango/autostart.conf
- [[configmangoconfig.conf]] - concept - config/mango/config.conf
- [[configmangoeffect.conf]] - concept - config/mango/effect.conf
- [[configmangoenv.conf]] - concept - config/mango/env.conf
- [[configmangolayout.conf]] - concept - config/mango/layout.conf
- [[configmangorule.conf]] - concept - config/mango/rule.conf
- [[configmangosettings.conf]] - concept - config/mango/settings.conf

## Live Query (requires Dataview plugin)

```dataview
TABLE source_file, type FROM #community/Window_Manager__Compositor
SORT file.name ASC
```

## Connections to other communities
- 1 edge to [[_COMMUNITY_NixOS System & Modules (3)]]

## Top bridge nodes
- [[configmangoconfig.conf]] - degree 8, connects to 1 community