# Install minisign

This can be used as a standalone script or inherited as a submodule. It will install [minisign](https://github.com/jedisct1/minisign) if it is not already installed. It will install from dnf if on a Fedora system or build minisign (and libsodium dependency) from source otherwise.

## USE

```bash
wget https://raw.githubusercontent.com/possiblynaught/install_minisign/master/install_minisign.sh
chmod +x install_minisign.sh
./install_minisign.sh
```

## TODO

- [x] Flip to static build flags or at least have option?
- [x] Verify libsodium lib signatures
