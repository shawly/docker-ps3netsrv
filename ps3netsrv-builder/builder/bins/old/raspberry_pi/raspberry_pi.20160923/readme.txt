--------------------------------------
Using Raspberry Pi As Streaming Device
--------------------------------------

----------------------------------------------------------------------------------------------
SECTION 1: Using Raspberry Pi with installed OpenElec-OS as a Streaming Device for webMAN & Co
----------------------------------------------------------------------------------------------

(Note: If you use Raspbian-OS scroll down to SECTION 2)

A) Preparations

  A1) Format USB-HDD with NTFS and create a folder named "PS3NETSRV" in it's root directory
  A2) Inside "PS3NETSRV" create these folders: "BDISO", "DVDISO", "GAMES", "PS3ISO", "PSPISO", "PSXISO" and fill them with your games and videos.
  A3) Put SD-Card back into your Pi > Connect USB-HDD with Pi > Start Pi 
  A4) Exemplary assumption:
  ___ Router-IP: 192.168.1.1 (check what's your Router-IP)
  ___ selected Pi-IP: 192.168.1.123 (the last number must be in the range of 2-254)
  A5) Go to "System > OpenElec > Connections > Edit > IPv4" and set it up like this (change the values to yours (see A4)):

IP Address Method: Manual
IP Address: 192.168.1.123
Subnet Mask: 255.255.255.0
Default Gateway: 192.168.1.1

  A6) Use "SAVE"-button to save these settings
  A7) Go to "System > OpenElec > Services" and activate 'Samba' and 'Auto-share external drives'
  A8) Go to "System > Settings > Services" and set 'Settings level' to 'Advanced' or 'Expert'
  A9) Go to "System > Settings > Services > SMB client" and set 'Workgroup' to the same as your PC
  A10) Reboot Openelec
  A11) Enter "\\192.168.1.123" in address-bar of windows explorer and u should see the shared folders of Openelec and the connected USB-HDD
  A12) Download and extract "ps3netsrv-pi" -> copy "ps3netsrv" to the shared "Userdata"-folder

B) Install "ps3netsrv" and make it autostart

  B1) Use 'Putty' (or another SSH client) to login to Openelec (IP=192.168.1.123 / Login=root / password=openelec)

    B2) Enter "cd /media"
    B3) Enter "ls" and you should see your USB-HDDs name. Note it ! (for me it's 'sdb1-ata-TOSHIBA_MQ01ABB2' and i'll use it further on in the tutorial as an example)
    B4) Enter "nano /storage/.config/autostart.sh"
    B5) Copy & Paste the following code (replace 'sdb1-ata-TOSHIBA_MQ01ABB2' with your USB-HDDs name (see B3)):

(
/storage/.kodi/userdata/ps3netsrv /media/sdb1-ata-TOSHIBA_MQ01ABB2/PS3NETSRV 38008
) &

  B5) Press CTRL-X -> answer the following question with Y -> press ENTER
  B6) Enter "reboot"

C) webMAN-Configuration

  C1) At PS3 go to "webMAN-settings" -> Check "Activate Streaming at PS3NETSRV#x" -> Enter '192.168.1.123' next to it -> Reboot PS3.
  C2) If u can't see your games/vidoes under "MyGames" do a XML-Scan and/or raise time settings in webMAN-settings

D) Updating 'ps3netsrv'

  D1) Copy new "ps3netsrv"-version to the shared "Userdata"-folder (see A11/A12)
  D2) Reboot Openelec


Notes:
- Because the system-filesystem of Openelec is 'read-only' we can't simply place 'ps3netsrv' in '/usr/local/bin' like we do in SECTION 2.
_ Therefore i've choosed '/storgage/.kodi/userdata' as an (not perfect) alternative.
- If you see more then one possible USB-HDDs name in step B3 (because your USB-HDD has more than 1 partition or there are other USB-devices connected to Pi) and you are not sure whats the correct one, then us "cd [name]" and then "ls" to find "PS3NETSRV" folder. If you've found it use [name] in B5

******************************************************
* PLEASE ALSO READ THE NOTES AT THE END OF THIS POST *
******************************************************

----------------------------------------------------------------------------------------------
SECTION 2: Using Raspberry Pi with installed Raspian-OS as a Streaming Device for webMAN & Co
----------------------------------------------------------------------------------------------

A) Prepare and auto-mount your USB-HDD

  A1) Format USB-HDD with NTFS and create a folder named "PS3NETSRV" in it's root directory
  A2) Inside "PS3NETSRV" create these folders: "BDISO", "DVDISO", "GAMES", "PS3ISO", "PSPISO", "PSXISO" and fill them with your games and videos.
  A3) Connect USB-HDD to Pi and start Pi to command shell

    A4) Enter "sudo apt-get install ntfsprogs" and answer any questions with Y 
    A5) Enter "ls -l /dev/disk/by-uuid/" (= list devices with their unique UUID)
    A6) Note UUID of your USB-HDD (it's the number in blue in the line with "sdax" )
    A7) Enter "sudo mkdir /media/usbhdd" (=create a mountpoint)
    A8) Enter "sudo chown -R pi:pi /media/usbhdd" (=Set user 'pi' as owner)
    A9) Enter "sudo nano /etc/fstab" (=open file "fstab" in editor)
    A10) Append line "UUID=1234-5678 /media/usbhdd ntfs,users,rw,uid=pi,gid=pi 0 0" (change '1234-5678' to your UUID from step A6)
    A11) Press CTRL-X -> answer the following question with Y -> press ENTER
    A12) Enter "sudo reboot" (=Pi Restart)


B) Install "ps3netsrv" and make it autostart

  B1) Shutdown Pi -> Put Pi's SD-Card in PC's SD-Card-Reader and open it in Windows-Explorer
  B2) Download and extract "ps3netsrv-pi" -> copy "ps3netsrv" to the root of SD-Card
  B3) Move SD-Card back to Pi and start pi to command shell

    B4) Enter "sudo cp /boot/ps3netsrv /usr/local/bin/"
    B5) Enter "chmod +x /usr/local/bin/ps3netsrv"  (=make it executeable)
    B6) Enter "sudo apt-get install systemd" and answer any questions with Y 
    B7) Enter "sudo nano /boot/cmdline.txt" 
    B8) Append "init=/bin/systemd" to the end of the line
    B9) Press CTRL-X -> answer the following question with Y -> press ENTER
    B10) Enter "sudo reboot" -> wait for reboot to finish -> Login to command shell
    B11) Enter "cd /etc/systemd/system" (=change directory)
    B12) Enter "sudo nano ps3netsrv.service" (create file 'ps3netsrv.service' and open it in editor)
    B13) Add the following code:


[Unit]
Description = Starts instance of ps3netsrv
After = remote-fs.target

[Service]
Type = simple
ExecStart = /usr/local/bin/ps3netsrv /media/usbhdd/PS3NETSRV 38008
Restart = always

[Install]
WantedBy = multi-user.target


    B14) Press CTRL-X -> answer the following question with Y -> press ENTER
    B15) Enter "sudo systemctl start ps3netsrv.service"
    B16) Enter "sudo systemctl enable ps3netsrv.service"
    B17) Enter "sudo reboot"


C) Fixed IP for Pi and webMAN-configuration

  C1) Exemplary assumption:
  ___ Router-IP: 192.168.1.1 (check what's your Router-IP)
  ___ selected Pi-IP: 192.168.1.123 (the last number must be in the range of 2-254)
  C2) Enter Pi's command shell

    C3) Enter "sudo nano /etc/network/interfaces" (open file 'interfaces' in editor)
    C4) Change line "iface eth0 inet manual/dhcp" to ('address'=selected Pi-IP / gateway=Router-IP (see C1)):

iface eth0 inet static
address 192.168.1.123
netmask 255.255.255.0
gateway 192.168.1.1

  C5) Press CTRL-X -> answer the following question with Y -> press ENTER
  C6) Enter "sudo reboot"

  C7) webMAN-settings -> Check "Activate Streaming at PS3NETSRV#x" -> Enter '192.168.1.123' next to it -> Reboot PS3.
  C8) If u can't see your games/vidoes under "MyGames" do a XML-Scan and/or raise time settings in webMAN-settings


D) Create a SMB-Share for your USB-HDD

  D1) Goto Pi's command shell

    D2) Enter "sudo apt-get install samba samba-common-bin" and answer any questions with Y
    D3) Enter "sudo nano /etc/samba/smb.conf"
    D4) Scroll down and change 'WORKGROUP' in line "workgroup = WORKGROUP" to the workgroup of your PC
    D5) Scroll further down and remove '#' in line "#   security = user"
    D6) At the end append this code:

[PS3NETSERV]
comment = My shared PS3 net server directory
path = /media/usbhdd/PS3NETSRV
writeable = yes
guest ok = no

    D7) Press CTRL-X -> answer the following question with Y -> press ENTER
    D8) Enter "sudo smbpasswd -a pi" and enter a password of your choise for your smb-share ('pi' is the smb-share-user... u can change it if u like)
    D9) Enter "sudo /etc/init.d/samba restart"

  D10) Open Windows Explorer and enter either "\\192.168.1.123"(see C1) or "\\RASPBERRYPI" at address bar
  D11) Enter smb-share-user and your password (see D8) and check checkbox to save your login data
  D12) [optional] Right-click "ps3netsrv", select "Connect Net Drive" and confirm

E) Updating 'ps3netsrv'

  E1) Copy new version of "ps3netsrv" to the root of SD-Card > Fire up Pi > Enter command shell
  E2) Enter "cd /etc/systemd/system"
  E3) Enter "sudo systemctl stop ps3netsrv.service"
  E4) Enter "sudo cp /boot/ps3netsrv /usr/local/bin/"
  E5) Enter "chmod +x /usr/local/bin/ps3netsrv"
  E6) Enter "sudo reboot"


Notes:
- Even it works on a Pi1 it is in fact a bit to powerless for a good streaming performance. I recoomend using a Pi2.
- U could also fomat ur USB-HDD in ext3/ext4/FAT32 (for Raspian-OS: change 'ntfs' in A10) to 'ext3', 'ext4', 'vfat' accordingly)
- If u try to use an 2,5" HDD on Pi B+ or Pi2 add "max_usb_current=1" to "config.txt"(on root of SD-Card) but make sure your Pi's power supply has at least 2A


---------------------------
How to compile it yourself:
---------------------------
1. Download latest ps3netsrv-source from http://github.com/aldostools and replace the 'makefile' with the one from 'ps3netsrv-pi'
2. Start latest 'Raspbian Jessie Lite' and update it via "sudo apt-get update" and "sudo apt-get upgrade"
3. Enter "sudo apt-get install ntfs-3g" (if u need ntfs support)
4. Copy over the folder with the source files from step 1 over to '/home/pi/'-directory (i recommend 'WinSCP' for this task)
5. Enter "cd /home/pi/ps3netsrv-pi"
6. Enter "make" (this will create the 'ps3netsrv' executable inside 'cd /home/pi/ps3netsrv-pi')

I've tried it on a Pi 3 and compared it to the ps3netsrv on my NAS: It performs with about 50% of the NAS-speed.
(I've installed a 500MB PKG over network and compared the install-times)
It's not that great... but i guess at least it's useable.
May be performance can be increased using a EXT4 formatted USB-device... i didn't check this !
If anyone tries this pls let us know the results !


Regards

Rudi Rastelli
