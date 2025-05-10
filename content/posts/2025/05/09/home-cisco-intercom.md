---
title: "Setting up a home intercom using Cisco 7941G phones"
date: 2025-05-09T22:58:00Z
draft: false
type: post
tags: [ 'Tutorial', 'Networking', 'Telephony' ]
description: |
    This is a guide on how to set up Cisco 7941G phones as an intercom system.
toc: true
---

## Introduction

Recently, I have been working on configuring several [Cisco 7941G](https://www.cisco.com/web/ANZ/cpp/refguide/hview/ipt/phone.html#7940g)
phones as an intercom between my house and workshop.

I chose to standardise on the Cisco 7941G for two reasons:

1. A friend lent me one for testing.
2. They're cheap and readily available on eBay.

The system now consists of three phones and a Raspberry Pi 4B.

The phones run Cisco's SIP firmware, which talks to [PJSIP](https://www.pjsip.org/)
and [Asterisk](https://www.asterisk.org/) on the Raspberry Pi. TFTP provides
firmware and configuration to the phones. NGINX serves up the telephone
directory, making it simpler to make calls within your network.

At the time of writing, [FreePBX](https://www.freepbx.org/) do not officially
support installations on Raspberry Pis, hence choosing plain Asterisk. It
would probably also be overkill for a small network.

I chose to run PJSIP instead of SIP due to SIP being removed in recent versions
of Asterisk.

## Setting up an intercom system of your own

After spending quite a lot of time configuring individual phones by hand, I
decided that Ansible would be a good fit for managing the configuration for the
various services involved in the system.

If you would like to set up your own intercom system, it is available
[here](https://git.taula.org/mike/ansible-asterisk-cisco-intercom).

### Prerequisites

A few things are required to set up your own system.

* At least two Cisco 7941G phones.
* A copy of the SIP firmware for the Cisco 7941G phone. I cannot provide this
  due to Cisco's licence, but it's easy to find with a cursory Google search.
* A Raspberry Pi with Debian 12 installed on it.

It would also be helpful to have a basic knowledge of computer networking.

### Setting up your home network

You will need a means of configuring static IP addresses for devices on your
network and a way of setting TFTP boot options based on MAC addresses. This is
all handled by [OPNsense](https://opnsense.org/), which I run on my router.

#### Static DHCP

Both the Raspberry Pi and SIP phones will need to have static IPv4 addresses
configured in your DHCP settings.

#### Booting from TFTP

The SIP phones netboot over TFTP. When you deploy the Ansible playbook, it sets
up the TFTP server with configuration for the phones and the firmware they need
to boot.

In OPNsense, TFTP booting can be configured on a per-MAC address basis in the
static DHCP mapping which was set up in the last step. It is hidden under an
advanced menu (Advanced - Show TFTP configuration).

| Form field        | Value                                             |
| :---------------- | :------------------------------------------------ |
| Set TFTP hostname | <the IP address or hostname of your Raspberry Pi> |
| Set bootfile      | `/srv/tftp/term41.default.loads`                  |

The bootfile is automatically placed in the correct location by the Ansible
playbook, so this path should always be the same.

### Making the Ansible playbook your own

Before the playbook can be run, there are two main requirements.

Firstly, you must find a copy of the SIP firmware for the phones. The following
files are required:

* `apps41.8-5-2TH1-9.sbn`
* `cnu41.8-5-2TH1-9.sbn`
* `cvm41sip.8-5-2TH1-9.sbn`
* `dsp41.8-5-2TH1-9.sbn`
* `jar41sip.8-5-2TH1-9.sbn`
* `SIP41.8-5-2S.loads`
* `term41.default.loads`

They need adding to the `roles/tftp/files/firmware/` directory in the Ansible
project. If you try to run the playbook without them, an error will be thrown.

Some configuration is also required:

#### `inventories/production/hosts.ini`

There are placeholders for the Asterisk, NGINX and TFTP servers. They can all be
the same server (in my case, the Raspberry Pi).

#### `inventories/production/group_vars/all.yml`

There are two example configurations for SIP phones. You will need to set the
MAC and IPv4 address for each phone.

In order to find the MAC, you can (after powering on a phone) visit the web
interface running on it. The "Host Name" should be set as the MAC in the
configuration.

### Deploying the Ansible playbook

```bash
ansible-playbook -i inventories/production/hosts.ini site.yml
```

### Verifying the system

After deploying the playbook, you should restart the phones and watch them boot
up. You should see the number you have configured on the screen, and the phone
icon on the right hand side should not have a cross next to it. If this is the
case, try making a call to one of your other extensions.

If you're having issues, try [Debugging Asterisk](#debugging-asterisk).

## Resources

Whilst configuring the system, I found a couple of useful resources:

* [Cisco 7941, Asterisk and SIP](https://www.whizzy.org/2017/02/23/cisco-7941-asterisk-and-sip/)
* [USECALLMANAGER.nz](https://usecallmanager)

## Pitfalls

The biggest issue I faced whilst setting up the phones was that they silently
fall back to old configurations if they fail validation or are absent. I
discovered that two of my phones could receive calls, but (as far as I could tell)
couldn't make them.

This had been caused by an abscence of a "dialplan" for the phones, meaning they
were falling back to configuration from their original network. That dialplan,
which I couldn't view, may have had an option to immediately connect when the
number "1" was entered. This, combined with the fact that I had chosen "1" as
the prefix for all my phone numbers, meant that the phones were unable to make
any calls.

## Debugging Asterisk

If you have any issues with setting up the phones (registration failures, calls
not being made), it can be helpful to watch traffic on the SIP port on the server:

```bash
sudo tcpdump -i any -n port 5060 and udp
```

You can also log into the Asterisk console and watch the debugging output:

```bash
sudo asterisk -rvvvvv
```

```bash
pjsip set logger on
```

Booting a phone or attempting to make a phone call should make any problems
clear.

