---
title: "Remote Lab, Part 2: Configuring Proxmox"
date: 2019-02-13T22:02:42Z
draft: false
type: post
tags: [ 'Remote Lab', 'Proxmox', 'pfSense', 'OVH', 'Networking' ]
description: |
    Part 2: Configuring Proxmox and setting up the base virtual machines for our
    remote virtual lab.
---

* [Part 1 (Introduction, OVH configuration.)](/posts/2019/02/13/remote_proxmox_lab_intro/)
* [Part 2 (Configuring Proxmox. You're here!)](#)
* [Part 3 (Installing pfSense.)](/posts/2019/02/17/installing_pfsense/)
* [Part 4 (Configuring pfSense.)](/posts/2020/01/11/configuring_pfsense)

Now, we'll need to install Proxmox on the server. I won't cover the basic
installation in this post, but I am using Proxmox VE 5, which is available as a
template during installation with OVH's wizard.

### Securing Proxmox's web interface

Once you have installed your hypervisor and logged in, I recommend taking a
couple of extra steps to improve security, because the web interface is public
facing:

1. Set up your own administrative user and disable the default one.
2. Set up two-factor authentication. I followed
   [this guide](http://jonspraggins.com/the-idiot-adds-two-factor-authentication-to-proxmox/).
3. Get a valid SSL certificate. I followed
   [this guide](https://pve.proxmox.com/wiki/HTTPS_Certificate_Configuration_(Version_4.x_and_newer)#Let.27s_Encrypt_using_acme.sh)
   to get a certificate from Let's Encrypt using `acme.sh` (but the steps using
   `certbot` look good, too).
4. Disable password authentication over SSH and use key authentication instead.

### Disabling the enterprise apt repository

Unless you have a Proxmox subscription, `apt` will fail with an exit code of 100.
This is because it is trying to read from the subscription-only enterprise apt
repository.

Comment out the only line in `/etc/apt/sources.list.d/pve-enterprise.list` and
run `apt update`.

### Network bridges

For the most basic setup, three network bridges are required (which will become
the WAN, LAN and OPT1 interfaces in our router). These are configured in the
host node's network settings.

| Name  | Type         | Ports/Slaves | IP address                          | Subnet mask   | Gateway                                   |
|-------|--------------|--------------|-------------------------------------|---------------|-------------------------------------------|
| vmbr0 | Linux bridge | eth0         | Primary IP address (ex. 5.39.50.60) | 255.255.255.0 | Primary gateway address (ex. 5.39.50.254) |
| vmbr1 | Linux bridge | dummy0       | (none)                              | (none)        | (none)                                    |
| vmbr2 | Linux bridge | dummy1       | (none)                              | (none)        | (none)                                    |

### Virtual hardware for pfSense

Below are the current specifications for my router's virtual hardware. Your
mileage may vary.

<table class="table table-bordered">
    <colgroup>
        <col style="width: 33.3%">
        <col style="width: 33.3%">
        <col style="width: auto">
    </colgroup>
    <thead>
        <tr>
            <th>Item</th>
            <th>Value</th>
            <th>Notes</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>CPU</td>
            <td>2 vCPU</td>
            <td>
                A type of "host" (for host-passthrough) is required if you would
                like to use AES-NI CPU Crypto
            </td>
        </tr>
        <tr>
            <td>RAM</td>
            <td>4G</td>
            <td></td>
        </tr>
        <tr>
            <td>Storage</td>
            <td>32G</td>
            <td>I am using a VirtIO disk</td>
        </tr>
        <tr>
            <td>Network Device 1</td>
            <td>vmbr0, VirtIO (or E1000)</td>
            <td>This will be used as the WAN interface</td>
        </tr>
        <tr>
            <td>Network Device 2</td>
            <td>vmbr1, VirtIO (or E1000)</td>
            <td>This will be used as the LAN interface</td>
        </tr>
        <tr>
            <td>Network Device 3</td>
            <td>vmbr2, VirtIO (or E1000)</td>
            <td>This will be used as the OPT1 interface</td>
        </tr>
    </tbody>
</table>

In the next part, we'll install pfSense and configure the basic interfaces.

*[Read part 3](/posts/2019/02/17/installing_pfsense)*

