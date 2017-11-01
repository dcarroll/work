#!/bin/bash
source testing-local.sh
export CONSUMERKEY="3MVG9SemV5D80oBc0DJyJvvUi4qo2y6INTmVdnwtPE4eORq9IwR3fHCWXna2yjDPcHXu4F0j5ZIhTgy13H87G"
export USERNAME="dcarroll-vnv9@force.com"

reset
sfdx force:auth:jwt:grant --clientid $CONSUMERKEY --jwtkeyfile assets/server.key  --username $USERNAME --setdefaultdevhubusername -a HubOrg

sfdx force:org:create -s -f config/project-scratch-def.json -a GeoAppScratch
forceSetup
sfdx force:source:status
sfdx force:user:permset:assign -n Geolocation
sfdx force:source:pull
#git init
#- git remote add origin https://github.com/developerforce/th-smoke-test
#git add .
#git commit -m 'Add custom field and permset'
#git push origin master
forceAddAccounts
mkdir data
sfdx force:data:tree:export -q "SELECT Name, Location__Latitude__s, Location__Longitude__s FROM Account WHERE Location__Latitude__s != NULL AND Location__Longitude__s != NULL" -d data
sfdx force:data:tree:import --sobjecttreefiles data/Account.json
cat assets/templates/AccountController.cls > force-app/main/default/classes/AccountController.cls
sfdx force:source:push
sfdx force:lightning:component:create -n AccountLocator -d force-app/main/default/aura
getAccountLocatorContent
sfdx force:source:push
forceCreateTab
sfdx force:source:pull
cat assets/templates/AccountListItem.cmp > force-app/main/default/aura/AccountListItem/AccountListItem.cmp
cat assets/templates/AccountListItem.css > force-app/main/default/aura/AccountListItem/AccountListItem.css
sfdx force:lightning:component:create -n AccountList -d force-app/main/default/aura
addAccountListContent
sfdx force:source:push
sfdx force:user:password:generate
sfdx force:user:display
cleanUpAfterForce
echo "<end>"