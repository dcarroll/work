#!/bin/bash
noprompt=$1

prompt() {
	printf "$1 "
    if [ -z "$noprompt" ]; then
        read
    fi
}

rm -rf data
rm -rf force-app/main/default
mkdir force-app/main/default
mkdir force-app/main/default/aura

printf "Deleting old scratch org..."
sfdx force:org:delete -u GeoAppScratch -p

echo && prompt 'Will create org...'
sfdx force:org:create -s -f config/project-scratch-def.json -a GeoAppScratch

echo && prompt "Register user with Force CLI..."
./assets/force usedxauth

echo && prompt "<Force CLI> Will create custom field..."
./assets/force rest post tooling/sobjects/CustomField assets/fieldCreate.json

echo && prompt "<Force CLI> Will import metadata using Force CLI..."
./assets/force import -d md

echo && prompt "Execute source tracking work around..."
sfdx force:data:soql:query -q "SELECT Id FROM SourceMember" --json -t > memberquery.json
echo "<Force CLI> Patching the source member objects..."
for row in $(cat memberquery.json | jq .result.records[].Id); do
   eval 'force rest patch "tooling/sobjects/SourceMember/'$( echo $row | tr -d '"' )'"' assets/smupdate.json
   echo ""
done   

echo "Checking source status..."
sfdx force:source:status

echo "Assigning permset..."
sfdx force:user:permset:assign -n Geolocation

echo && echo "Pulling down source imported with Force CLI..."
sfdx force:source:pull

echo "Initializing git repo..."
git init
echo "Add remote orgin to developerforce/th-smoke-test"
git remote add origin https://github.com/developerforce/th-smoke-test

echo "Adding local changes to git..."
git add .
git remove sfdx
echo "Commiting changes to git..."
git commit -m 'Add custom field and permset'
echo "Pushing changes to remote..."
#git push origin master

echo "<Force CLI> Create an Account with location infomation..."
./assets/force record create Account Name:"Marriott Marquis" Location__Longitude__s:-122.403405 Location__Latitude__s:37.785143
echo "<Force CLI> Create an Account with location infomation..."
./assets/force record create Account Name:"Hilton Union Square" Location__Longitude__s:-122.410137 Location__Latitude__s:37.786164
echo "<Force CLI> Create an Account with location infomation..."
./assets/force record create Account Name:"Hyatt" Location__Longitude__s:-122.396311 Location__Latitude__s:37.794157

echo "Creating data directory locally..."
mkdir data
echo "Running tree export command..."
sfdx force:data:tree:export -q "SELECT Name, Location__Latitude__s, Location__Longitude__s FROM Account WHERE Location__Latitude__s != NULL AND Location__Longitude__s != NULL" -d ./data

echo && prompt "Running tree import command..."
sfdx force:data:tree:import --sobjecttreefiles data/Account.json

echo && prompt "Creating Apex AccountController for lightning component..."
sfdx force:apex:class:create -n AccountController -d force-app/main/default/classes
cat assets/templates/AccountController.cls > force-app/main/default/classes/AccountController.cls

prompt "Pushing Apex AccountController to org..."
sfdx force:source:push

echo && prompt "Creating AccountLocator component..."
sfdx force:lightning:component:create -n AccountLocator -d force-app/main/default/aura

cat assets/templates/AccountLocator.cmp > force-app/main/default/aura/AccountLocator/AccountLocator.cmp

cat assets/templates/AccountLocator.css > force-app/main/default/aura/AccountLocator/AccountLocator.css

echo "Pushing lightning sources to org..."
sfdx force:source:push

echo "<Force CLI> Creating custom tab for the lightning component..."
./assets/force rest post tooling/sobjects/CustomTab  assets/templates/customtab/customTab.json

echo "<Force CLI> Push updated profile for Admin to see new tab..."
./assets/./assets/force rest post tooling/sobjects/CustomTab  assets/templates/customtab/customTab.json
force push -f assets/templates/customtab/profiles/Admin.profile

echo "Pulling the new Tab to local space..."
sfdx force:source:pull

echo && prompt "Creating AccountListItem lightning component..."
sfdx force:lightning:component:create -n AccountListItem -d force-app/main/default/aura

cat assets/templates/AccountListItem.cmp > force-app/main/default/aura/AccountListItem/AccountListItem.cmp

cat assets/templates/AccountListItem.css > force-app/main/default/aura/AccountListItem/AccountListItem.css

prompt "Creating AccountList lightning component..."
sfdx force:lightning:component:create -n AccountList -d force-app/main/default/aura

cat assets/templates/AccountList.cmp > force-app/main/default/aura/AccountList/AccountList.cmp

cat assets/templates/AccountList.css > force-app/main/default/aura/AccountList/AccountList.css

cat assets/templates/AccountListController.js > force-app/main/default/aura/AccountList/AccountListController.js

cat assets/templates/AccountLocator2.cmp > force-app/main/default/aura/AccountLocator/AccountLocator.cmp

prompt "Pushing new lightning components..."
sfdx force:source:push

echo "Opening scratch org..."
sfdx force:org:open

rm -rf metadata
rm -rf src 

echo "<end>"