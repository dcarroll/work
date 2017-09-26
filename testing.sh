#!/bin/bash

sfdx force:org:delete -u GeoAppScratch -p
echo "Will create org..."
read x
sfdx force:org:create -s -f config/project-scratch-def.json -a GeoAppScratch
read x
force usedxauth
echo "Will create custom field..."
read x
force rest post tooling/sobjects/CustomField assets/fieldCreate.json
echo "Will import metadata using Force CLI..."
read x
force import -d md.1
read x
sfdx force:data:soql:query -q "SELECT Id FROM SourceMember" --json -t > memberquery.json
echo "Hackaround source tracking bug..."
read x
for row in $(cat memberquery.json | jq .result.records[].Id); do
   eval 'force rest patch "tooling/sobjects/SourceMember/'$( echo $row | tr -d '"' )'"' smupdate.json
   echo ""
done   
echo "Checking source status..."
sfdx force:source:status

echo "Assigning permset..."
sfdx force:user:permset:assign -n Geolocation

echo "Pulling down source imported with Force CLI..."
sfdx force:source:pull

echo "Initializing git repo..."
git init
echo "Add remote orgin to developerforce/th-smoke-test"
git remote add origin https://github.com/developerforce/th-smoke-test

#read x
echo "Adding local changes to git..."
git add .
echo "Commiting changes to git..."
git commit -m 'Add custom field and permset'
echo "Pushing changes to remote..."
#git push origin master

echo "Create an Account with location infomation, using Force CLI..."
force record create Account Name:"Marriott Marquis" Location__Longitude__s:-122.403405 Location__Latitude__s:37.785143
echo "Create an Account with location infomation, using Force CLI..."
force record create Account Name:"Hilton Union Square" Location__Longitude__s:-122.410137 Location__Latitude__s:37.786164
echo "Create an Account with location infomation, using Force CLI..."
force record create Account Name:"Hyatt" Location__Longitude__s:-122.396311 Location__Latitude__s:37.794157

echo "Creating data directory locally..."
read x
mkdir data
echo "Running tree export command..."
read x
sfdx force:data:tree:export -q "SELECT Name, Location__Latitude__s, Location__Longitude__s FROM Account WHERE Location__Latitude__s != NULL AND Location__Longitude__s != NULL" -d ./data

echo "Running tree import command..."
read x
sfdx force:data:tree:import --sobjecttreefiles data/Account.json

echo "Creating Apex AccountController for lightning component..."
read x
sfdx force:apex:class:create -n AccountController -d force-app/main/default/classes
cat assets/templates/AccountController.cls > force-app/main/default/classes/AccountController.cls

echo "Pushing Apex AccountController to org..."
read x
sfdx force:source:push

echo "Creating AccountLocator component..."
sfdx force:lightning:component:create -n AccountLocator -d force-app/main/default/aura

cat assets/templates/AccountLocator.cmp > force-app/main/default/aura/AccountLocator/AccountLocator.cmp

cat assets/templates/AccountLocator.css > force-app/main/default/aura/AccountLocator/AccountLocator.css

echo "Pushing lightning sources to org..."
sfdx force:source:push

echo "<Force CLI> Creating custom tab for the lightning component..."
force rest post tooling/sobjects/CustomTab  assets/customTab.json

echo "Pulling the new Tab to local space..."
sfdx force:source:pull

echo "Creating AccountListItem lightning component..."
sfdx force:lightning:component:create -n AccountListItem -d force-app/main/default/aura

cat assets/templates/AccountListItem.cmp > force-app/main/default/aura/AccountListItem/AccountListItem.cmp

cat assets/templates/AccountListItem.css > force-app/main/default/aura/AccountListItem/AccountListItem.css

echo "Creating AccountList lightning component..."
sfdx force:lightning:component:create -n AccountList -d force-app/main/default/aura

cat assets/templates/AccountList.cmp > force-app/main/default/aura/AccountList/AccountList.cmp

cat assets/templates/AccountList.css > force-app/main/default/aura/AccountList/AccountList.css

echo "<end>"