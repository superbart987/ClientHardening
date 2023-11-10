#!/bin/sh


#######################################
#    Bart Rats          3-11-2023     #
#    Versie 0.1                       #
#    AutoLinuxHardening.sh            #
#######################################

#----------------------------------------------------------------------------------#
#  Door middel van dit script kan de linux client in 1 keer worden gehardend.      #
#----------------------------------------------------------------------------------#


#Menu Hardening onderdelen aanvinken
secureusers=0
firewall=0
ssh=0
updates=0
av=0
lock=0
encryption=0

#select menu
cmd=(dialog --separate-output --checklist "Select options:" 22 76 16)
options=(1 "Secure User" off    # any option can be set to default to "on"
         2 "Secure Firewall" off
         3 "Secure SSH" off
         4 "Automatic Updates" off
         5 "Anti Malware en Virus" off
         6 "Auto Lock" off
         7 "Add Ecryption" off)
         
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear
for choice in $choices
do
    case $choice in
        1)
            secureusers=1
            ;;
        2)
            firewall=1
            ;;
        3)
            ssh=1
            ;;
        4)
            updates=1
            ;;
        5)
            av=1
            ;;
        6)
            lock=1
            ;;
        7)
            encryption=1
            ;;
    esac
done
sleep 3

#Secure users
echo "Secure Users"
if [secureusers = 1]
then
    #add new user
    echo "wat wordt de naam van de nieuwe user?"
    read newuser
    adduser $newuser
fi
sleep 3

#setup firewall
echo "Firewall"
if [$firewall = 1]
then
    #install UFW firewall
    apt install ufw
    ufw enable
    ufw default deny incoming
    ufw default allow outgoing
fi
sleep 3

#SSH keys
echo "SSH"
if [$ssh = 1]
then
    case $yn in
                #create ssh key for selected user
        [Yy]* ) ssh-keygen -f /home/$newuser/.ssh/key$newuser. -t rsa ;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
    #disable password authentication for ssh
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
    sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
fi
sleep 3

#Automatic Updates
echo "updates"
if [$updates = 1]
then
    #install en setup automatic updates
    apt install unattended-upgrades apt-listchanges
    dpkg-reconfigure -plow unattended-upgrades
    sed -i 's/APT::Periodic::Update-Package-Lists "0";/APT::Periodic::Update-Package-Lists "1"/g' /etc/apt/apt.conf.d/20auto-upgrades
    sed -i 's/APT::Periodic::Unattended-Upgrade "0";/APT::Periodic::Unattended-Upgrade "1"/g' /etc/apt/apt.conf.d/20auto-upgrades
fi
sleep 3

#Malware en virus protection
echo "AV"
if [$av = 1]
then
    apt install clamav clamav-daemon clamav-freshclam
    service ClamAV-freshclam start
    sed -i 's/Checks 24/Checks 1/g' /etc/clamav/freshclam.conf
    freshclam -v
    #add scan to crontab voor iedere dag 5:00 scan /home
    crontab -u $(whoami) -l; echo "5 0 * * *  clamscan --recursive=yes --infected /home" ) | crontab -u $(whoami) -
fi
sleep 3

#Autolock
echo "Lock"
if [$lock = 1]
then
    echo "Na hoeveel seconden moet de client worden gelocked? Wij raden 120 tot 300 seconden aan."
    read locksec
    gsettings set org.gnome.desktop.screensaver lock-delay $locksec
fi
sleep 3

#Data Encryption
echo "Encryption"
if [$encryption = 1]
then
    apt install ecryptfs-utils rsync lsof
    echo 'modprobe ecryptfs' >> /etc/modules-load.d/modules.conf
    ecryptfs-migrate-home -u $newuser
    echo login op het account $newuser
    su $newuser
    echo sla de volgende passphrase extern op, voor eventuele recovery
    ecryptfs-unwrap-passphrase
fi
sleep 3

echo "het script is uitgevoerd en alle geselecteerde features zijn aangepast."
echo "Het systeem moet herstart worden"
sleep 10
reboot now