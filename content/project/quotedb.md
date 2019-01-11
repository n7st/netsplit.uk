---
title: "quoteDB"
date: 2019-01-06T19:40:38Z
draft: false
description: |
    quoteDB is an open-source bash.org inspired application for storing and
    managing quotes from IRC channels, providing a web frontend for viewing
    quotes.
os_link: https://git.netsplit.uk/mike/quoteDB
type: project
kind: project
tags: [ "irc", "golang", "docker" ]
authors: [ "Mike Jones" ]
---

* [Source](https://git.netsplit.uk/mike/quoteDB)
* Built in Golang
* Deployed in a Docker container

quoteDB v1.0.0 is now available on the Netsplit Gitlab. This release provides
the first working version of quoteDB, allowing IRC users to add quotes directly
from their channel into a Bash-like quotes database. The program can be
self-hosted and run in a Docker container. Presently, the web UI is read-only,
but I'm working on moderation features for the next release.

I recommend installation using Docker Compose. Please raise any issues or bugs
on the Gitlab repository.

