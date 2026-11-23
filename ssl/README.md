# ssl

## ssl_pfx_to_crt.sh

Splits a `.pfx` / `.p12` file (the format Windows, IIS and most certificate portals export)
into the separate PEM files that Linux web servers, load balancers and appliances want.

For each `NAME.pfx` it writes:

| File | Contents |
|---|---|
| `NAME.crt` | The server certificate |
| `NAME.key` | The private key, **unencrypted**, readable only by you (mode 600) |
| `NAME.chain.crt` | The intermediate / CA certificates, if the pfx includes them |
| `NAME.fullchain.crt` | Certificate followed by the chain, for nginx, HAProxy and similar |

The server certificate is the one that matches the private key, so it doesn't matter
in which order the pfx stores the certificates. The PEM files are clean, without the
`Bag Attributes` lines that `openssl pkcs12` adds.

### Requirements
`openssl`. Works with the LibreSSL in macOS (`/usr/bin/openssl`), OpenSSL 1.1, and
OpenSSL 3 or later. With OpenSSL 3+, older pfx files that use RC2 / 3DES encryption
are opened with `-legacy` automatically.

### Usage
```bash
ssl_pfx_to_crt.sh [-o dir] [-f] file.pfx [file2.p12 ...]
```

| Option | Meaning |
|---|---|
| `-o dir` | Write the files to `dir` (default: next to each input file) |
| `-f` | Overwrite existing output files (by default the script stops rather than overwrite) |

The import password is asked once per file. For scripting, set it in the `PFX_PASSWORD`
environment variable instead; it is passed to openssl through the environment, never on
the command line where other users could see it in `ps`.

Exit codes: `0` ok, `1` bad usage, `2` at least one file failed (wrong password, not a pfx...).

### Example
```
$ ./ssl_pfx_to_crt.sh www.example.com.pfx
== www.example.com.pfx
   import password (empty for none):
   subject  CN=www.example.com
   expires  Dec 22 21:32:47 2026 GMT
   wrote    ./www.example.com.crt, ./www.example.com.key, ./www.example.com.fullchain.crt
            ./www.example.com.chain.crt (2 CA certificate(s))
```

The `.key` file is not password protected. Move it to the server and delete the local
copy when you're done.
