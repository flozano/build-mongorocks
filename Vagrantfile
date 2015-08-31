# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "puppetlabs/centos-7.0-64-nocm"
  config.vm.provider :virtualbox do |vb|
#    vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.1","1"]
#    vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.2","1"]
    vb.gui = true
    vb.memory = "1024"
  end

  config.vm.provision "shell", inline: <<-SHELL
    if [ ! -f "/etc/yum.repos.d/epel.repo" ]; then
      rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    fi

    yum -y install gcc gcc-c++ rpm-build glibc-devel.x86_64 libstdc++-devel.x86_64 boost.x86_64 git python-httplib2

    if [ ! -x "/usr/bin/scons" ]; then
      rpm -Uvh http://sourceforge.net/projects/scons/files/scons/2.3.6/scons-2.3.6-1.noarch.rpm/download
    fi
  SHELL

end
