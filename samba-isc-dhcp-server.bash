#!/bin/bash

#Примечание для портфолио: операторы, производящие работы на территории клиентов, для удобства обладают доступом к общей папке, где хранятся все остканированные копии документов.
#Поскольку чаще всего по окончании работ все хранилища исполнителя подлежат форматированию (согласно ТЗ), возникла необходимость часто разворачивать файловый сервер.
#С целью экономии моего времени как сотрудника и был написан этот скрипт. Он предназначен для простой настройки сервера Samba, с учётом того, что в офисе заказчика всё рабочее оборудование не будет иметь выход в Интернет.
#Скрипт запрашивает данные для создания файлового сервера, а затем устанавливает и настраивает его в соответствии с параметрами пользователя.

clear

echo -e "\033[1mЗдравствуйте. Данный скрипт используется для быстрой настройки файлового сервера Samba и DHCP-сервера isc-dhcp-server.\033[0m"
echo -e "\033[1mПожалуйста, введите запрашиваемые данные.\033[0m"

echo 

#Первым действием выводится запроос на ввод переменной server (IP-адреса настраиваемого сервра). При вводе данных в переменную server осуществляется проверка - пользователю необходимо ввести переменную servervalidation, чтобы подтвердить значение ("$servervalidation" != "$server"). 
#Эта проверка нацелена на исключение шанса опечатки. Проверка на ввод пустого значения или значения или значения, отличного от IP-адреса, не добавлена т.к. предполагается, что работающий со скриптом человек достаточно компетентен, чтобы не допускать подобных ошибок.
#*Здесь и далее под "действиями" подразумеваются этапы, наблюдаемые пользователем скрипта
printf "Введите локальный адрес сервера: " 
read -r server
printf "Подтвердите локальный адрес сервера: "
read -r servervalidation
 while [[ "$servervalidation" != "$server" ]]; do 
  echo
  echo -e "\033[1;1;31mУказанные адреса не совпадают. Введите повторно: \033[0m"
  echo
   printf "Введите локальный адрес сервера: "
    read -r server
   printf "Подтвердите локальный адрес сервера: "
    read -r servervalidation
done

#Вторым действием выводятся два запроса - на ввод первого и последнего IP-адреса DHCP-пула

#Сперва определяется последний октет IP-адреса сервера, чтобы исключить шанс на его включение в пул DHCP - выводится значение переменной (адрес), после чего порсдетсвом awk выделяется последний октет адреса и вносится в переменную $serverlsatoct
serverlastoct=`echo "$server" | awk -F '.' '{print $NF; exit}'`

echo

#Далее запрашивается значение первого адреса пула DHCP. Производится проверка на наличие опечаток ("$firstaddr" != "$firstaddrvalidation"), затем проверяется, не равен ли первый адрес DHCP-пула адресу сервера ("$firstaddr" = "$server")
#Далее проверяется, не меньше ли указанный первый адрес пула чем адрес сервера ("$firstaddrlastoct" -lt "$serverlastoct"). Если одно из условий не совпадает, начинается цикл while, в ходе которого переменная первого адрес пула вводится пользователем заново
echo "Пожалуйста, укажите диапазон пула DHCP"
echo
printf "Введите первый адрес пула: "
read -r firstaddr
printf "Подтвердите первый адрес пула: "
read -r firstaddrvalidation
firstaddrlastoct=`echo "$firstaddr" | awk -F '.' '{print $NF; exit}'`
while [[ "$firstaddr" != "$firstaddrvalidation" ]] || [[ "$firstaddr" = "$server" ]] || [ "$firstaddrlastoct" -lt "$serverlastoct" ]; do
 echo
 echo -e "\033[1;1;31mВведённые адреса не совпадают или первый адрес пула включает в себя адрес сервера. Введите повторно\033[0m"
 echo
  printf "Введите первый адрес пула: "
   read -r firstaddr
  printf "Подтвердите первый адрес пула: "
   read -r firstaddrvalidation
   firstaddrlastoct=`echo "$firstaddr" | awk -F '.' '{print $NF; exit}'`
done

echo

#Далее запрашивается значение последнего адреса пула DHCP. Проверка ввода данных аналогична проверке при вводе первого адреса пула
#Как и при вводе переменной $server, не осуществляется проверка на ввод пустого значения
#Следует отметить, что согласно проверкам  "$firstaddrlastoct" -lt "$serverlastoct" и "$lastaddrlastoct" -lt "$serverlastoct" пул не может начинаться с адреса, меньше адреса сервера, что теоретически может создать ситуацию, когда пул будет недостаточного размера (например, если адрес сервера равен 192.168.1.254)
#Как и в случае с проверкой на ввод пустого значение, предполагается, что администратор достаточно компетентен, чтобы не допустить подобную ошибку
printf "Введите последний адрес пула: "
read -r lastaddr
printf "Подтвердите последний адрес пула: "
read -r lastaddrvalidation
lastaddrlastoct=`echo "$lastaddr" | awk -F '.' '{print $NF; exit}'`
while [[ "$lastaddr" != "$lastaddrvalidation" ]] || [[ "$lastaddr" = "$server" ]] || [ "$lastaddrlastoct" -lt "$serverlastoct" ]; do
 echo
 echo -e "\033[1;1;31mВведённые адреса не совпадают или первый адрес пула включает в себя адрес сервера. Введите повторно\033[0m"
 echo
  printf "Введите последний адрес пула: "
   read -r lastaddr
  printf "Подтвердите последний адрес пула: "
   read -r lastaddrvalidation
   lastaddrlastoct=`echo "$lastaddr" | awk -F '.' '{print $NF; exit}'`
done
 
echo

#Третим действием выводится запрос на ввод наименования директории Samba. Проверка введенной переменной осуществляется аналогично с проверкой переменной $server
printf "Введите наименование директории, с которой будут работать операторы: "
read -r directory
printf "Подтвердите наименование директории: "
read -r directoryvalidation
 while [[ "$directoryvalidation" != "$directory" ]]; do
  echo
  echo -e "\033[1;1;31mУказанные наименования не совпадают. Введите повторно: \033[0m"
  echo
   printf "Введите наименование директории: "
    read -r directory
   printf "Подтвердите наименование директории: "
    read -r directoryvalidation
done

echo

#Четвертым действием выводится запрос на ввод имени пользователя Samba. Проверка введенной переменной осуществляется аналогично с проверкой переменнх $server и $directory
printf "Введите имя пользователя для подключения к папке: "
read -r user
printf "Подтвердите имя пользователя: "
read -r uservalidation
 while [[ "$uservalidation" != "$user" ]]; do
  echo
  echo -e "\033[1;1;31mУказанные имена пользователя не совпадают. Введите повторно: \033[0m"
  echo
   printf "Введите имя пользователя: "
    read -r user
   printf "Подтвердите имя пользователя: "
    read -r uservalidation
done

echo

#Пятым действием выводится запрос на ввод имени пользователя Samba. Проверка введенной переменной осуществляется аналогично с проверкой переменнх $server, $directory и $user
printf "Ведите пароль пользователя для подключения к папке: "
read -r password
printf "Подтвердите пароль пользователя: "
read -r passwordvalidation
 while [[ "$passwordvalidation" != "$password" ]]; do
  echo
  echo -e "\033[1;1;31mУказанные пароли пользователя не совпадают. Введите повторно: \033[0m"
  echo
   printf "Введите пароль пользователя: "
    read -r password
   printf "Подтвердите пароль пользователя: "
    read -r passwordvalidation
done

echo

echo -e "\033[1mПроизводится установка и настройка сервисов. Пожалуйста, подождите...\033[0m"

#На данном этапе и практически до конца скрипта вывод команд подавляется $>/dev/null из эстетических соображений

#В список репозиториев добавляются репозитории Yandex, поскольку предполагается, что настройка сервера будет производится при подключении к Интернету
cat << End_Mess > /etc/apt/sources.list

deb http://mirror.yandex.ru/debian/ bullseye main
deb-src http://mirror.yandex.ru/debian/ bullseye main

deb http://mirror.yandex.ru/debian-security bullseye-security main contrib
deb-src http://mirror.yandex.ru/debian-security bullseye-security main contrib

deb http://mirror.yandex.ru/debian/ bullseye-updates main contrib
deb-src http://mirror.yandex.ru/debian/ bullseye-updates main contrib

End_Mess

#Устанавливаются пакеты samba и isc-dhcp-server, необходимые для работы файлового и DHCP-сервера соответственно
apt update &>/dev/null
apt install samba isc-dhcp-server -y &>/dev/null

#Производится настройка сетевого интерфейса - IP-адрес сервера задается из переменной $server
cat << End_Mess > /etc/network/interfaces

auto lo
iface lo inet loopback

auto ens33
iface ens33 inet static
address $server
netmask 255.255.255.0

End_Mess

#Перезапускается служба networking.service для обновления параметров сетевого интерфейса. В Debian встречатся баг, из-за которого после однократного перезапуска этой службы адрес обновляется, однако вывод ifconfig некорректен - проблема решается двойным перезапуском службы
systemctl restart networking.service &>/dev/null
systemctl restart networking.service &>/dev/null

#Удаляются все маршруты, кроме того, что соответствует рабочей сети. В дальнейшем результаты вывода команд ip route и ifconfig будут использоваться для ввода данных в переменные
ip route del default
ip route flush cache
oldroute=`ip route | grep metric`
ip route del $oldroute

#Производится настройка первого конфигурационного файла DHCP - указывается интерфейс, через который будет осуществляться раздача адресов
cat << End_Mess > /etc/default/isc-dhcp-server

DHCPDv4_CONF=/etc/dhcp/dhcpd.conf
DHCPDv4_PID=/var/run/dhcpd.pid
INTERFACESv4="ens33"

End_Mess

#Переменным $broadcast и $subnet назначаются значения из вывода команд ifconfig и ip route. Вывод команд "обрезается" командами awk и cut таким образом, чтобы в переменные не вносились лишние символы
broadcast=`ifconfig | grep broadcast | awk -F 'broadcast' '{print $NF; exit}' | awk '{print $1}'`
subnet=`ip route | cut -d' ' -f1 | rev | cut -c 4- | rev`

#Производится настройка второго конфигурационного файла DHCP - указывается адрес сервера из переменной $server, действующая сеть $subnet и broadcast-адрес из переменной $broadcast
#При использовании данного скрипта для настройки DHCP пул адресов всегда будет расчитываться из кол-ва адресов с маской подсети равной 24. Учитывая, что клиентами DHCP являются от пяти до десяти устройств, это считается приемлемым
cat << End_Mess > /etc/dhcp/dhcpd.conf

option domain-name "localhost.localdomain";
option domain-name-servers $server;
default-lease-time 32400;
max-lease-time 604800;
log-facility local7;
subnet $subnet netmask 255.255.255.0 {
authoritative;
range $firstaddr $lastaddr;
option routers $server;
option subnet-mask 255.255.255.0;
option broadcast-address $broadcast;
 }

End_Mess

#Создается резервная копия конфигурационного файла Samba smb.conf
if [ -e /etc/samba/smb.conf.copy ]
 then
  echo
 else
  cp /etc/samba/smb.conf /etc/samba/smb.copy
fi

#Создается директория для папок Samba и сама общая папка с именем из переменной $directory
mkdir /SambaDirectories
mkdir /SambaDirectories/$directory
sudo chmod -R 0770 /SambaDirectories/$directory

#Производится настройка конфигурационного файла Samba smb.conf. Указывается действующий интерфейс, используемый порт и роль сервера standalone. Указывается директория $directory с правами на чтение, запись и выполнение для пользователя $user
cat << End_Mess > /etc/samba/smb.conf

[global]

   server string = Paul's_SambaServer
   server role = standalone server
   interfaces = 127.0.0.0/8 ens33
   bind interfaces only = yes
   disable netbios = yes
   smb ports = 445
   log file = /var/log/samba/smb.log
   max log size = 10000

[$directory]
   path = /SambaDirectories/$directory
   browseable = yes
   writeable = yes
   create mode = 0770
   guest ok = no
   valid users = $user
   admin users = $user
   force create mode = 0770
   directory mode = 0770

End_Mess

#Создается пользователь $user сперва локально (в рамках системы), затем для взаимодействия с файловым сервером.
useradd -m $user
echo -e "$password\n$password" | passwd $user &>/dev/null
echo -e "$password\n$password" | smbpasswd -a $user &>/dev/null

#Перезапускаются службы isc-dhcp-server и smbd.service, а также добавляются в автозагрузку
systemctl restart isc-dhcp-server &>/dev/null
systemctl restart smbd.service &>/dev/null
systemctl enable smbd.service &>/dev/null
systemctl enable isc-dhcp-server &>/dev/null

#Выводится сообщение об успешном выполнении скрипта а также статус служб smbd.service и isc-dhcp-server. Также выводятся данные для подключения к файловому серверу (в качестве напоминания)
echo
echo -e "\033[0;1;32mСкрипт успешно завершил свою работу! \033[0m"
echo
echo "----------------------------------"
echo
systemctl status smbd.service | head -n 3
echo
echo "----------------------------------"
echo
systemctl status isc-dhcp-server.service | head -n 3
echo
echo "----------------------------------"
echo
echo -e "\033[1mУбедитесь, что на операторских ПК включено сетевое обнаружение и клиентам заданы IP-адреса из той же сети, что и серверу.\033[0m"
echo
echo -e "\033[1mДанные для подключения к файловому серверу:\033[0m"
echo
echo "Адрес сервера: $server "
echo "Логин пользователя: $user "
echo "Пароль пользователя: $password "
echo
