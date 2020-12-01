---
name: Help
about: If you still have trouble setting up your container.
title: ''
labels: ''
assignees: ''

---

**I have read and followed [all troubleshooting steps from the README.md](https://github.com/shawly/docker-ps3netsrv#troubleshooting)?**

```
// paste the secret help code in here
```

**System configuration:**
Output of `docker ps -a -f "ancestor=shawly/ps3netsrv"`:
```
// paste the output of the command here
```

Output of `id` (you should be logged in with the user that owns your games directory):
```
// paste the output of the command here
```

Output of `ls -l /path/to/your/games/folder`:
```
// paste the output of the command here
```

Output of `docker exec CONTAINERNAME ls -l /games` (replace *CONTAINERNAME* with your ps3netsrv container's name):
```
// paste the output of the command here
```

Output of `docker exec --user ps3netsrv CONTAINERNAME id` (replace *CONTAINERNAME* with your ps3netsrv container's name):
```
// paste the output of the command here
```
