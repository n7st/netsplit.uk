---
title: "Remote Lab, Part 3: Installing pfSense"
date: 2019-02-17T22:22:25Z
draft: false
type: post
authors: [ 'Mike Jones' ]
tags: [ 'Remote Lab', 'OVH', 'Networking', 'pfSense' ]
description: |
    Part 3: Install pfSense on an OVH dedicated server.
---

* [Part 1 (Introduction, OVH configuration.)](/posts/2019/02/13/remote_proxmox_lab_intro/)
* [Part 2 (Configuring Proxmox.)](/posts/2019/02/13/configuring_proxmox/)
* [Part 3 (Installing pfSense. You're here!)](#)

## First boot

At the firewall's first boot, we need to set up the bare minimum for accessing
the web interface, where the configuration will be finalised.

**VLANs do not need setting up at this time.**

* Assign vtnet0 (or em0) as the WAN interface. Set the IP address to your first
  failover IP address (ex. `5.39.60.70`).
* Assign vtnet1 (or em1) as the LAN interface.
* Press 2 to set the WAN interface's IP address.

<table class="table table-bordered">
    <colgroup>
        <col style="width: 50%">
        <col style="width: 50%">
    </colgroup>
    <thead>
        <tr>
            <th colspan="2">Temporary WAN interface configuration</th>
        </tr>
        <tr>
            <th>Value</th>
            <th>Option</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>Configure IPv4 address WAN interface via DHCP? (y/n)</td>
            <td>n</td>
        </tr>
        <tr>
            <td>Enter the new WAN IPv4 subnet bit count (1 to 31)</td>
            <td>31 (this will be changed from the GUI)</td>
        </tr>
        <tr>
            <td>For a WAN, enter the new WAN IPv4 upstream gateway address.</td>
            <td>(nothing)</td>
        </tr>
        <tr>
            <td>Configure IPv6 address WAN interface via DHCP6? (y/n)</td>
            <td>y (we can fix this later)</td>
        </tr>
        <tr>
            <td>Do you want to revert to HTTP as the webConfigurator protocol? (y/n)</td>
            <td>n</td>
        </tr>
    </tbody>
</table>

Next, we need to set up a temporary route to give us access to the web interface.

* From the main menu, press 8 to enter the shell.
* Add a route to the primary IP address' gateway: `$ route add -net 5.39.50.254/32 -iface vtnet0`
  making sure you substitute your own gateway IP (and set the iface as `em0` if
  you are using an E1000 network card).
* Set the route as default: `$ route add default 5.39.50.254` (substituting your
  own gateway address).
* Ping an external host to confirm internet access (`$ ping 8.8.8.8`).

## Temporarily disable the firewall

Before the firewall is properly configured, the firewall will need disabling so
you have access to the web interface. This is a temporary measure until we have
given ourselves permanent access with a firewall rule, but it does mean that
this section of the guide must be completed quickly (to reduce the amount of
time the web interface is open to the internet). If you do not have a static IP
address at home, you may want to set this to the IP of your own VPN service
(which you could set up on the router by following
[this guide](https://doc.pfsense.org/index.php/OpenVPN_Remote_Access_Server)).

In the pfSense console, temporarily disable the firewall: `$ pfctl -d`.

If you need to pause setup for any meaningful length of time, the firewall can
be enabled from the console using `$ pfctl -e`.

## First connection to the web interface

1. Navigate to the web interface (in this example, https://pf.example.com/).
2. Log in with the default username and password (`admin` and `pfsense`).
3. Skip the first-login wizard.
4. Change the password for the default user (just in case):
    1. From the "System" menu, choose "User Management".
    2. Edit the "admin" user.
    3. Change the password.

Later, you should disable the administrative user and add your own.

## Finalise configuration for the WAN interface

1. From the "System" menu, select "Routing".
2. Under the "Gateways" tab (which is selected by default), add a new gateway.
3. Fill in the form:
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

Next, we need to set the correct address for the interface.

1. From the "Interfaces" menu, select "WAN".
2. Fill in the form:
    * MAC address: `02:01:01:e4:44:44` (the virtual MAC address we created earlier).
    * IPv4 address: `5.39.60.70`
    * IPv4 upstream gateway: `OVH_Primary` (the gateway we just created)
    * Block bogon networks: (checked)

Once again, this will enable the firewall, so you will need to disable it again
in order to whitelist a management IP address.

## Whitelist a management IP

1. From the "Firewall" menu, select "Aliases" and click "Add".
2. Fill in the form:
    * Name: Management
    * Description: Addresses to allow full access to the web interface
    * Type: Host(s)
    * IP or FQDN: (your home IP address)
3. Click "Save".
4. From the "Firewall" menu, "Rules", choose the "WAN" tab, and click "Add".
5. Fill in the form:
    * Action: Pass
    * Interface: WAN
    * Source: Single host or alias
    * Source address: Management
    * Destination: This firewall (self)
    * Log packets that are handled by this rule
    * Description: Permit remote access to the web interface
6. Click "Save", and apply the rule. This will restart the firewall (undoing
   step 1, and resecuring the router).

## Configuring the LAN and OPT1 interfaces

* The LAN interface should be static IPv4 with an IPv4 address of
  `192.168.1.1/24` (or another sensible reserved range, documented
  [here](https://en.wikipedia.org/wiki/Reserved_IP_addresses)). There should not
  be an upstream gateway.
* The OPT1 interface should be static IPv4 with an IPv4 address of
  `10.5.4.1/24` (or, as above, another sensible reserved range). There should not
  be an upstream gateway.

## Disable hardware checksum offload

>Checksum offloading is broken in some hardware, particularly some Realtek cards.
 Rarely, drivers may have problems with checksum offloading and some specific NICs.
 This will take effect after a machine reboot or re-configure of each interface.

The network cards in SoYouStart machines do not appear to support hardware
checksum offloading (this may need confirming from other sources, but the card
in mine certainly doesn't).

1. From the "System" menu, select "Advanced" and then go to the "Networking" tab.
2. Check "Disable hardware checksum offload".
3. Reboot the system ("Halt system" under the "Diagnostics" menu).

*Part 4 coming soon...*

