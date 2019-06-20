# Overview

[CT](http://www.certificate-transparency.org/what-is-ct) [log operators](https://www.youtube.com/watch?v=v39VIqULPzA) must maintain a list of certificates that the log will accept submissions from - the accepted roots list. This project will hopefully help _someone_ gather these certs for their log. For an easier to use project, [see this one](https://github.com/PeculiarVentures/tl-create/).

- - - -
# Known CT log programs

* [Apple](https://support.apple.com/en-om/HT209255)
* [Chromium](https://github.com/chromium/ct-policy)

- - - -
# Acquire certificates

### Let's Encrypt Staging Environment Intermediate

```
wget https://letsencrypt.org/certs/fakeleintermediatex1.pem
```

### Google Maximum Merge Delay (MMD) monitor

```
wget https://raw.githubusercontent.com/chromium/ct-policy/master/mmd_monitor_root.crt
```

### Mozilla NSS

[](https://curl.haxx.se/docs/caextract.html)

```
curl --remote-name --time-cond cacert.pem https://curl.haxx.se/ca/cacert.pem
sed -n '/-BEGIN CERTIFICATE/,/-END CERTIFICATE-/p' cacert.pem > mozilla-root-store.bundle
```

### Apple

Apple does not make it easy on the log operator by providing a certificate bundle. We'll be building this certificate bundle ourselves. Download the HTML which contains fingerprints of all the certificates that Apple requires the CT log to allow submssions from. We'll be comparing the fingerprints to what we extract from an OSX root store just to be sure.

On an up to date OSX device, open the Keychain app and drag all the system root certificates into a folder. This will export them all as individual files in DER format
Compress the certs and transfer them to a Qubes VM
```
unzip apple-certs.zip
```

Compare the fingerprints that Apple lists at
If something is jacked up, try `export IFS=$'\n'`
```
find -type f -name '*.cer' -exec openssl x509 -inform der -in '{}' -noout -fingerprint -sha256 \; | sed -e 's/SHA256 Fingerprint=//g' -e 's/:/ /g' > fingerprints.txt
for i in $(cat fingerprint.txt); do grep "${i}" ../apple-trusted-list.html > /dev/null ; if [ $? -ne 0 ]; then echo "Fingerprint ${i} was not found in the trusted list. Remove this certificate."; fi; done
```

To find any certificates that the previous command complained about (if any)
```
find -type f -name '*.cer' -print -exec openssl x509 -inform der -in '{}' -noout -fingerprint -sha256 \; | sed -e 's/SHA256 Fingerprint=//g' -e 's/:/ /g' | less
```

Remove any certificate that isn't found in the trusted list
```
rm -f whatever.cer
```

Convert the DER formatted certs to PEM
```
find -type f -name '*.cer' -exec openssl x509 -inform der -in '{}' -outform pem -out '{}.pem' \;
```

Bundle all the Apple trusted root certs
```
cat *.cer.pem > apple-trusted-roots.bundle
```

### Windows

Run the powershell script located in `windows` on an up to date Windows server. After that, zip the certs up, transfer them to your Linux box, and finally continue processing them. You'll end up with ~395 (as of this writing) PEM formatted certs.
```
unzip windows-certs.zip
mkdir -p windows-certs
cd windows-certs
for i in *.der; do openssl x509 -inform der -in ${i} -outform pem -out ${i%%.*}.pem; done
rm -f *.der
```

- - - -
# Generate the accepted roots file

Combine all the disparate files into a single file
```
cat mmd_monitor_root.crt mozilla-root-store.bundle apple-trusted-roots.bundle windows-certs/*.pem > accepted-roots.pem
```

Get the [c_rehash](http://manpages.ubuntu.com/manpages/trusty/man1/c_rehash.1ssl.html) utility
```
sudo dnf install -y openssl-perl
```

```
mkdir certs
cp accepted-roots.pem certs/
cd certs
awk 'BEGIN {c=0;} /BEGIN CERT/{c++} { print > "cert." c ".pem"}' < accepted-roots.pem
c_rehash -v .
cat *.[0-9] > final-accepted-roots.pem
```

Gather information about the unique certs
```
ls -al *.[0-9] | wc -l
find . -type l -name '*\.[0-9]' -exec openssl x509 -in {} -noout -subject -fingerprint -sha256 \;
```

- - - -
# Get root list from another log
This part has some extra handling due to https://github.com/openssl/openssl/issues/9187
```
for cert in $(curl -s "https://testflume.ct.letsencrypt.org/2019/ct/v1/get-roots" | jq -r '.certificates | .[]' | sort | uniq); do echo -e "-----BEGIN CERTIFICATE-----\n${cert}\n-----END CERTIFICATE-----" >> accepted-roots.pem; done
fold --spaces --width=64 accepted-roots.pem > accepted-roots.folded.pem
mv accepted-roots.folded.pem accepted-roots.pem
awk 'BEGIN {c=0;} /BEGIN CERT/{c++} { print > "cert." c ".pem"}' < accepted-roots.pem
for cert in cert*.pem; do openssl x509 -in ${i} -noout -subject; done
```

- - - -

# Music
[Pine Hill Haints - Jack o' Diamonds](https://serioussambarrett.bandcamp.com/track/jack-o-diamonds)
