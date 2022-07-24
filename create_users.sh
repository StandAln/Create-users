#!/usr/bin/env bash

#Checking root permissions
if [ "$(id -u)" != 0 ]
then
  echo root permissions required >&2
  exit 1
fi

#Variables
file=/opt/scripts/create_user/users.csv
oldIFS=$IFS

#Functions
check_user() {
i=0
userorig=$user
while cut -d: -f1 /etc/passwd | grep ^$user$ > /dev/null
do
   user=$userorig
   ((i++))
   user=$user$i
done
}

create_user() {
#Restore IFS
IFS=$oldIFS
shell=/sbin/nologin
#Create group
groupadd $group

# Sudoers
if [ "$group" = it ] || [ "$group" = security ]
then
  if ! grep "%$group" /etc/sudoers >/dev/null
    then 
    cp /etc/sudoers{,.bkp}
    echo '%'$group' ALL=(ALL) ALL' >> /etc/sudoers
  fi
  shell=/bin/bash
elif [ "$user" = admin ]
then
  if ! grep "$user" /etc/sudoers >/dev/null
    then 
    cp /etc/sudoers{,.bkp}
    echo $user' ALL=(ALL) ALL' >> /etc/sudoers
  fi
  shell=/bin/bash
fi

mkdir /home/$group &>/dev/null
useradd $user -g $group -b /home/$group -s $shell -c "Birthday $bday" &>/dev/null 
echo Создан пользователь: $user с группой: $group !
}


#Check parameters
if [ ! -z $2 ]
then
  user=$1
  group=$2
  check_user
  create_user
elif [ -f $file ]
then
  IFS=$'\n'
  for line in $(cut -d, -f2,3,4,5 $file | tail -n +2 | tr '[:upper:]' '[:lower:]' | tr , ' ' )
  do
    user=$(echo $(echo "$line" | cut -c1).$(echo "$line" | cut -d' ' -f2))
    group=$(echo "$line" | cut -d' ' -f4)
    bday=$(echo "$line" | cut -d' ' -f3)
    check_user
    create_user
  done
else
  echo Welcome!
  select option in "Add user" "Show users" "Exit"
  do  case $option in
         "Add user")
	            read -p "Print username: " user
		    read -p "Print groupname: " group
  		    check_user
  		    create_user ;;
         "Show users")
		    cut -d: -f1 /etc/passwd ;;
	 "Exit")
		    break ;;
	 *) echo Wrong option ;;
      esac
  done

fi


