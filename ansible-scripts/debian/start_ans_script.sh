#!/bin/bash

################################################################################################################
#Script name    :start_ans_script.sh
#Description    :Starting Ansible basic server setup. This script is mainly used to start other *.sh scripts that each ansible roles has.
#Args           :No
#Author         :Ilija Letic
#Email          :ilija.letic@shandoola.com
#Ownership      :Shandoola Doo
################################################################################################################

# colorization of output
RED='\033[0;31m'
GREEN='\e[32m'
NOCOLOR='\033[0m'

# RUN as root reminder
if [[ $UID != 0 ]]; then
    echo "Please run this script as root user"
    exit 1
fi

if [ "$#" -gt 0 ]; then
    if [ "$1" == "-help" ]; then                            # running help argument
        echo "This script feeds variable sets for ansible."
        echo "After variable sets are feed, script runs different playbooks with tasks:"
        echo "- Installing netstat, htop, vim, git, sudo, tree."  
        echo "- Setting timezone."  
        echo "- Creating users with option to add them to sudoers group. There is also option to add ssh public key to each created user."  
        echo "- Instaling Nginx (with hardening), NodeJS, php, Apache, MariaDB."  
        echo "- Setting and hardening SSH." 
        echo "- Instaling ufw and setting ufw rules."  
        exit 0
    fi
    echo "Invalid arguments.. Please use '-help' as argument to get further information"
    exit 1
fi


echo -e "---"
echo -e "Thank you for starting the script!"                  #short introduction to requirements
echo -e "---"
echo -e "These are requirements for this script to work properly:"
echo -e "${GREEN}- Ansible version 2.9 or higher is required.${NOCOLOR}"
echo -e "${GREEN}- ansible.posix collection required for some modules. (run -> [ansible-galaxy collection install ansible.posix])${NOCOLOR}"
echo -e "${GREEN}- Sudo is required on the slave server. Please install it on the slave server.${NOCOLOR}"
echo -e "---"
echo -e "To get further information about script run -help as argument"
echo -e "---"
echo -e "Do you want to continue now?"
echo -e "(yes/no)"
    read -r start_bolean
        if [ "$start_bolean" != "yes" ];
            then
                echo -e "Script stoped."
                exit 0
        fi



echo -e "You started script for installing basic infrastructure on Debian servers using Ansible"


# Setting information into host file
rm -rf "$(pwd)"/hosts #just removing hosts file from prevous session
echo -e "[debian10_servers]" >> "$(pwd)"/hosts #adding new empty hosts
while_add_slave_var="yes"
while [ "$while_add_slave_var" = "yes" ] ; do                        #while loop added to enable input of multiple slaves
    echo -e "Setting information about slave server.."
    echo -e "Please type ip address of the slave server: "
        read -r slave_ip_address
    echo -e "Please type ssh user of slave server: "
        read -r slave_ssh_user                                                                                          #simple input
        while true; do                                                           
            echo -e "Please type ssh password of slave server: "
            read -r -s slave_ssh_password
            echo
            echo -e "Password (again):"
            read -r -s slave_ssh_password2
            echo
            [ "$slave_ssh_password" = "$slave_ssh_password2" ] && break
            echo -e "Please try again" 
        done
        o='"'
    echo -e " " >> "$(pwd)"/hosts
    echo -e "${slave_ip_address} ansible_ssh_user=${o}${slave_ssh_user}${o} ansible_ssh_pass=${o}${slave_ssh_password}${o} ansible_sudo_pass=${o}${slave_ssh_password}${o}" >> "$(pwd)"/hosts 
    echo -e "---"
    echo -e "Slave server with the following information added to hosts file:"
    echo -e "ip address: ${GREEN}${slave_ip_address}${NOCOLOR}"
    echo -e "ssh username: ${GREEN}${slave_ssh_user}${NOCOLOR}"
    echo -e "---"
    echo -e "Do you want to add more slave servers?"
    echo -e "yes/no?"
    read -r while_add_slave_var
done
echo -e "Testing connection.."
ansible debian10_servers -i hosts -m ping #pinging slave through ansible


# Setting variable for timezone ansible role
echo -e 'Please, insert desired timezone location?'
echo -e '[Continent/City]'
read -r continent_city
rm -rf "$(pwd)"/timezone/vars/main.yml
echo '---' >> "$(pwd)"/timezone/vars/main.yml
echo " " >> "$(pwd)"/timezone/vars/main.yml
echo "continent_city: ${continent_city}" >> "$(pwd)"/timezone/vars/main.yml
if [ $? -ne 0 ];
    then
        echo -e "${RED}Something went wrong with adding ${continent_city} variable ${NOCOLOR}"
    else
        echo -e "${continent_city} Succesfully importet in variables set!"
    fi

# starting ansible-playbook for setting timezone and installing handytools
ansible-playbook -i hosts timezone_handytools.yml

# Setting necessary variables for user_create ansible role...
user_create_while_var="yes"
while [ "$user_create_while_var" = "yes" ] ; do
    echo -e "Setting Different Users, sudoers or no-sudoers"
    echo -e "Please insert Admin's credentials and write them somewhere safe!"
    echo -e "Username:"
        read -r user_name      
    while true; do                                                               #standard reading of input
        echo -e "Password:"
        read -s password_name
        echo
        echo -e "Password (again):"
        read -s password_name2
        echo
        [ "$password_name" = "$password_name2" ] && break
        echo -e "Please try again" 
    done
    echo -e "Should I add ${user_name} to sudoers group?"
    echo -e "yes/no?"
        read -r sudo_bolean
    echo -e "Do you want to add pub_key to /home/${user_name}/.ssh/authorized_keys. ${RED}It is preffered for admin!${NOCOLOR}"
    echo -e "yes/no"
        read -r key_bolean
            if [ "$key_bolean" = "yes" ];
                then
                    key_bolean="present"
                else
                    key_bolean="absent"
                    pub_key=0
            fi
    if [ "$key_bolean" = "present" ];
        then
            echo -e "Please input desired key:"
                read -r pub_key
        else                                                                                               #Ansible can't take some random value... but in this case ansible will take this key but since key_bolean is absent ansible wont give this key to user
            pub_key='ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAklQQMNzk6BfuSrkMr3V9rzAUdTljTDqAcqXTOxw+1zfdqtCBsauoY+nPbQmU4FFFSh149iIszUu9I32ojrb15KzjyoxqwD6aHQuUODtTP/xNf/WgR9ScOyJZdBySRb7GppkwJPLQv41fXU684oKC1jr+PJdjfm/Hai9qBuNFH5CUsatvB6uCsyZ/+giReiBAJ/Jd1ds5jBcV0kkmBESgr8FSBmxEBA0vOVRimmTa0RfFIjXmAFibqY0KtKL6PIJgZp68FfaE6A5JQlY3vX/yFRqre/F5D96QtuE9uuOnatp2OSj8mpJWgw9on0nDCnTU4ASp+q/Xr4QpE0lYTarrIw== rsa-key-20201201'
    fi
            rm -rf "$(pwd)"/user_create/vars/main.yml               #just deleting previous variable set
            echo -e "---" >> "$(pwd)"/user_create/vars/main.yml
            echo -e " " >> "$(pwd)"/user_create/vars/main.yml                                               #feeding /var directory
            echo -e "user_name: ${user_name}" >> "$(pwd)"/user_create/vars/main.yml
            echo -e "password_name: ${password_name}" >> "$(pwd)"/user_create/vars/main.yml
            echo -e "sudo_bolean: ${sudo_bolean}" >> "$(pwd)"/user_create/vars/main.yml
            echo -e "key_bolean: ${key_bolean}" >> "$(pwd)"/user_create/vars/main.yml
            echo -e "pub_key: ${pub_key}" >> "$(pwd)"/user_create/vars/main.yml
            
            ansible-playbook -i hosts user_create.yml   #running ansible-playbook just for user_creation

            echo -e "Do you want to add more users?"
            echo -e "yes/no?"
                read -r user_create_while_var      #loop in case you want to create more users
done

# Setting location of sshd config file as variable
echo -e "${RED}Please make sure that you have assigned public_key to some users. SSH authentication will be passwordless!${NOCOLOR}"
sshd_config_location="$(pwd)"/configs/sshd_config
rm -rf "$(pwd)"/set_SSH/vars/main.yml
echo -e "---" >> "$(pwd)"/set_SSH/vars/main.yml
echo -e " " >> "$(pwd)"/set_SSH/vars/main.yml
echo -e "sshd_config_location: ${sshd_config_location}" >> "$(pwd)"/set_SSH/vars/main.yml

# Setting location of nginx config (default) as a variable
nginx_config_location="$(pwd)"/configs/nginx_conf/default
rm -rf "$(pwd)"/set_NGINX/vars/main.yml
echo -e "---" >> "$(pwd)"/set_NGINX/vars/main.yml
echo -e " " >> "$(pwd)"/set_NGINX/vars/main.yml
echo -e "nginx_config_location: ${nginx_config_location}" >> "$(pwd)"/set_NGINX/vars/main.yml

ansible-playbook -i hosts installations.yml #running ansible-playbook for installation of more important tools

echo -e "Installation is finished!"