#Requires -RunAsAdministrator

####
# powershell -ExecutionPolicy ByPass -File get-trusted-roots.ps1
####

# TODO: Figure out how to change this based on whatever user
$workdir = "C:\Users\phil\Desktop\"

$outdir = ${workdir} + "extracted-certs\"
$sstfile = ${workdir} + "roots.sst"
$type = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert

If(!(test-path ${outdir})) {
  echo "Creating output directory: ${outdir}"
  New-Item -ItemType Directory -Force -Path ${outdir}
}

echo "Gathering SST file from Windows Update"
If(!(test-path ${sstfile})) {
  certutil -generateSSTFromWU ${sstfile}
} else {
  echo "Found existing SST file from Windows Update at: ${sstfile}"
}

echo "Building temporary CertStore from SST"
$file = (get-childitem -Path ${sstfile})
$file | import-certificate -CertStoreLocation cert:\LocalMachine\My

echo "Dumping extracted der files to ${outdir}"
$certs = get-childitem -path cert:\LocalMachine\My
foreach ($cert in $certs) {
  $hash = ${cert}.GetCertHashString()
  $outfile = ${hash} + ".der"
  $path = ${outdir} + ${outfile}
  [System.IO.File]::WriteAllBytes(${path}, ${cert}.export(${type}))
}
