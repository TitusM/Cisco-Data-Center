*** Settings ***
Library  SSHLibrary

*** Variables ***
${HOST}      10.62.130.142
${USERNAME}  tmajeza
${PASSWORD}  


*** Test Cases ***
Check All Nexus Interface Status
    Open Connection    ${HOST}
    Login              ${USERNAME}     ${PASSWORD}

    Write     terminal length 0
    Sleep     1
    ${_}=     Read

    Write     show interface status
    Sleep     2s
    ${output}=  Read

    Log      ${output}

    Should Not Contain    ${output}    xcvrAbsen

    Write     exit 
    Close Connection


