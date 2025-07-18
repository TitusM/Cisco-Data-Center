*** Settings ***
Documentation    A simple test to login a Cisco device
Library          SSHLibrary

*** Variables ***
${DEVICE_IP}           10.62.130.142
${USERNAME}            tmajeza
${PASSWORD}            C


*** Test Cases ***
SSH To Nexus and Run Show Version
    Open Connection  ${DEVICE_IP}
    Login            ${USERNAME}   ${PASSWORD}
    Enable Mode
    Enter Config Mode
    Exit Config Mode
    Close Connection

*** Keywords ***
Enable Mode
    Write   terminal length 0
    Write   show version

Enter Config Mode
    Write   conf t
    Sleep   1s
    Read

Exit Config Mode
    Write   end
    Read