# Bind9


> BIND 9 has evolved to be a very flexible, full-featured DNS system. 
> Whatever your application is, BIND 9 probably has the required features. 
> As the first, oldest, and most commonly deployed solution, there are more 
> network engineers who are already familiar with BIND 9 than with any other system.

[Link](https://www.isc.org/bind/)

## After Setup Steps

1. Go to your router's homepage (`192.168.1.1` or similar) and setup K8S node IP as DNS server.

    > Replace all DNS servers with K8S node IP to force all DNS resolution to perform the `Bind9 > Pihole` chain.
