Vagrant.configure("2") do |config|
    config.vm.define "macosx-test"
    config.vm.box = "yzgyyang/macOS-10.14"

    config.vm.synced_folder ".", "/vagrant", disabled: true

    config.vm.provider :virtualbox do |vb|
        vb.name = "macosx-test"
        vb.memory = 4096
        vb.cpus = 2
        vb.gui = false

        # Disable USB 3.0
        vb.customize ["modifyvm", :id, "--usb", "on"]
        vb.customize ["modifyvm", :id, "--usbxhci", "off"]

        # Some configs needed to get macOS to run on VirtualBox
        vb.customize ["modifyvm", :id, "--cpuid-set", "00000001", "000106e5", "00100800", "0098e3fd", "bfebfbff"]
        vb.customize ["modifyvm", :id, "--cpu-profile", "Intel Core i7-6700K"]
        vb.customize ["setextradata", :id, "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct", "MacBookPro11,3"]
        vb.customize ["setextradata", :id, "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion", "1.0"]
        vb.customize ["setextradata", :id, "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct", "Iloveapple"]
        vb.customize ["setextradata", :id, "VBoxInternal/Devices/smc/0/Config/DeviceKey", "ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"]
        vb.customize ["setextradata", :id, "VBoxInternal/Devices/smc/0/Config/GetKeyFromRealSMC", "1"]

        # set resolution on OSX:
        # 0,1,2,3,4,5 :: 640x480, 800x600, 1024x768, 1280x1024, 1440x900, 1920x1200
        vb.customize ["setextradata", :id, "VBoxInternal2/EfiGopMode", "4"]
    end

    $uninstall_homebrew = <<-SCRIPT
        curl -sLO https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh
        chmod +x ./uninstall.sh
        sudo ./uninstall.sh --force
        sudo rm -rf /usr/local/Homebrew
        sudo rm -rf /usr/local/Caskroom
        sudo rm -rf /usr/local/bin/brew
    SCRIPT

    # Uninstall the Homebrew that is in the VM before attempting setup
    config.vm.provision "Uninstall Homebrew", type:"shell",
        inline: $uninstall_homebrew

    # Upload ansible playbook from host to guest
    Dir.glob('**/*') do |filename|
        config.vm.provision "file", source: filename, destination: filename
    end

    config.vm.provision "Run Setup", type:"shell",
        env: {"IN_VAGRANT" => "true"},
        path: 'setup.sh', privileged: false
end