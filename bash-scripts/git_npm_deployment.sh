#!/bin/bash

################################################################################################################
#Script name    :git_npm_deployment.sh
#Description    :This script clones repository, builds it if parameter is added and creates backup of prevoius version
#Args           :No
#Author         :Dusan Ilic
#Email          :dusan.ilic@shandoola.com
#Ownership      :Shandoola Doo
################################################################################################################

PC="$#"
BRANCH="$1"
NPM="$2"
CHECK="build"
RED='\e[31m'
GREEN='\e[32m'
NOCOLOR='\033[0m'
current_time=$(date "+%Y.%m.%d-%H.%M.%S")

if [ $PC -lt 1 ];
then
        echo -e "${RED}Invalid arguments, please see following options:${NOCOLOR}"
        echo -e "Deployment script for Eat And Save project, for printing usage manual again please run script without arguments:"
        echo -e "  OPTIONS:"
        echo -e "    ./deploy.sh ${GREEN}- prints this message${NOCOLOR}"
        echo -e "    ./deploy.sh <branch> ${GREEN}- Deploys only code for SPECIFIC branch withot rebuilding source${NOCOLOR}"
        echo -e "    ./deploy.sh <branch> build ${GREEN}- Deploys code and rebuilds source with new npm packages${NOCOLOR}"

        exit 1
else
        cd /tmp
        git clone --branch $BRANCH  https://bitbucket.org/shandoola/eas-devops.git

        if [ -d "eas-web" ];
        then
          echo -e "${GREEN}Repository clone successfull${NOCOLOR}"
        else
          echo -e "${RED}Repository clone failed${NOCOLOR}"
          exit 1
        fi

pkill -9 node

        if [ "$NPM" = "$CHECK" ];
        then
          echo -e "${GREEN}Building from source with new npm packages...${NOCOLOR}"

          mv /home/easadmin/eas-web /home/easadmin/eas-web-$current_time
          echo -e "${GREEN}Previous build deployed backed up if existing on: /home/easadmin/eas-web-${current_time} ${NOCOLOR}"

          echo -e "${GREEN}Cleaning up previous build, user may be required to input password: ${NOCOLOR}"
          rm -rf /home/easadmin/eas-web

          mv /tmp/eas-web /home/easadmin/eas-web
          cd /home/easadmin/eas-web
          npm install -s
          npm audit fix --silent
          pm2 start npm -- start
        else
          echo -e "${GREEN}Deploying new code only...${NOCOLOR}"

          cp -r /home/easadmin/eas-web /home/easadmin/eas-web-$current_time
          echo -e "${GREEN}Previous build deployed backed up if existing on: /home/easadmin/eas-web-${current_time} ${NOCOLOR}"

          cp -r /tmp/eas-web/* /home/easadmin/eas-web/
          cp -r /tmp/eas-web/package.json /home/easadmin/eas-web

          cd /home/easadmin/eas-web
          pm2 start npm -- start
          rm -rf /tmp/eas-web
        fi
fi

if [ $? -ne 0 ];
then
        echo -e "${RED}Deployment failed, see npm logs.${NOCOLOR}"
else
        echo -e "${GREEN}Deployment complete, application deployed at path: ${NOCOLOR} /home/easadmin/eas-web"
        exit 0
fi