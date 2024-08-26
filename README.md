# **Mempool.Space Dockerized** 

**Simple implementation of mempool within docker**

## 🔍 About the project

One click ready to run mempool integration for home users. The project exposes multiple websites on different ports.

Those are:

| Site | Port |
| --- | --- |
| `mempool` | 8080 |
| `lnbits` | 5000 |
| `thunderhub` | 3000 |



This project is designed to run on environments with low hardware. Keep in mind that `bitcoind` is downloading the whole blockchain so your storage should be at least 1TB.

***This is basically the same as my other github project but this one gives a bit more insight in whats happening because it compiles everything on the host.***

While testing i ran it on 2 cores and 2GB of RAM and 
it worked fine.

***Keep in mind that compiling will take a long time depending on the machine you are using. On my 16C host it took about half an hour***

Can be run on ``x86/64`` and ``arm64``




The project also exposes metrics via prometheus about `bitcoind`and `lnd` on port `3001`and `9092`




## ⚙️ Configuration

### Install dependencies:

```bash
$ apt-get install docker.io docker-compose git -y
```

### Clone repository onto the machine:

```bash
$ git clone https://github.com/pxrzival/mempool-dockerized-v2.git
```

### cd into the repository:

```bash
$ cd mempool-dockerized-v2
```

### Change password in the `.env` file:
```bash
# Open .env file
nano .env
# Look for the parameters to change
```

### Run docker compose:
```bash
$ docker compose up -d
```

### Initialize LND once

```bash
$ docker compose exec -it lnd /bin/sh
# You now opened up a shell within the LND container

    $ lncli create 
    # You will be prompted to choose a password. Chose one and also save it within the .lndpass file.
    # LND needs the password saved in a file
```
### Restart the project once

```bash
$ docker compose restart
```


