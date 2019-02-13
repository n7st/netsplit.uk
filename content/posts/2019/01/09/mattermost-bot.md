---
title: "Building a Mattermost Chatbot in Perl"
date: 2019-01-09T17:53:11Z
draft: false
type: post
authors: [ 'Mike Jones' ]
tags: [ 'Perl 5', 'Chatops', 'Bot', 'WebService::Mattermost', 'Tutorial' ]
description: |
    This article provides a brief overview of how to set up a Mattermost chatbot
    in Perl 5.
---

## Introduction

[WebService::Mattermost](https://metacpan.org/pod/WebService::Mattermost) is an
alternative [Mattermost](https://mattermost.com/) chatbot library written in
Perl. It provides two interfaces to the Mattermost API and WebSocket gateway:
from a script, and as a base for [Moo](https://metacpan.org/pod/Moo) and
[Moose](https://metacpan.org/pod/Moose) classes. In this article, I will cover
how to use it in a basic script, and demonstrate with a bot which greets users.

## Requirements

Installable from [CPAN](https://www.cpan.org/):

* [`WebService::Mattermost`](https://metacpan.org/pod/WebService::Mattermost)
  ([source](https://git.netsplit.uk/mike/webservice-mattermost))

## Final code

For anyone who doesn't want to read, here is the final product. You will need to
change the authentication values in the constructor for
[`WebService::Mattermost::V4::Client`](https://metacpan.org/pod/WebService::Mattermost::V4::Client)
to your own Mattermost server and bot user.

{{< gist n7st d73a03a0aa17b731fd31e2b4fa219e6c "greeter.pl" >}}

## Breakdown

* First, as with all good Perl scripts, we need to enable strictures and
  warnings.
* Then, we instantiate the bot class with three required configuration values:
    - `username`: your Mattermost username (e.g. "mybot@myemailaddress.org")
    - `password`: your Mattermost password (e.g. "hunter2")
    - `base_url`: the base URL of your Mattermost server's API (e.g.
      "[https://my.mattermost-server.com/api/v4/](#)")

{{< gist n7st d73a03a0aa17b731fd31e2b4fa219e6c "use.pl" >}}

* Next, we add a non-blocking loop which watches for messages from the gateway.
* Received messages include two arguments: `$bot`, which contains our instance
  of `WebService::Mattermost::V4::Client`, and `$args`, which contains the
  message from the gateway.

{{< gist n7st d73a03a0aa17b731fd31e2b4fa219e6c "loop.pl" >}}

* Finally, we start the bot.

{{< gist n7st d73a03a0aa17b731fd31e2b4fa219e6c "start.pl" >}}

## Extending

In the bot's event loops, there are some additional utilites, accessible through
the `bot` argument:

- `$bot->api`: a full Mattermost API integration
  ([WebService::Mattermost::V4::API](https://metacpan.org/pod/WebService::Mattermost::V4::API))
- `$bot->ua`: an instance of [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent)
- `$bot->logger`: an instance of [Mojo::Log](https://metacpan.org/pod/Mojo::Log)

