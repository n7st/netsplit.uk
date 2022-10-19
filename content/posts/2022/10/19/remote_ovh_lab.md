---
title: 'Build a remote Proxmox and pfSense lab on OVH dedicated servers'
date: 2022-10-19T16:22:14Z
type: post
tags: [ 'Remote Lab', 'OVH', 'Networking', 'Systems' ]
toc: true
description: |
  This is a guide on how to set up a remote "lab" with multiple IP addresses on an OVH server using Proxmox and
  pfSense.
---

## Introduction

This guide details how to set up a remote lab with a [pfSense](https://www.pfsense.org/) gateway on an OVH dedicated server,
including basic firewall rules for managing access to the router's web interface, and use of [Let's Encrypt](https://letsencrypt.org/)
for SSL certificates.

It was previously split into four parts which were written in 2019, but has now been consolidated into one post for readability.

## Why?

There are some benefits to setting up a dedicated server in this manner.

* You can manage assignment of OVH's additional IP addresses in one place, rather than having to manually set up the
  gateway on every single virtual machine.
* Traffic to your virtual machines is protected with one admin-friendly firewall.
* You'll use fewer IP addresses. Instead of having an address per machine, you can forward ports to machines which do
  not have a public IP address.

## Drawbacks

The main drawback to this approach is that you'll end up with a single large dedicated server which contains many
services. This makes managing downtime (for example for software updates) quite difficult. You're also putting all your
eggs in one basket, so make sure your configuration and data is set up in case there's a disaster in the data centre.

All things considered, I'm still running a machine set up in this fashion after three years. It's been very stable and
quite low maintenance.

## Requirements

### An OVH dedicated server

First, you'll need to buy a dedicated server from [OVH](https://www.ovhcloud.com/en-gb/bare-metal/). Unfortunately, their
budget-friendly [Eco line](https://eco.ovhcloud.com/en-gb/) does _not_ support additional IP addresses, making them unsuitable
for this configuration.

### At least two additional IP addresses

OVH provide [additional IP addresses](https://www.ovhcloud.com/en-gb/network/additional-ip/), which you'll attach to your
dedicated server for your router and externally facing virtual machines.

You'll use the first additional IP address as your router's public IP address. The second (and any extras) will be used,
where required, as public addresses for your virtual machines.

I'll cover how to assign additional IP addresses to your dedicated server below.

### A domain name

A domain name will be useful for forward and reverse DNS for your virtual machines. You'll also need access to its DNS
management panel.

## Configuring your OVH server

This setup will all be undertaken from the OVH control panel.

### Additional IP addresses

#### Ordering the additional IP addresses

1. From the OVH control panel, select your dedicated server.
1. From your dedicated server's dashboard, select "IP".
1. Under "Order", select "Additional IPs".
1. Fill out the order form:
    * Service: (choose your server's hostname)
    * Number of IPs: 1 address
    * Country: (your choice)
    * Accept the terms and conditions
1. Repeat the process a second time for another IP address.

#### Example IP and MAC addresses

For the rest of the guide, I'll use the following made up example IP addresses:

| Name         | IP address | MAC address       | Description                                                |
| :----------- | :--------- | :---------------- | :--------------------------------------------------------- |
| Primary      | 5.39.50.60 | (none)            | The address that was originally supplied with your server  |
| Additional 1 | 5.39.50.70 | 01:01:01:e4:44:44 | The IP address you'll use for pfSense's LAN interface      |
| Additional 2 | 5.39.50.71 | 02:01:01:e4:44:44 | The IP address you'll assign to your first virtual machine |
