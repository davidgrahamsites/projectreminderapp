# DesignKit — restart
Build: `swift build --package-path Packages/DesignKit`. Linked into all 3 targets via project.yml.
To change the look: edit `Theme.swift` (tokens) / `Components.swift` (components); rebuild the apps
(`xcodegen generate` then xcodebuild each scheme). Direction lives in repo-root `design.md`.
