---
title: "Remote Lab, Part 4: Configuring pfSense"
date: 2020-01-11T12:29:20
draft: false
type: post
tags: [ 'Remote Lab', 'OVH', 'Networking', 'pfSense']
description: |
    Part 4: Configuring NAT and firewall rules in pfSense.
---

* [Part 1 (Introduction, OVH configuration.)](/posts/2019/02/13/remote_proxmox_lab_intro/)
* [Part 2 (Configuring Proxmox.)](/posts/2019/02/13/configuring_proxmox/)
* [Part 3 (Installing pfSense.)](/posts/2019/02/17/installing_pfsense/)
* [Part 4 (Configuring pfSense. You're here!)](#)

Finally, we need to forward traffic from the WAN to internal VMs.

## Connecting a virtual machine to the router

Firstly, a new Proxmox virtual machine must be created. Ensure its network device
is set to `vmbr2` (which is configured as the OPT1 device in pfSense).

## Setting up virtual IP addresses

Virtual IPs are required for NAT. [Here is pfSense's official documentation](https://docs.netgate.com/pfsense/en/latest/book/firewall/virtual-ip-addresses.html).

1. From the "Firewall" menu, select "Virtual IPs".
2. Add two new virtual IPs with the following settings:
    * The internal IP address:
        - Type: "Proxy ARP"
        - Interface: "OPT1"
        - Address type: "Network"
        - Address(es): "10.5.4.2" / "32" (single IPv4 address)
        - Description: Not parsed
    * The external IP address:
        - Type: "Proxy ARP"
        - Interface: "WAN"
        - Address type: "Network"
        - Address(es): "5.39.60.71" / "32" (single IPv4 address)
        - Description: Not parsed

## Configuring 1:1 NAT

Next, we will bind all traffic for the external IP to an internal IP address.

1. From the "Firewall" menu, select "NAT", and then "1:1".
2. Add a new rule:
    - Interface: "WAN"
    - External subnet IP: "5.39.60.71"
    - Internal IP: "Single host" "10.5.4.2"
    - Destination: "Any"
    - Description: Not parsed

This forwards all traffic sent to the external IP address (5.39.60.71) to the
internal VM (10.5.4.2).

## Firewall rules to permit traffic to the servers

For this example, the VM installed requires HTTP and HTTPS traffic to be allowed
to the VM, so we need two firewall rules on the WAN device.

1. From the "Firewall" menu, select "Rules".
2. Add two rules:
    * HTTPS:
        - Action: "Pass"
        - Interface: "WAN"
        - Address family: "IPv4"
        - Protocol: "TCP"
        - Source: "Any"
        - Destination: "Single host or alias" "10.5.4.2"
        - From: "443"
        - To: "443"
        - Description: Not parsed
    * HTTP:
        - Action: "Pass"
        - Interface: "WAN"
        - Address family: "IPv4"
        - Protocol: "TCP"
        - Source: "Any"
        - Destination: "Single host or alias" "10.5.4.2"
        - From: "80"
        - To: "80"
        - Description: Not parsed

Further similar rules can be added for any other ports that need to be accessible
from the WAN.

