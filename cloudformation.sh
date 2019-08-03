if ! aws cloudformation describe-stacks --region $region --stack-name $client-$env-EMR ; then

  echo -e "Stack does not exist, creating\n"
  aws cloudformation create-stack \
    --region $region \
    --stack-name $client-$env-EMR \
	--capabilities CAPABILITY_IAM \
	--template-body body.yaml \
	--parameters params-$client-$env.json

  echo "Waiting for stack to be created ..."
  aws cloudformation wait stack-create-complete \
    --region $region \
    --stack-name $client-$env-EMR \

else

  echo -e "Stack exists, updating the stack\n"

  set +e
  update_output=$( aws cloudformation update-stack \
    --region $region \
    --stack-name $client-$env-EMR \
	--capabilities CAPABILITY_IAM \
	--template-body body.yaml \
	--parameters params-$client-$env.json \
	)
	
  status=$?
  set -e

  echo "$update_output"

  if [ $status -ne 0 ] ; then

    # Don't fail for no-op update
    if [[ $update_output == *"ValidationError"* && $update_output == *"No updates"* ]] ; then
      echo -e "Error creating/updating\n"
      exit 0
    else
      exit $status
    fi

  fi

  echo "Waiting for stack update to complete\n"
  aws cloudformation wait stack-update-complete \
    --region $1 \
    --stack-name $2 \

fi

echo "Finished create/update successfully!\n"
