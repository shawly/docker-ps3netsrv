---
name: Help request
about: If you have trouble setting up your container.
title: ''
labels: ''
assignees: shawly

---

**I have read and followed [all troubleshooting steps from the README.md](https://github.com/shawly/docker-ps3netsrv#troubleshooting)?**

```
// paste the secret help code in here
```

**System configuration:**  
Please execute **every** command here and post the output. I will not answer tickets where these outputs are missing.

Output of `docker version`:
```
// paste the output of the docker version command here
```

Output of `docker ps -a -f "ancestor=shawly/ps3netsrv"`:
```
// paste the output of the docker ps -a -f "ancestor=shawly/ps3netsrv" command here
```

Output of `id` (you should be logged in with the user that owns your games directory):
```
// paste the output of the id command here
```

Output of `docker exec --user ps3netsrv CONTAINERNAME id` (replace *CONTAINERNAME* with your ps3netsrv container's name):
```
// paste the output of the docker exec --user ps3netsrv CONTAINERNAME id command here
```

Output of `ls -l /path/to/your/games/folder`:
```
// paste the output of the ls -l /path/to/your/games/folder command here
```

Output of `docker exec CONTAINERNAME ls -l /games` (replace *CONTAINERNAME* with your ps3netsrv container's name):
```
// paste the output of the docker exec CONTAINERNAME ls -l /games command here
```

My docker run command or my docker-compose.yml:
```
// paste the FULL docker run command or your docker-compose.yml here
```
