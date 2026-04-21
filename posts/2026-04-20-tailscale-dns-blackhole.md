---
title: "Tailscale MagicDNS was null-routing my DNS to 0.0.0.0"
date: 2026-04-20T01:32:00-06:00
categories: ["Tools", "Notes"]
tags: ["tailscale", "dns", "debugging"]
url: https://dade.micro.blog/2026/04/20/tailscale-magicdns-was-nullrouting-my.html
---

Spent an hour yesterday watching Chrome return `ERR_CONNECTION_REFUSED` on a custom domain while `curl` hit the same URL and got a clean 200. Split-brain DNS, obviously. The cause wasn't.

`scutil --dns` showed 100.100.100.100 (Tailscale MagicDNS) as the resolver. MagicDNS was returning 0.0.0.0 for a public domain it had no answer for, and Chrome was honoring it. Disconnect Tailscale, resolver flips back to upstream, domain loads. Reconnect Tailscale with Chrome's Secure DNS set to 1.1.1.1 and it also loads.

Lesson logged: a 0.0.0.0 in a DNS answer doesn't automatically mean a blocklist or a hosts file. It can come from Tailscale MagicDNS when it has no record for a public name and decides to null-route by default. Worth checking `scutil --dns` before blaming `/etc/hosts`, `/etc/resolver/`, or the registrar.
