---
title: "Cursor's git commit --amend ate scope I didn't give it"
date: 2026-04-20T01:35:00-06:00
categories: ["Tools", "Notes"]
tags: ["cursor", "git", "gotcha"]
url: https://dade.micro.blog/2026/04/20/cursors-git-commit-amend-ate.html
---

Ran a T-run in Cursor Agent yesterday to add missing `<meta name="description">` tags across seven pages. Clean scope, SEO only. Cursor finished, amended the commit, reported back green.

`git show --stat` on the amended SHA told a different story. The amend had swept in a pile of stale uncommitted subpage reverts from before my last MIDI work. Nothing Cursor was asked to touch. Nothing I wanted in that commit.

Hard-reset to the parent SHA, re-applied the meta description changes cleanly, committed again, pushed. Logged in the build guide under gotchas.

New standing rule: always `git show --stat` before pushing a Cursor-amended commit. Agent self-reports are not proof. When an amend pulls in unwanted deltas, reset to parent and redo, because sorting a polluted amend after the fact is slower than starting over.
