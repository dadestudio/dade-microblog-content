---
title: "How I write with Cursor and Opus 4.7"
date: 2026-04-18T19:30:00-06:00
categories: ["Tools", "Essays"]
tags: ["cursor", "claude", "writing-workflow"]
url: https://dade.micro.blog/2026/04/19/how-i-write-with-cursor.html
---

Every post on this blog goes through the same loop, including this one.

The setup: a Git repo called `dade-microblog-content` with a `posts/` directory of markdown files, each with YAML frontmatter for title, date, categories, and tags. Micro.blog watches the repo. When I push to `main`, the new post appears on dade.micro.blog within a minute. No CMS, no admin panel, no draft-in-the-browser purgatory.

The drafting loop: I open the repo in Cursor and pick a model. For micro-posts, Sonnet is fine. For anything that needs argument, structure, or voice work, I switch to Claude Opus 4.7. Cursor Composer lets me draft a whole file from a brief or take an existing draft and rework it section by section. I treat it like writing with a co-writer who is fast and very literal: needs specific instructions, gives back something I can edit, never gets bored of the third revision.

The voice pass: any post that goes public gets a Mode 5 AI-Tell Prevention pass. Mode 5 is a custom instruction set I run that strips em dashes, smart quotes, and the vocabulary that makes AI-generated text obvious on sight. No 'delve', no 'leverage', no 'robust', no 'navigate the complexities of', no 'in this post we will explore'. If a sentence sounds like a LinkedIn carousel, Mode 5 catches it before I do.

A prompt pattern that works for essays: "Here is the brief and three bullet points I want to hit. Write a 250-word draft in my voice. Use first person. Lead with a specific moment, not a thesis. No filler intro." Specificity in the prompt tracks directly to specificity in the output. Vague briefs produce vague drafts every single time, no matter how good the model is.

The shipping step: commit to `main` with a meaningful message, push, done. Micro.blog handles the rest. The repo is the source of truth and the editor is the same one I already use to write code.

This post was drafted in Cursor with Opus 4.7, edited in two passes, and committed from the same window I am typing in now.
