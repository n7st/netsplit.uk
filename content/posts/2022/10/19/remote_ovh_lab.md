---
title: 'How to build a remote Proxmox and pfSense lab on an OVH dedicated server'
date: 2022-10-19T16:22:14Z
type: post
tags: [ 'Remote Lab', 'OVH', 'Networking', 'Systems', 'Tutorial' ]
toc: true
description: |
  This is a guide on how to set up a remote "lab" with multiple IP addresses on an OVH dedicated server using Proxmox and
  a pfSense router.
aliases:
  - /posts/2019/02/13/remote_proxmox_lab_intro/
  - /posts/2019/02/13/configuring_proxmox/
  - /posts/2019/02/17/installing_pfsense/
  - /posts/2020/01/11/configuring_pfsense/
---

## Introduction

This guide details how to set up a remote lab with a [pfSense](https://www.pfsense.org/) gateway on an OVH dedicated server,
including basic firewall rules for managing access to the router's web interface, and use of [Let's Encrypt](https://letsencrypt.org/)
for SSL certificates.

It was previously split into four parts which were written in 2019, but has now been consolidated into one post for readability
and updated to still be valid in 2022 after OVH merged SoYouStart into its main control panel.

### Why?

There are some benefits to setting up a dedicated server in this manner.

* You can manage assignment of OVH's additional IP addresses in one place, rather than having to manually set up the
  gateway on every single virtual machine.
* Traffic to your virtual machines is protected with one admin-friendly firewall.
* You'll use fewer IP addresses. Instead of having an address per machine, you can forward ports to machines which do
  not have a public IP address.

### Drawbacks

The main drawback to this approach is that you'll end up with a single large dedicated server which contains many
services. This makes managing downtime (for example for software updates) quite difficult. You're also putting all your
eggs in one basket, so make sure your configuration and data is backed up in case there's a disaster in the data centre.

All things considered, I'm still running a machine set up in this fashion after three years. It's been very stable and
quite low maintenance.

## Requirements

### An OVH dedicated server

First, you'll need to buy a dedicated server from [OVH](https://www.ovhcloud.com/en-gb/bare-metal/) or the more budget-friendly
[OVH Eco line](https://eco.ovhcloud.com/en-gb/). Please note that _Kimsufi_ servers unfortunately do not support additional
IP addresses, making them unsuitable for this configuration. This means that if you're using an Eco server, you **must**
choose either a _Rise_ or _SoYouStart_ server.

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

You will shortly receive two e-mails with invoices. After paying, the orders can take a while to fulfill. Once you
receive confirmation that your addresses have been set up, return to the IP management area to set up their virtual MAC
addresses.

#### Setting virtual MAC addresses for your additional IP addresses

1. Select "Manage IPs".
1. Select your server's hostname in the "Service" dropdown.
1. Click the "settings" icon (a cog) next to the first IP.
1. Select "Add a virtual MAC".
1. Fill out the form:
    * Name of VM: (this field is for display purposes only, so you can set the name to whatever you like)
    * Type of virtual MAC: ovh
    * You want to: Create a new virtual MAC address

Next, set up the second failover IP address.

1. Click the "settings" icon next to the second address.
1. Select "Add a virtual MAC".
1. Fill out the form:
    * Set the VM name (this is required but can be anything).
    * Use the failover MAC address from the first failover IP.

Again, fulfillment of virtual MAC addresses can take a few minutes. You won't receive an e-mail when they are finished,
so check back later to find out. After this, you should have a primary IP address with **no** virtual MAC address, and
two failover IP addresses with the **same** virtual MAC address. The virtual MAC addresses should be the same because
later on, you're going to use a 1:1 NAT rule to route the second failover IP to a virtual machine. Any further failover
IP addresses added to the environment should also be configured with the same virtual MAC address.

### Example IP and MAC addresses

For the rest of the guide, I'll use the following made up example IP addresses. Note that the MAC addresses for the
additional IP addresses are identical.

<div class="table-wrapper">

| Name         | IP address | MAC address       | Description                                                |
| :----------- | :--------- | :---------------- | :--------------------------------------------------------- |
| Primary      | 5.39.50.60 | (none)            | The address that was originally supplied with your server  |
| Additional 1 | 5.39.50.70 | 02:01:01:e4:44:44 | The IP address you'll use for pfSense's LAN interface      |
| Additional 2 | 5.39.50.71 | 02:01:01:e4:44:44 | The IP address you'll assign to your first virtual machine |

</div>

### OVH gateway IP addresses

Gateway addresses for OVH IP addresses are the address, but with the last octet changed to `254`. This means that your
primary IP address (ex. `5.39.50.60`) becomes `5.39.50.254`. This is documented in greater detail
[in the OVH network bridge documentation](https://docs.ovh.com/gb/en/dedicated/network-bridging/#determine-the-gateway-address).

## DNS configuration

Later, you will need subdomains for memorable access to the services you're configuring. Add some A records using your
DNS manager (replacing my example names and addresses).

<div class="table-wrapper">

| Type  | Name                | IP address | Description                                            |
| :---- | :------------------ | :--------- | :----------------------------------------------------- |
| A     | proxmox.example.com | 5.39.50.60 | Will be used to access Proxmox's web interface         |
| A     | pf.example.com      | 5.39.50.70 | Will be used to access pfSense's web interface         |
| A     | vm.example.com      | 5.39.50.71 | Will be used for public access to your virtual machine |

</div>

## Configuring Proxmox

Next, you'll need to install Proxmox on the server. I won't cover the basic installation in this post, but I am using
Proxmox VE 5, which is available as a template during installation with OVH's wizard.

### Securing Proxmox's web interface

Once you have installed your hypervisor and logged in, I recommend taking a couple of extra steps to improve security,
because the web interface is public facing:

1. Set up your own administrative user and disable the default one.
1. Set up two-factor authentication. I followed [this guide](http://jonspraggins.com/the-idiot-adds-two-factor-authentication-to-proxmox/).
1. Get a valid SSL certificate. I followed [this guide](https://pve.proxmox.com/wiki/HTTPS_Certificate_Configuration_(Version_4.x_and_newer)#Let.27s_Encrypt_using_acme.sh)
   to get a certificate from Let's Encrypt using `acme.sh` (but the steps using `certbot` look good, too).
1. Disable password authentication over SSH and use key authentication instead.

### Disabling the enterprise APT repository

Unless you have a Proxmox subscription, `apt` will fail with an exit code of 100. This is because it is trying to read
from the subscription-only enterprise APT repository.

Comment out the only line in `/etc/apt/sources.list.d/pve-enterprise.list` and run `apt update`.

Adding the "no subscription" repository to `/etc/apt/sources.list` means you will still receive Proxmox updates:

```
# Please note that the APT repositories in this sample file use the UK Debian
# mirror
deb http://ftp.uk.debian.org/debian bullseye main contrib

deb http://ftp.uk.debian.org/debian bullseye-updates main contrib

# security updates
deb http://security.debian.org bullseye-security main contrib

# PVE pve-no-subscription repository provided by proxmox.com,
# NOT recommended for production use
deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription
```

See [the Proxmox package repository guide](https://pve.proxmox.com/wiki/Package_Repositories) for more information.

### Network bridges

For the most basic setup, three network bridges are required (which will become
the WAN, LAN and OPT1 interfaces in our router). These are configured in the
host node's network settings.

<div class="table-wrapper">

| Name  | Type         | Ports/Slaves | IP address                          | Subnet mask   | Gateway                                   |
| :---- | :----------- | :----------- | :---------------------------------- | :------------ | :---------------------------------------- |
| vmbr0 | Linux bridge | eth0         | Primary IP address (ex. 5.39.50.60) | 255.255.255.0 | Primary gateway address (ex. 5.39.50.254) |
| vmbr1 | Linux bridge | dummy0       | (none)                              | (none)        | (none)                                    |
| vmbr2 | Linux bridge | dummy1       | (none)                              | (none)        | (none)                                    |

</div>

### Virtual hardware for pfSense

Below are the current specifications for my router's virtual hardware. Your
mileage may vary.

<div class="table-wrapper">

| Item             | Value                    | Notes                                                                                                |
| :--------------- | :----------------------- | :--------------------------------------------------------------------------------------------------- |
| CPU              | 2 vCPUs                  | A type of "host" (for host-passthrough) is required if you would like to use AES-NI CPU cryptography |
| RAM              | 4G                       |                                                                                                      |
| Storage          | 32G                      | I am using a VirtIO disk                                                                             |
| Network Device 1 | vmbr0, VirtIO (or E1000) | This will be used as the WAN interface                                                               |
| Network Device 2 | vmbr1, VirtIO (or E1000) | This will be used as the LAN interface                                                               |
| Network Device 3 | vmbr2, VirtIO (or E1000) | This will be used as the OPT1 interface                                                              |

</div>

## Installing pfSense

### First boot

At the firewall's first boot, you need to set up the bare minimum for accessing the web interface, where the
configuration will be finalised.

**VLANs do not need setting up at this time.**

* Assign vtnet0 (or em0) as the WAN interface. Set the IP address to your first failover IP address (ex. `5.39.60.70`).
* Assign vtnet1 (or em1) as the LAN interface.
* Press 2 to set the WAN interface's IP address.

<div class="table-wrapper">
    <table>
        <colgroup>
            <col style="width: 50%">
            <col style="width: 50%">
        </colgroup>
        <thead>
            <tr>
                <th colspan="2">Temporary WAN interface configuration</th>
            </tr>
            <tr>
                <th align="left">Value</th>
                <th align="left">Option</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td align="left">Configure IPv4 address WAN interface via DHCP? (y/n)</td>
                <td align="left">n</td>
            </tr>
            <tr>
                <td align="left">Enter the new WAN IPv4 subnet bit count (1 to 31)</td>
                <td align="left">31 (this will later be changed to 32 from the GUI)</td>
            </tr>
            <tr>
                <td align="left">For a WAN, enter the new WAN IPv4 upstream gateway address.</td>
                <td align="left">(nothing)</td>
            </tr>
            <tr>
                <td align="left">Configure IPv6 address WAN interface via DHCP6? (y/n)</td>
                <td align="left">y (you can fix this later)</td>
            </tr>
            <tr>
                <td align="left">Do you want to revert to HTTP as the webConfigurator protocol? (y/n)</td>
                <td align="left">n</td>
            </tr>
        </tbody>
    </table>
</div>

Next, you need to set up a temporary route to give yourself access to the web interface.

* From the main menu, press 8 to enter the shell.
* Add a route to the primary IP address' gateway: `route add -net 5.39.50.254/32 -iface vtnet0` making sure you
  substitute your own gateway IP (and set the iface as `em0` if you are using an E1000 network card).
* Set the route as default: `route add default 5.39.50.254` (substituting your own gateway address).
* Ping an external host to confirm internet access (`ping 8.8.8.8`).

### Temporarily disable the firewall

Before the firewall is properly configured, the firewall will need disabling so you have access to the web interface.
This is a temporary measure until you have given yourself permanent access with a firewall rule, but it does mean that
this section of the guide must be completed quickly (to reduce the amount of time the web interface is open to the
internet). If you do not have a static IP address at home, you may want to set this to the IP of your own VPN service
(which you could set up on the router by following [this guide](https://doc.pfsense.org/index.php/OpenVPN_Remote_Access_Server)).

In the pfSense console, temporarily disable the firewall: `pfctl -d`.

If you need to pause setup for any meaningful length of time, the firewall can be enabled from the console using
`pfctl -e`.

### First connection to the web interface

1. Navigate to the web interface (in this example, https://pf.example.com/).
1. Log in with the default username and password (`admin` and `pfsense`).
1. Skip the first-login wizard.
1. Change the password for the default user (just in case):
    1. From the "System" menu, choose "User Management".
    1. Edit the "admin" user.
    1. Change the password.

Later, you should disable the administrative user and add your own.

### Finalise configuration for the WAN interface

1. From the "System" menu, select "Routing".
1. Under the "Gateways" tab (which is selected by default), add a new gateway.
1. Fill in the form:
    * Interface: WAN
    * Address family: IPv4
    * Name: `OVH_Primary`
    * Gateway: `5.39.50.254`
    * Default gateway: (checked)
    * Show advanced
    * Weight: 1
    * Use non-local gateway: (checked)

Configuration changes restart the pf firewall, so you will need to stop it again
to finish the configuration.

Next, you need to set the correct address for the interface.

1. From the "Interfaces" menu, select "WAN".
1. Fill in the form:
    * MAC address: `02:01:01:e4:44:44` (the virtual MAC address you created earlier).
    * IPv4 address: `5.39.60.70`
    * IPv4 upstream gateway: `OVH_Primary` (the gateway you just created)
    * Block bogon networks: (checked)

Once again, this will enable the firewall, so you will need to disable it again
in order to whitelist a management IP address.

### Whitelist a management IP

1. From the "Firewall" menu, select "Aliases" and click "Add".
1. Fill in the form:
    * Name: Management
    * Description: Addresses to allow full access to the web interface
    * Type: Host(s)
    * IP or FQDN: (your home IP address)
1. Click "Save".
1. From the "Firewall" menu, "Rules", choose the "WAN" tab, and click "Add".
1. Fill in the form:
    * Action: Pass
    * Interface: WAN
    * Source: Single host or alias
    * Source address: Management
    * Destination: This firewall (self)
    * Log packets that are handled by this rule
    * Description: Permit remote access to the web interface
1. Click "Save", and apply the rule. This will restart the firewall (undoing step 1, and resecuring the router).

### Configuring the LAN and OPT1 interfaces

* The LAN interface should be static IPv4 with an IPv4 address of `192.168.1.1/24` (or another sensible reserved range,
  documented [on Wikipedia's "Reserved IP addresses" page](https://en.wikipedia.org/wiki/Reserved_IP_addresses)). There
  should not be an upstream gateway.
* The OPT1 interface should be static IPv4 with an IPv4 address of `10.5.4.1/24` (or, as above, another sensible
  reserved range). There should not be an upstream gateway.

### Disable hardware checksum offload

<blockquote cite="https://docs.netgate.com/pfsense/en/latest/config/advanced-networking.html#hardware-checksum-offloading">
  Checksum offloading is broken in some hardware, particularly some Realtek cards. Rarely, drivers may have problems
  with checksum offloading and some specific NICs. This will take effect after a machine reboot or re-configure of each
  interface.
</blockquote>

The network cards in SoYouStart machines do not appear to support hardware checksum offloading (this may need confirming
from other sources, but the card in mine certainly doesn't).

1. From the "System" menu, select "Advanced" and then go to the "Networking" tab.
1. Check "Disable hardware checksum offload".
1. Reboot the system ("Halt system" under the "Diagnostics" menu).

## Configuring pfSense

Finally, you need to forward traffic from the WAN to internal VMs.

### Connecting a virtual machine to the router

Firstly, a new Proxmox virtual machine must be created. Ensure its network device is set to `vmbr2` (which is configured
as the OPT1 device in pfSense).

### Setting up virtual IP addresses

Virtual IPs are required for NAT. [Here is pfSense's official documentation](https://docs.netgate.com/pfsense/en/latest/book/firewall/virtual-ip-addresses.html).

1. From the "Firewall" menu, select "Virtual IPs".
1. Add two new virtual IPs with the following settings:
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

### Configuring 1:1 NAT

Next, you will bind all traffic for the external IP to an internal IP address.

1. From the "Firewall" menu, select "NAT", and then "1:1".
1. Add a new rule:
    - Interface: "WAN"
    - External subnet IP: "5.39.60.71"
    - Internal IP: "Single host" "10.5.4.2"
    - Destination: "Any"
    - Description: Not parsed

This forwards all traffic sent to the external IP address (5.39.60.71) to the internal VM (10.5.4.2).

### Firewall rules to permit traffic to the servers

For this example, the VM installed requires HTTP and HTTPS traffic to be allowed to the VM, so you need two firewall
rules on the WAN device.

1. From the "Firewall" menu, select "Rules".
1. Add two rules:
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

Further similar rules can be added for any other ports that need to be accessible from the WAN.

## Growing

Not every extra virtual machine will require its own public IP address. It is worth considering if you can provide
public access to services via another means, for example you could have a single webserver which provides proxies to
web services running in virtual machines without a public IP address. If you're running a database server, for example,
it's likely that only other machines on your private network will need access to it.
