---
title: "Introduction: Remote Proxmox and pfSense Lab"
date: 2019-02-13T20:05:24Z
type: post
authors: [ 'Mike Jones' ]
tags: [ 'Remote Lab', 'OVH', 'Networking' ]
description: |
    Part 1: Building a remote lab with Proxmox and pfSense on an OVH dedicated
    server. Set up a dedicated server with multiple IP addresses.
---

* [Part 1 (Introduction, OVH configuration. You're here!)](/posts/2019/02/13/remote_proxmox_lab_intro/)
* [Part 2 (Configuring Proxmox.)](#)

## Overview

This guide details how to set up a remote lab with a
[pfSense](https://www.pfsense.org/) gateway on an OVH dedicated server,
including basic firewall rules for managing access to the router's web
interface, and use of [Let's Encrypt](https://letsencrypt.org/) for SSL
certificates.

First, we'll configure the server and its IP addresses.

## Why?

* Manage OVH's failover IP addresses in one place, rather than having to
  manually set up the gateway on every single virtual machine.
* Protect traffic to your virtual machines with one user-friendly firewall.
* Use fewer IP addresses. Instead of having an address per machine, you can
  forward ports to machines which do not have a public IP address.

## Requirements

1. An [OVH](https://www.ovh.co.uk/) or [SoYouStart](https://www.soyoustart.com/en/)
   dedicated server. I am using a lower end SoYouStart server.
2. A domain name (and access to its DNS manager). In this example, I will use the
   domain `example.com`.
3. Images for pfSense and (in this example) Ubuntu.

## OVH configuration

### Failover IP addresses


OVH allow up to 16 extra free (after the initial setup fee) "failover" IP
addresses with their dedicated servers. These can be used to give a public IP
address to a virtual machine. For the sake of this guide, I have two failover IP
addresses: one for the router, and one for the first virtual machine, which I
will make publicly accessible.

1. From the OVH control panel, select "IP".
2. Select "Order IPs".
3. Fill out the order form:
    * Server: (choose your server's hostname)
    * Number of IPs: 1 address
    * Country: (your choice)
    * Accept the terms and conditions
4. Repeat the process a second time for another IP address.

You will shortly receive two e-mails with invoices. After paying, the orders can
take a while to fulfill. Once you receive confirmation that your addresses have
been set up, return to the IP management area to set up their virtual MAC
addresses.

1. Select "Manage IPs".
2. Select your server's hostname in the "Service" dropdown.
3. Click the "settings" icon (a cog) next to the first IP.
4. Select "Add a virtual MAC".
5. Fill out the form:
    * Name of VM: (this field is for display purposes only, so you can set the
      name to whatever you like)
    * Type of virtual MAC: ovh
    * You want to: Create a new virtual MAC address

Next, set up the second failover IP address.

1. Click the "settings cog" next to the second address.
2. Select "Add a virtual MAC".
3. Set the VM name (this is required but can be anything).
4. Use the failover MAC address from the first failover IP.

Again, fulfillment of the virtual MAC addresses can take a few minutes. You
won't receive an e-mail when they are finished, so check back later to find out.
After this, you should have a primary IP address with **no** virtual MAC
address, and two failover IP addresses with the **same** virtual MAC address.
The virtual MAC addresses should be the same because later on, we're going to
use a 1:1 NAT rule to route the second failover IP to a virtual machine. Any
further failover IP addresses added to the environment should also be
configured with the same virtual MAC address.

## IP address reference

For the rest of the guide, I will use the following (made up) examples:

<table class="table table-bordered">
    <colgroup>
        <col style="width: 15%">
        <col style="width: 15%">
        <col style="width: 15%">
        <col style="width: auto">
    </colgroup>
    <thead>
        <tr>
            <th>Name</th>
            <th>IP Address</th>
            <th>MAC Address</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>Primary</td>
            <td>5.39.50.60</td>
            <td>(none)</td>
            <td>The IP address that was originally supplied with your server</td>
        </tr>
        <tr>
            <td>Failover 1</td>
            <td>5.39.60.70</td>
            <td>02:01:01:e4:44:44</td>
            <td>The IP address we'll use for pfSense's LAN interface</td>
        </tr>
        <tr>
            <td>Failover 2</td>
            <td>5.39.60.71</td>
            <td>02:01:01:e4:44:44</td>
            <td>The IP address we'll assign to the first virtual machine</td>
        </tr>
    </tbody>
</table>

### OVH gateway IP addresses

Gateway addresses for OVH IP addresses are the address, but with the last octet
changed to `254`. This means that our primary IP address (ex. `5.39.50.60`)
becomes `5.39.50.254`. This is documented in greater detail
[here](https://docs.ovh.com/gb/en/dedicated/network-bridging/#determine-the-gateway-address).

### Subdomain configuration

Later, we will need (well, *want*) subdomains for memorable access to the
services we're configuring. Add some A records using your DNS manager (replacing
my example names and addresses):

<table class="table table-bordered">
    <colgroup>
        <col style="width: 33.3%">
        <col style="width: 33.3%">
        <col style="width: auto">
    </colgroup>
    <thead>
        <tr>
            <th>Type</th>
            <th>Name</th>
            <th>IP address</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>A</td>
            <td>proxmox.example.com</td>
            <td>5.39.50.60</td>
        </tr>
        <tr>
            <td>A</td>
            <td>pf.example.com</td>
            <td>5.39.60.70</td>
        </tr>
        <tr>
            <td>A</td>
            <td>vm.example.com</td>
            <td>5.39.60.71</td>
        </tr>
    </tbody>
</table>

In the next part, we'll install and configure Proxmox on the dedicated server.

*[Read part 2](/posts/2019/02/13/configuring_proxmox/)*

