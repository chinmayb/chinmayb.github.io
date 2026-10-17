---
layout: post
title: "DNS Updates and Transfers"
date: 2026-10-12 11:41:00 +0530
categories: general
tags: [DNS, networking, learning]
---

> DNS Part II

We looked at evolution and query flow in the [previous post](https://chinmayabharadwaj.substack.com/p/dns-evolution-and-flow?r=pq6fj&utm_campaign=post-expanded-share&utm_medium=web). Let’s look at how data redundancy and update propagation are achieved in the DNS.
![DNS update and propagation flow](https://substackcdn.com/image/fetch/$s_!MN2_!,w_1456,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F19bc25bd-da36-493c-93f3-7fcbd94ec205_2701x1203.png)

Let’s take a real world example. You've set up a cool website, `shipmyproduct.com` to sell your product. You find the registrars like `godaddy` and purchase a domain and wire it to your web servers, which have the following IPs

52.168.10.11 (node1)

52.168.10.12 (node2)

52.168.10.13 (node3)

Now imagine if the node2 goes down, or its IP has been changed to `52.168.10.14` for whatever reason. Users resolving to `52.168.10.12` may see timeouts (to be precise the browser sends SYN packets and gets no response) or see 404 Not found errors impacting your business. So you need to update the DNS to point your domain to the new IP. Most vendors make your life simple by abstracting it.

For learning sake, lets say you’re doing it manually. The IP/record update should be done in a zone file at the **primary server**, vendor APIs or via DDNS update ([Dynamic DNS update](https://www.rfc-editor.org/info/rfc2136/)). Typically, the server where the domain is hosted or answers from its own copy is called **Authoritative Server**. **Primary DNS server** is the one where the edits are made. As we said in the previous post, DNS is a distributed, eventually consistent system. So how do we propagate the updates to other servers and resolvers across the globe? Pause and think about it. There are 2 broad approaches:

1. Send notification to other servers (**Secondaries**) and let them pull
2. Send the changes to all other servers ourselves from the **primary**

DNS chose the lightweight UDP notification way. It is easier and less expensive to send the updates to multiple servers, also some secondaries may not be ready to take up the transfer. It is also expensive to maintain the state of their secondaries in primary. In a pull architecture, the control is given to the **secondaries** on when and how it retrieves data. If its under heavy load it can defer pulling update (TCP based) and retry later based on timers.

This brings up a fresh challenge, you also need to know who holds the truth value, how to detect the changes , how frequently the secondaries should sync and discard outdated records.

The SOA or **Start Of Authority** record is created as a mandatory metadata for a zone to solve these problems. Its a special type of resource record and not a mere property of a zone. Defining SOA as a standard record (`TYPE = SOA`) allows DNS softwares like *bind*,*knot* to manage SOA metadata using the same mechanisms as other `A`, `MX`, or `TXT` records. Also this solves another problem, clients can query SOA record to find out `mname` (Master name) to send DDNS updates to.

E.g SOA for `shipmyproduct.com` may look like this:

```text
@   IN   SOA   ns1.shipmyproduct.com. admin.shipmyproduct.com. (
                   10         ; Serial number (32 bit serial)
                   3600       ; Refresh timer (1 hour)
                   900        ; Retry timer (15 minutes)
                   1209600    ; Expire timer (2 weeks)
                   300        ; Minimum / Negative Cache TTL (5 minutes)
             )
```

Coming back to our story, as soon as you update the zonefile, `SOA` serial gets incremented and the zone reload happens at the primary. Then it sends a `notify` UDP packet to the secondaries. Wait a second, how does primary know about secondaries? It notifies all the servers in the **NS Record set** (Nameserver records/NS RRsets, another record type like the `A` record) except the one listed in MNAME (that’s itself, so no need). Secondaries can also be listed in `also-notify` in DNS software. There’s a concept of hidden primaries/secondaries wherein the actual nameserver is kept hidden behind private network firewalls and is never exposed to public DNS traffic. In such cases `notify` will be used to send them the notification.

Secondaries get the `notify` event and asks the primary “whats your serial number?” If the serial number returned by the server is higher, secondary requests for **IXFR** ([Incremental transfer](https://www.rfc-editor.org/info/rfc1995/) UDP/TCP) with its serial number. Why **IXFR** ? There could be millions of records for a zone, its very expensive to send the full copy every time. So primary maintains an append only journal of all the changes with the operation performed (*.jnl file in case of bind*), the diff between the requested serial to its latest serial number present in SOA record can be easily generated from this log.

E.g. Journal entry may look like this in the primary.

```text
; Transaction: serial 10 -> 11

del shipmyproduct.com. 300 IN A    52.168.10.12
del shipmyproduct.com. 3600 IN SOA ns1.shipmyproduct.com. admin.shipmyproduct.com. 10 3600 900 1209600 300

add shipmyproduct.com. 3600 IN SOA ns1.shipmyproduct.com. admin.shipmyproduct.com. 11 3600 900 1209600 300
add shipmyproduct.com. 300 IN A    52.168.10.14
```

Secondaries get an **AXFR** ([Authoritative Transfer](https://www.rfc-editor.org/info/rfc5936/)) if primaries can’t form the history based on the input serial number or secondary doesn’t have an existing version to compare. Another case could be incremental changes is so large that its not wise to the send the changes. Then a primary returns the full copy of the zones containing all records to the caller.

What if the notification is lost or transfer fails ? There are essentially 3 parameters to control this

1. **Refresh:** How frequently a secondary server must poll the primary to check if the SOA `serial` has increased.
2. **Retry:** How long a secondary server waits before trying again if the primary server fails to respond during a SOA refresh check.
3. **Expire:** Defines the hard cutoff limit. If a secondary server cannot reach the primary server for this entire period (e.g. 2 weeks), it considers its local copy unreliable and stops answering queries for that zone.

At this point the secondaries are updated. What next? it hasn’t reached your customers yet. Globally there are several resolvers holding old value in their cache.

Resolvers (*e.g 8.8.8.8*) hold their records till the cache timeout. That is defined by the **Time-To-Live (TTL)** field associated to each Resource Record Set (RRset). In this case, `A` record. When you update the IP, you could update the TTL to smaller value if the IP changes are frequent, However it will come into picture from next updates. In addition to this, resolver level caching can be enforced too.

Viola! The proper IP goes to the browser, and finally the customer can access `shipmyproduct.com`

While we are here, we should discuss another important aspect of DNS: **DDNS (Dynamic DNS Update)**. Its not practical to update the IP manually especially, when the IPs are dynamic in nature controlled by a DHCP server. When the lease gets expired, DHCP leases the IP and wants to send an Update to primaries. In this case, it leverages Dynamic DNS updates mechanism when configured against a zone. In the above example, if the node gets the new IP `52.168.10.14` DHCP server lease can make the `DNS UPDATE()` call automatically and eliminate a human in the loop. This brings out security challenges, which will be discussed later.

Until next time.
