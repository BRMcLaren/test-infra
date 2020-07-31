# Experimental
az group create \
    --output table \
    --name OE-Prow-Jenkins-Testing \
    --location uksouth

az vm create \
    --output table \
    --resource-group OE-Prow-Jenkins-Testing \
    --location uksouth \
    --name jenkins-master-testing \
    --size Standard_DS3_v2 \
    --os-disk-size-gb 128 \
    --data-disk-sizes-gb 512 \
    --image Canonical:UbuntuServer:18_04-lts-gen2:latest \
    --accelerated-networking true \
    --nsg-rule SSH \
    --admin-username oeadmin \
    --ssh-key-value ~/.ssh/id_rsa.pub

NIC_ID=`az vm show --resource-group OE-Prow-Jenkins-Testing \
                    --name jenkins-master-testing \
                    --output tsv \
                    --query "networkProfile.networkInterfaces[0].id"`

NSG_ID=`az network nic show --ids $NIC_ID \
                            --output tsv \
                            --query "networkSecurityGroup.id"`

NSG_NAME=`az network nsg show --ids $NSG_ID \
                                --output tsv \
                                --query "name"`

az network nsg rule create --resource-group OE-Prow-Jenkins-Testing \
                            --nsg-name $NSG_NAME \
                            --name Port_443 \
                            --priority 500 \
                            --access Allow \
                            --direction Inbound \
                            --protocol Tcp \
                            --destination-port-ranges 443

az network nsg rule create --resource-group OE-Prow-Jenkins-Testing \
                            --nsg-name $NSG_NAME \
                            --name Port_80 \
                            --priority 501 \
                            --access Allow \
                            --direction Inbound \
                            --protocol Tcp \
                            --destination-port-ranges 80

NIC_ID=`az vm show --resource-group OE-Prow-Jenkins-Testing \
                    --name jenkins-master-testing \
                    --output tsv \
                    --query "networkProfile.networkInterfaces[0].id"`

PUBLIC_IP_ID=`az network nic show --ids $NIC_ID \
                                    --output tsv \
                                    --query "ipConfigurations[0].publicIpAddress.id"`

az network public-ip update --ids $PUBLIC_IP_ID \
                            --dns-name oe-prow-jenkins-testing \
                            --idle-timeout 30
