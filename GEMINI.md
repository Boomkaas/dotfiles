# Project Guidelines: Dotfiles

## Graphify-First Codebase Analysis & Token Optimization
- **Check for `graphify-out/` First**: When inspecting project structure, NixOS modules, scripts, or configuration dependencies, use `graphify-out/` (`GRAPH_REPORT.md`, `graph.json`, `obsidian/`) as the primary index instead of scanning files from scratch.
- **Fast-Path Context**: Query the graph directly (`graphify query "<question>"`) or read specific node notes in `graphify-out/obsidian/` to understand component relationships.
- **Active Maintenance**: When modifying or adding configurations, scripts, or modules, keep `graphify-out/` updated via `gsync` / `graphify-all` or `graphify . --update`.
