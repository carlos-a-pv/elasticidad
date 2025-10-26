@echo off

:: Crear la máquina virtual 
VBoxManage createvm --name "servidor4" --ostype Debian_64 --register
VBoxManage modifyvm "servidor4" --memory 2048 --vram 12 --cpus 1
VBoxManage modifyvm "servidor4" --nic1 bridged --bridgeadapter1 "Realtek PCIe FE Family Controller"
VBoxManage storagectl "servidor4" --name "SATA Controller" --add sata --bootable on
VBoxManage storageattach "servidor4" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "C:\Users\carlos.perez\VirtualBox VMs\servidor1.vdi"
VBoxManage startvm "servidor4"

:: Esperar 2 minutos para que la VM arranque y obtenga una IP vía DHCP
echo Waiting for the VM to boot up and obtain an IP address...
timeout /t 40 /nobreak

for /L %%i in (100,1,120) do ping -n 1 -w 10 192.168.1.%%i > nul


::Obtener la IP asignada a la VM
for /f "tokens=4 delims= " %%A in ('VBoxManage showvminfo servidor4 ^| findstr "MAC"') do (
    set "MAC_RAW=%%A"
)

rem Quitar la coma final (porque sale como 080027684F8B,)
set "MAC=%MAC_RAW:,=%"

::formatear la MAC para que coincida con el formato de arp -a
for /f "delims=" %%F in ('powershell -NoProfile -Command "('%MAC%' -replace '(.{2})','$1-').TrimEnd('-').ToLower()"') do set "MAC_FMT=%%F"

arp -a | findstr /i %MAC_FMT% > ip.txt


:: Copiar el archivo ip.txt al balanceador
scp ip.txt carlos@192.168.0.107:.

:: conectar via ssh a la VM y configurar el HAPROXY
ssh carlos@192.168.0.107:.

echo "server servidor4 $(awk '{print $1}' ip.txt)" >> /etc/haproxy/haproxy.cfg
sudo systemctl restart haproxy
exit




