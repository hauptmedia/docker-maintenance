# docker-maintenance

A maintenance docker container.

It spawns an ssh server which can be used to login and execute the
provided maintenance tools.

Provide a `maintenance-users` users file as `/etc/maintenance-users` with the format
`user` `ssh-key` to enable the ssh login for the specified user

Example maintenance-users file:

```
user1 ssh-rsa AAAAB3NzaC1yc2E.........
user2 ssh-rsa AAAAB3NzaC1yc2E.........
```

Example usage:

```bash
docker run -d -v /path/to/maintenance-users:/etc/maintenance-users -p2022:22 hauptmedia/maintenance
```
