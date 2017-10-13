#!/bin/bash
prompt() {
	printf "$1 "
}

reset() {
    rm -rf data
    rm -rf force-app/main/default
    mkdir force-app/main/default
    mkdir force-app/main/default/aura
    printf "Deleting old scratch org..."
    #sfdx force:org:delete -u GeoAppScratch -p
    return
}

forceSetup() {
    echo && prompt "Register user with Force CLI..."
    force usedxauth

    echo && prompt "<Force CLI> Will create custom field..."
    force rest post tooling/sobjects/CustomField assets/fieldCreate.json

    echo && prompt "<Force CLI> Will import metadata using Force CLI..."
    force import -d assets/md

    echo && prompt "Execute source tracking work around..."
    sfdx force:data:soql:query -q "SELECT Id FROM SourceMember" --json -t > memberquery.json
    echo "<Force CLI> Patching the source member objects..."
    for row in $(cat memberquery.json | jq .result.records[].Id); do
    eval 'force rest patch "tooling/sobjects/SourceMember/'$( echo $row | tr -d '"' )'"' assets/smupdate.json
    echo ""
    done
    return
}

forceAddAccounts() {
    echo "<Force CLI> Create an Account with location infomation..."
    force record create Account Name:"Marriott Marquis" Location__Longitude__s:-122.403405 Location__Latitude__s:37.785143
    echo "<Force CLI> Create an Account with location infomation..."
    force record create Account Name:"Hilton Union Square" Location__Longitude__s:-122.410137 Location__Latitude__s:37.786164
    echo "<Force CLI> Create an Account with location infomation..."
    force record create Account Name:"Hyatt" Location__Longitude__s:-122.396311 Location__Latitude__s:37.794157
}

getAccountLocatorContent() {
    cat assets/templates/AccountLocator.cmp > force-app/main/default/aura/AccountLocator/AccountLocator.cmp
    cat assets/templates/AccountLocator.css > force-app/main/default/aura/AccountLocator/AccountLocator.css
    return
}

forceCreateTab() {
    echo "<Force CLI> Creating custom tab for the lightning component..."
    force rest post tooling/sobjects/CustomTab  assets/templates/customtab/customTab.json

    echo "<Force CLI> Push updated profile for Admin to see new tab..."
    force push -f assets/templates/customtab/profiles/Admin.profile
    return
}

addAccountListContent() {
    cat assets/templates/AccountListItem.cmp > force-app/main/default/aura/AccountListItem/AccountListItem.cmp
    cat assets/templates/AccountListItem.css > force-app/main/default/aura/AccountListItem/AccountListItem.css
    cat assets/templates/AccountList.cmp > force-app/main/default/aura/AccountList/AccountList.cmp
    cat assets/templates/AccountList.css > force-app/main/default/aura/AccountList/AccountList.css
    cat assets/templates/AccountListController.js > force-app/main/default/aura/AccountList/AccountListController.js
    cat assets/templates/AccountLocator2.cmp > force-app/main/default/aura/AccountLocator/AccountLocator.cmp
    return
}

cleanUpAfterForce() {
    rm -rf metadata
    rm -rf src
    return
}
