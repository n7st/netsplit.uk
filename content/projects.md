---
title: Projects
type: page
description: Software (and other) projects I've worked on.
date: 2022-11-17T00:01:30Z
---

Most of my software projects can be found on [my GitHub profile](https://github.com/n7st).

## Snoonet

I've been a volunteer for the [Snoonet IRC network](https://snoonet.org) since 2014, initially starting out managing
a worldwide set of virtual private servers running [InspIRCd](https://www.inspircd.org/). These days I serve as
assistant network director and put together software as required.

### Website

In 2019 I migrated [Snoonet's website](https://snoonet.org) from a custom [Ruby on Rails](https://rubyonrails.org/)
application to a vastly simplified static website generated using [Hugo](https://gohugo.io/). This helped to reduce
development overhead and cost of operation, and increase security by descoping features we didn't really need.

### SubGrok

[SubGrok](https://github.com/snoonetIRC/subgrok) is an IRC bot which monitors Reddit boards for new posts and announces
them in IRC channels. It's built with [Golang](https://go.dev/) and runs on a Linux virtual private server.

## WebService::Mattermost

[WebService::Mattermost](https://github.com/n7st/WebService-Mattermost) is a Perl 5 library used for interacting with
the [Mattermost](https://mattermost.com/) HTTP API and WebSocket gateway. It can be used to create chat bots or to
integrate other software with Mattermost.

[Here is an introductory guide to building a chatbot using the library.](/posts/2019/01/09/mattermost-bot/)
