#!/bin/bash
client=$1
env=$2
region=$3
action=$4
stack=$5

if [[ $# -ne 1 ]]; then
    echo "Illegal number of parameters"
    exit 11
fi

template=dddd-$stack.yaml
params=$client-$env-$stack.json

if [[ $client != "client1" &&  $client != "client2" && $client != "client3" ]]; then
    echo "Invalid client $client";
    exit 22
fi

if [[ $action != "create" && $action != "delete" ]]; then
    echo "Invalid action $action"
    exit 33
fi

if [[ $stack != "base" && $stack != "emr" ]]; then
    echo "Invalid Stack"
    exit 44
fi

if [[ $action == "delete" ]]; then
    if /usr/local/bin/aws cloudformation describe-stacks --region $region --stack-name $client-$env-$stack ; then
        echo "Stack exists. Deleting $client-$env-$stack"
        /usr/local/bin/aws cloudformation delete-stack --region $region --stack-name $client-$env-$stack
        echo "Waiting for stack deletion to complete ..."
        /usr/local/bin/aws cloudformation wait stack-delete-complete --region $region --stack-name $client-$env-$stack
        echo "Deletion of stack $client-$env-$stack Successful"
        exit 0
    else
        echo "Stack $client-$env-$stack doesn't exist. Exiting"
        exit 55
    fi
fi

if [[ $action == "create" ]]; then
    if [[ ! -f "$template" || ! -f "$params" ]]; then
        echo "Required File does not exist"
        exit 66
    fi

    if ! /usr/local/bin/aws cloudformation describe-stacks --region $region --stack-name $client-$env-$stack ; then
        echo "Stack does not exist, Creating stack $client-$env-$stack"
        /usr/local/bin/aws cloudformation create-stack --region $region --stack-name $client-$env-$stack \
        --capabilities CAPABILITY_NAMED_IAM \
        --template-url https://sxcdemobucket.s3.amazonaws.com/$template \
        --parameters file://$client-$env-$stack.json
        echo "Waiting for stack to be created ..."
        /usr/local/bin/aws cloudformation wait stack-delete-complete --region $region --stack-name $client-$env-$stack
        echo "Creation of stack $client-$env-$stack Successful"
        exit 0
    else
        echo "Stack exists, Updating stack $client-$env-$stack"
        update_output=$(/usr/local/bin/aws cloudformation update-stack --region $region --stack-name $client-$env-$stack \
        --capabilities CAPABILITY_NAMED_IAM \
        --template-url https://sxcdemobucket.s3.amazonaws.com/$template \
        --parameters file://$client-$env-$stack.json)
        status=$?
        echo "$update_output"
        if [ $status -ne 0 ]; then
            if [[ $update_output == *"ValidationError"* && $update_output == *"No updates"* ]]; then
                echo "Error creating / updating"
                exit 0
            else
                exit $status
            fi
        fi
        echo "Waiting for stack to be updated ..."
        /usr/local/bin/aws cloudformation wait stack-update-complete --region $region --stack-name $client-$env-$stack
        echo "Updation of stack $client-$env-$stack Successful"
        exit 0
    fi
fi
