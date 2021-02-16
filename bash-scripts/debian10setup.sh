#!/bin/bash

################################################################################################################
#Script name    :debian10setup.sh
#Description    :Used for setting basic requirements and dependecies for stable and secure infrastructure.
#Args           :No
#Author         :Ilija Letic
#Email          :ilija.letic@shandoola.com
#Ownership      :Shandoola Doo
################################################################################################################

# Colorized output and variable with pwd
RED='\033[0;31m'
GREEN='\e[32m'
NOCOLOR='\033[0m'
current_dir=$(pwd)


# Help argument
if [ "$#" -gt 0 ]; then
    if [ "$1" == "-help" ]; then
        echo "This script installs basic tools and sets configuration for infrastructure to be stable and safe..."
        echo "This includes:"
        echo "- Installing netstat, htop, vim, git, sudo, tree."  
        echo "- Setting timezone."  
        echo "- Creating users with option to add them to sudoers group. There is also option to add ssh public key to each created user."  
        echo "- Setting and hardening SSH." 
        echo "- Adding colorization output for root user."  
        echo "- Instaling Nginx, NodeJS, php, Apache, MariaDB."  
        echo "- Instaling ufw and setting ufw rules."  
        exit 0
    fi
    echo "Invalid arguments.. Please use '-help' as argument to get further information"
    exit 1
fi

# RUN as root reminder
if [[ $UID != 0 ]]; then
    echo "Please run this script as root user"
    exit 1
fi

echo -e 'Starting script for setting basic requirements and dependencies for stable infrastructure'
echo -e 'Please wait.'

# Creating file for logs and updating packages
touch "$current_dir"/.STlog
apt-get update &> "$current_dir"/.STlog ; echo "#########" >> "$current_dir"/.STlog
echo "#################################################################################################################"

# Setting timezone
echo -e "Setting timezone"
echo -e "Your current status:"
    timedatectl status | grep Time 
#echo -e "List of available timezones"  listing available timezones... discarding it but leaving as a comment
    #timedatectl list-timezones | grep Europe  listing available timezones... discarding it but leaving as a comment
echo -e 'What should my timezone be? [Continent/City]'
    read -r timezone
    timedatectl set-timezone "$timezone"
        if [ $? -ne 0 ];
            then
                echo -e "${RED}Something went wrong, Timezone is not set!${NOCOLOR}"
            else
                echo -e "${GREEN}Timezone is set!${NOCOLOR}"
        fi
echo "#################################################################################################################"

# Adding colorization
echo -e "Adding some basic colorization options for root's shell"   
    echo "export LS_OPTIONS='--color=auto'" >> /root/.bashrc
    echo 'eval "`dircolors`" ' >> /root/.bashrc
    LS_OPTIONS='$LS_OPTIONS'
    echo "alias ls='ls $LS_OPTIONS'" >> /root/.bashrc
echo "#################################################################################################################"

# Installing basic tools
echo -e "Installing netstat, htop, vim, git, sudo, tree"
    apt-get install -y net-tools htop vim git sudo tree >> "$current_dir"/.STlog ; echo "#########" >> "$current_dir"/.STlog
        if [ $? -ne 0 ];
            then
                echo -e "${RED}One or more packets are not installed.. Please check $current_dir/.STlog.${NOCOLOR}"
            else
                echo -e "${GREEN}netstat, htop, vim, git, sudo successfuly installed!${NOCOLOR}"
        fi
echo "#################################################################################################################"

# Creating admin's user and other users with option to add created user to sudoers group
echo -e "Setting Different Users, sudoers or no-sudoers"
echo -e "Adding User... Please, insert Admin's Username and Password and write them somewhere safe!"
echo -n "Username: "
    read -r useradmin
    /sbin/adduser --gecos "" "$useradmin"
echo -e "${GREEN}Admin's User created: ${useradmin} ${NOCOLOR}"
echo -e "Should I add admin user $useradmin in sudoers group (preffered for admin's user)?"
echo -e "yes/no?"
    read -r bovar
        case $bovar in
            yes)   
                /sbin/usermod -aG sudo "$useradmin"
                echo -e "${GREEN}$useradmin added to sudoers ${NOCOLOR}"
            ;;
            no)
                echo -e "${RED} $useradmin is not added to sudoers ${NOCOLOR}"
                ;;
            *)	
                echo -e "${RED}Wrong input!${NOCOLOR}"	
                echo -e "${GREEN} $useradmin added to sudoers ${NOCOLOR}"			
            ;;
        esac
echo -e "Creating directory and file for ssh keys in $useradmin's folder"
    mkdir /home/"$useradmin"/.ssh
    touch /home/"$useradmin"/.ssh/authorized_keys
    chown -R "$useradmin":"$useradmin" /home/"$useradmin"/.ssh
    chmod 600 /home/"$useradmin"/.ssh/authorized_keys
        if [ $? -ne 0 ];
            then
                echo -e "${RED}There is some problem with creating ssh directory!${NOCOLOR}"
                exit 1
            else
                echo -e "${GREEN}Directory and file for ssh keys in $useradmin's folder successfully created${NOCOLOR}"
        fi
echo -e "Please insert SSH public key for $useradmin."
    read admins_pub_key
    echo -r "$admins_pub_key" >> /home/"$useradmin"/.ssh/authorized_keys
        if [ $? -ne 0 ];
            then
                echo -e "${RED}There is some problem with adding key to authorized_keys${NOCOLOR}"
                exit 1
            else
                echo -e "${GREEN}Public key for $useradmin is added!${NOCOLOR}"
        fi
echo -e "Do you want to add additional SSH public keys for user $useradmin ?"
echo -e "yes/no?"
    read -r whilepubvar
    while [ "$whilepubvar" = "yes" ] ; do
        echo -e "Please insert additional SSH public key for $useradmin."
        read -r admins_pub_key
        echo "$admins_pub_key" >> /home/"$useradmin"/.ssh/authorized_keys
            if [ $? -ne 0 ];
                then
                    echo -e "${RED}There is some problem with adding additional key to authorized_keys${NOCOLOR}"
                    exit 1
                else
                    echo -e "${GREEN}Additional public key for $useradmin is added!${NOCOLOR}"
            fi
        echo -e "Do you want to add more SSH public keys for user $useradmin ?"
        echo -e "yes/no?"
            read -r whilepubvar
    done
echo -e "---"
echo -e "Do you want to create more users?"
echo -e "yes/no?"
    read -r whilevar
    t=0
        while [ "$whilevar" = "yes" ] ; do
            t=$(($t + 1))
            echo -n "Username: "
                read -r addeduser
                /sbin/adduser --gecos "" "$addeduser"
            echo -e "${GREEN}User created: ${addeduser} ${NOCOLOR}"
            echo -e "Should I add user $addeduser in sudoers group?"
            echo -e "yes/no?"
                read -r bovar
                    case $bovar in 
                        yes)   
                            /sbin/usermod -aG sudo "$addeduser"
                            echo -e "${GREEN}$addeduser added to sudoers ${NOCOLOR}"
                        ;;
                        no)
                            echo -e "${RED}$addeduser is not added to sudoers ${NOCOLOR}"
                        ;;
                        *)	
                            echo -e "${RED}Wrong input!${NOCOLOR}"	
                            echo -e "${RED}$addeduser is not added to sudoers ${NOCOLOR}"			
                        ;;
                    esac
            echo -e "Do you want to add SSH public key for $addeduser"
            echo -e "yes/no?"
                read boleanvar
                if [ "$boleanvar" = "yes" ];
                    then
                        echo -e "Creating directory and file for ssh keys in $addeduser's folder"
                            mkdir /home/"$addeduser"/.ssh
                            touch /home/"$addeduser"/.ssh/authorized_keys
                            chown -R "$addeduser":"$addeduser" /home/"$addeduser"/.ssh
                            chmod 600 /home/"$addeduser"/.ssh/authorized_keys
                            if [ $? -ne 0 ];
                                then
                                    echo -e "${RED}There is some problem with creating ssh directory!${NOCOLOR}"
                                    exit 1
                                else
                                    echo -e "${GREEN}Directory and file for ssh keys in $addeduser's folder successfully created${NOCOLOR}"
                            fi
                        echo -e "Please insert SSH public key for $addeduser."
                            read -r addeduser_pub_key
                        echo "$addeduser_pub_key" >> /home/"$addeduser"/.ssh/authorized_keys
                            if [ $? -ne 0 ];
                                then
                                    echo -e "${RED}There is some problem with adding key to authorized_keys${NOCOLOR}"
                                    exit 1
                                else
                                    echo -e "${GREEN}Public key for $addeduser is added!${NOCOLOR}"
                            fi
                        echo -e "Do you want to add additional SSH public keys for user $addeduser ?"
                        echo -e "yes/no?"
                            read -r whilepubvar
                            while [ "$whilepubvar" = "yes" ] ; do
                                echo -e "Please insert additional SSH public key for $addeduser."
                                    read -r addeduser_pub_key
                                echo "$addeduser_pub_key" >> /home/"$addeduser"/.ssh/authorized_keys
                                    if [ $? -ne 0 ];
                                        then
                                            echo -e "${RED}There is some problem with adding additional key to authorized_keys${NOCOLOR}"
                                            exit 1
                                        else
                                            echo -e "${GREEN}Additional public key for $addeduser is added!${NOCOLOR}"
                                    fi
                        echo -e "Do you want to add more SSH public keys for user $addeduser ?"
                        echo -e "yes/no?"
                            read -r whilepubvar
                        done
                fi
            echo -e "---"
            echo -e "Should I create more users?"
            echo -e "yes/no?"
                read -r whilevar
        done
echo "#################################################################################################################"
echo -e "${GREEN}You successfuly created admin user $useradmin and $t additional users: ${NOCOLOR}"
    if [ $t -eq 0 ];
        then
            additionalusers="There are no additional users."
        else
            additionalusers=$(tail -"$t" /etc/passwd | awk -F: '{print $1}')
        fi    
echo -e "$additionalusers"
echo "#################################################################################################################"


# Instaling Nginx, NodeJS, php, Apache, MariaDB
echo -e "Installing Nginx..."
    {
        apt-get install -y nginx >> "$current_dir"/.STlog
            pid=$!
            wait $pid
        echo "#########"
    } >> "$current_dir"/.STlog
echo -e "Copying nginx config file to /etc/nginx/sites-available/default."
echo -e "Original default will become default_bkp"
    mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default_bkp
    cp "$current_dir"/nginx_config/default /etc/nginx/sites-available/default
    nginx_v=$(echo "$(/usr/sbin/nginx -v | grep nginx)")
echo -n "$nginx_v"
echo -e "${GREEN}Successfully installed!${NOCOLOR}"
echo " "
echo -e "Installing nodeJS and NPM..."
    {
        apt-get install -y nodejs npm
            pid=$!
            wait $pid
        npm i -g pm2
            pid=$!
            wait $pid
        echo "#########" 
    } >> "$current_dir"/.STlog
    nodeJS_v=$(node -v)
    npm_v=$(npm -v)
echo -e "${GREEN}nodeJS $nodeJS_v successfully installed!${NOCOLOR}"
echo -e "${GREEN}npm $npm_v successfully installed!${NOCOLOR}"
echo -e "${GREEN}pm2 successfully installed!${NOCOLOR}"
echo -e "Installing php..."
    {
        apt-get update
            pid=$!
            wait $pid
        apt-get -qq -y install lsb-release apt-transport-https ca-certificates
            pid=$!
            wait $pid
        wget -q -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
            pid=$!
            wait $pid
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
            pid=$!
            wait $pid
        apt-get update
            pid=$!
            wait $pid
        apt-get -qq -y install php7.4
            pid=$!
            wait $pid
        echo "#########"
    } >> "$current_dir"/.STlog
    php_v=$(php -version | awk 'NR==1{print $1, $2}')
echo -e "${GREEN}$php_v successfully installed!${NOCOLOR}"
echo -e "Installing Apache..."
    {
        apt-get install -y apache2
            pid=$!
            wait $pid
        echo "#########"
    } >> "$current_dir"/.STlog
    apache_v=$(/usr/sbin/apachectl -v | awk 'NR==1{print $3}')
echo -e "${GREEN}$apache_v successfully installed!${NOCOLOR}"
echo -e "Installing mariaDB..."
    {
        apt-get install -y mariadb-server
            pid=$!
            wait $pid
        echo "#########"     
    } >> "$current_dir"/.STlog
    mysql_v=$(/usr/sbin/mysqld --version | awk -F" |-" '{print $5, $4}')
echo -e "${GREEN}$mysql_v successfully installed!${NOCOLOR}"
echo "#################################################################################################################"

# Setting and hardening ssh protocol..
echo -e "Installing and enabling openssh-server"
    {
        apt-get install -y openssh-server
        systemctl enable ssh 
        systemctl start ssh 
        echo "#########" 
    } >> "$current_dir"/.STlog
echo -e "I am enabling ssh protocol 2..."
    echo "Protocol 2" >> /etc/ssh/sshd_config
echo -e "I am disabling ssh root login..."
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo -e "I am disabling password authentication..."
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo -e "I am limmiting authentication tries to 3..."
    echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
echo -e "I am changing default SSH port 22 to 2288"
    echo "Port 2288" >> /etc/ssh/sshd_config
echo -e "Restarting ssh"
    systemctl reload sshd
    if [ $? -ne 0 ];
        then
            echo -e "${RED}Something went wrong with sshd_config. Please manually check for errors manually${NOCOLOR}"
            exit 1
        else
            echo -e "${GREEN}sshd_confing is correct!${NOCOLOR}"
    fi
echo -e "I am restarting ssh service"
    systemctl restart sshd
    echo -e "${GREEN}SSH service is $(systemctl is-active sshd).${NOCOLOR}"
echo -e "${GREEN}SSH service should be set and safe.${RED} Before closing current connection please check if /home/$useradmin/.ssh/authorized_keys matches private key that $useradmin has.${NOCOLOR}"
echo -e "${GREEN}Or simply, try to connect right now with that key!${NOCOLOR}"
echo "#################################################################################################################"
sleep 3

# Instaling ufw and setting rules
echo -e "Installing ufw and setting some basic rules..."
    {
        apt-get install ufw -y 
            pid=$!
            wait $pid
        echo "#########"
    } >> "$current_dir"/.STlog
echo -e "${GREEN}UFW successfully installed!${NOCOLOR}"
echo -e "Configuring and adding ufw rules..."
    echo "y" | /usr/sbin/ufw enable >> "$current_dir"/.STlog
    {
        /usr/sbin/ufw allow 80
        /usr/sbin/ufw allow 443
        /usr/sbin/ufw allow 2288
        /usr/sbin/ufw deny 22
    } >> "$current_dir"/.STlog
    echo '& stop' >> /etc/rsyslog.d/20-ufw.conf #Disabling loging ufw logs in kern.log and syslog
    systemctl restart ufw
        pid=$!
        wait $pid
echo -e "UFW should be confirugated and these are rules: "
    /usr/sbin/ufw status numbered  
echo "#################################################################################################################"
