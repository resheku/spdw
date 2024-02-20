#!/bin/bash
py_command="import json,sys;
[print(json.dumps(i)) for i in json.loads(sys.stdin.read())['data'] if i['status']['id'] == 1]"

echo "CHANGED FILES"
for file in $(git diff --name-only --diff-filter=M HEAD^ HEAD); do
    # check if the file exists and is a json file
    if [[ -e "$file" && "$file" == *.json ]]; then
        echo $file;
        # get the hashes of the commits that modified the file excet the most recent one
        hash=$(git log -n 2 --pretty=format:%h -- $file | tail -n 1);
        diff -e <(git show "$hash:$file" | python -c "$py_command") \
        <(python -c "$py_command" < $file) \
        | sed '1d;$d' | tee -a CHANGES;
    fi
done

echo "ADDED FILES"
for file in $(git diff --name-only --diff-filter=A HEAD^ HEAD); do
    if [[ -e "$file" && "$file" == *.json ]]; then
        echo $file;
        python -c "$py_command" < $file | tee -a CHANGES;
    fi;
done
