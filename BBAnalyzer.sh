#!/bin/bash
echo "---------------------------------------------------------------------------"
echo "|                        BitBucket Analyzer by nobody_cares                |"
echo "---------------------------------------------------------------------------"
echo "[+] Scan initiated on $(date)"

echo "[+] Exfiltrating all Private Repositories on Bitbucket!"

read -p "[>] Enter the repository you want to scan:" repoName
echo "[>]Scanning" $repoName
echo "Please enter credentials for Private Repository scan"
read -p  "[>] Username:" userName 
read -sp "[>] Password:" passWord

for i in $(seq 1 2 30)
do
	curl -s https://api.bitbucket.org/2.0/repositories/$repoName/?page=$i -r PUT -u $userName:$passWord | jq | grep slug | cut -d ":" -f 2 | sed 's/\,//g' | sed 's/\"//g' >> repos.txt
done

echo "[+] All results saved to repos.txt"

echo "[+] Exfiltrating all users on Bitbucket!"
for i in $(seq 1 2 30)
do
	curl -s  https://api.bitbucket.org/2.0/teams/$repoName/members?page=$i -r PUT -u $userName:$passWord | jq | grep nickname | cut -d ":" -f 2 | sed 's/\,//g' | sed 's/\"//g'
done 
echo "[+] All results saved to Users.txt"

echo "[+] Scanning commits.....!"
for j in $(cat /repos.txt)
do
	for i in $(seq 1 2 10)
	do
	curl -s  https://api.bitbucket.org/2.0/repositories/$repoName/$j/commits?page=$i -r PUT -u $userName:$passWord | jq | grep parents -A 6 | grep href | cut -d ":" -f 2,3  | sed 's/\"//g' >> commits.txt
	done
done
cat commits.txt  | sed 's/api.bitbucket.org\/2.0\/repositories/bitbucket.org/g' > commits1.txt

cat commits1.txt | sed 's/commit/commits/g' > finalcommits.txt

for i in $(cat /finalcommits.txt)
do
	echo -e "[+] Harvesting Email Addresses on \n\t > $i "
	curl -s $i/raw -r PUT -u $userName:$passWord | grep -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b" 
done


for i in $(cat /finalcommits.txt)
do
	echo -e "[+] Harvesting internal IP addresses on \n\t> $i"
	curl -s $i/raw -r PUT -u $userName:$passWord | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" 
done

for i in $(cat /finalcommits.txt)
do
	echo -e "[+] Harvesting hardcoded passwords on \n\t> $i"
	curl -s $i/raw -r PUT -u $userName:$passWord | grep -e pwd -e password -e passphrase
done

for i in $(cat /finalcommits.txt)
do
	echo -e "[+] Harvesting  hardcoded tokens on \n\t> $i"
	curl -s $i/raw -r PUT -u $userName:$passWord | grep -e aws -k token -e secret -e key -e access
done

