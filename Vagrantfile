# -*- mode: ruby -*-
# vi: set ft=ruby :
#
registry_host = ENV["REGISTRY_HOST"]
registry_org = ENV["REGISTRY_ORG"]
save_image_tarball = ENV["SAVE_IMAGE_TARBALL"]

$no_dirty_working_dir = <<-NODIRTYWD
# Avoid "fatal: detected dubious ownership in repository at '/home/vagrant/subspace-buildroot'"
git config --global --add safe.directory /home/vagrant/subspace-buildroot
pushd ~/subspace-buildroot/
echo "Checking for unstaged changes"
git diff --exit-code || exit
echo "Checking for staged, uncommited changes"
git diff --cached --exit-code || exit
popd
NODIRTYWD

$disable_snaps = <<-NOSNAPS
sudo systemctl disable --now snap.lxd.daemon.service snapd.service snapd.socket snapd.seeded.service || true
sudo systemctl mask snapd.service || true
NOSNAPS

$dist_upgrade = <<-DISTUPGRADE
sudo apt-get update
sudo apt-get dist-upgrade -y
DISTUPGRADE

$containers_in_tmpfs = <<-CNTTMPFS
grep -q /var/lib/docker /etc/fstab || { echo 'tmpfs   /var/lib/docker         tmpfs   rw,nodev,nosuid,size=14G          0  0' | sudo tee -a /etc/fstab ; }
sudo install -d -m0750 /var/lib/docker
sudo mountpoint -q /var/lib/docker || sudo mount /var/lib/docker
CNTTMPFS

$container_engine = <<-CNTENGINE
sudo apt-get install -y ca-certificates curl gnupg
[ -s /etc/apt/keyrings/docker.gpg ] || curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
[ -s /etc/apt/sources.list.d/docker.list ] || {
  echo "deb [arch="amd64" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
}
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
sudo usermod -aG docker vagrant
echo "{ \\"log-driver\\": \\"local\\", \\"insecure-registries\\" : [ \\"localhost:4000\\" ] }" | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
sudo systemctl disable docker containerd # tmpfs
CNTENGINE

$container_registry = <<-CNTREGISTRY
[ "$(docker ps --filter name=registry --filter status=running --format '{{.State}}')" == "running" ] ||
 { docker run -d --network host --name registry --restart=always -e REGISTRY_HTTP_ADDR=0.0.0.0:4000 -v registry:/var/lib/registry registry:2 ; }
CNTREGISTRY

$subspacebuild = <<-SUBSPACEBUILD
cd ~/subspace-buildroot/
export GIT_COMMIT_DESCRIBED=$(git describe --tags HEAD)
TZ=UTC docker build -t $1/$2/subspace:amd64-${GIT_COMMIT_DESCRIBED}-$(TZ=UTC date +%Y%m%d-%H%M%Z) .
if [ "$3" == "true" ] ; then
  TAG="$(docker image ls --format "{{.Tag}}" -f "reference=$1/$2/subspace")"
  docker image save "$1/$2/subspace:$TAG" | zstd -T0 -c > "./${2}-subspace-${TAG}.tar.zst"
fi
SUBSPACEBUILD

Vagrant.configure("2") do |config|
  config.vm.box = "bento-ubuntu-22.04-amd64"

  config.vm.box_check_update = false

  config.vm.network :private_network, :type => "dhcp"

  config.vm.synced_folder "./", "/vagrant", disabled: true

  config.vm.provider "libvirt" do |lv|
    lv.cpus = 8
    lv.memory = "12288"
    lv.machine_virtual_size = 40
  end
  config.vm.synced_folder "./", "/home/vagrant/subspace-buildroot", type: "sshfs"

  config.vm.provision "shell", inline: "sudo lvextend -r -l +100%FREE ubuntu-vg/ubuntu-lv", privileged: false
  config.vm.provision "shell", inline: $no_dirty_working_dir, privileged: false
  config.vm.provision "shell", inline: $disable_snaps, privileged: false
  config.vm.provision "shell", inline: $dist_upgrade, privileged: false
  config.vm.provision :reload
  config.vm.provision "shell", inline: $containers_in_tmpfs, privileged: false
  config.vm.provision "shell", inline: $container_engine, privileged: false, reset: true
  config.vm.provision "shell", inline: $container_registry, privileged: false
  config.vm.provision "shell", inline: $subspacebuild, privileged: false, args: [registry_host, registry_org, save_image_tarball]
end
