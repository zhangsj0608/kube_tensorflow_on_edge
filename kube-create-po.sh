#/bin/bash
#This script is used to create pods on k8 clusters

# directories and scripts
baseDir=$(pwd)
podSourcesDownloadScript="pod-sources-download.sh"
psJobStartScript=""
workerJobStartScript=""

# local variables
pod_IP_Status=""
ps_IPs=""
worker_IPS=""
port="2222"


#
# check the directory is exist
#
echo "#######################################"
if [ -d $baseDir ]; then
    echo "[INFO] The working directory is $baseDir"
else
    echo "[ERRO] Workding directory $baseDir error" >2 
fi

#
# extract all ps-, worker- yaml files, and create the 
# pods with kubectl ...
yamlFiles=""
cd ${baseDir}/sources/kubernetes #Changing workding directory
for file in $(ls)
do  
    # find the ps-,worker-,ps-svc-,worker-svc.yaml
    if [[ "$file" =~ ^((ps)|(worker))((-|_)(svc))?\.yaml$ ]] ; then
        yamlFiles=${yamlFiles}${file}" "
        kubectl create -f $file
    fi
done 
echo "[INFO] the yamlFiles include: $yamlFiles"


# here we wait seconds for the initialization of pods and services,
# and then, get the information of pods and services and ensure
# them working properly
# 
started="false"
while [ ${started} == "false" ]
do 
    sleep 1
    pod_IP_Status=$(kubectl get pods -o wide | gawk '$1 ~ /^tensorflow/{
    
        print $1":"$6":"$3
     
    }')
    for status_string in ${pod_IP_Status} 
    do
        echo "${status_string}"
        if ! [[ ${status_string} =~ Running$ ]]
        then
            echo "status_string=${status_string}"
            started="false"       
            break
        fi
        started="true"
    done 
    echo ${started}
done

ps_IPs_=$(kubectl get pods -o wide | gawk '$1 ~ /^tensorflow-ps/ {

    print $6":"podPort

}' podPort=$port)
worker_IPs_=$(kubectl get pods -o wide | gawk '$1 ~ /^tensorflow-worker/{

    print $6":"podPort

}' podPort=$port)

## formulate the ps_IPs, and worker_IPs, replace '/n' to ','
ps_IPs=$(echo ${ps_IPs_} | sed -n 's/ /,/g p')
worker_IPs=$(echo ${worker_IPs_} | sed -n 's/ /,/g p')

if [ -z ${ps_IPs} ]
then 
    ps_IPs=${ps_IPs_}
fi

if [ -z ${worker_IPs} ]
then 
    worker_IPs=${worker_IPs_}
fi


echo "#######################################"
echo -e "[INFO] Tensorflow pods information: \n$pod_IP_Status"
echo -e "[INFO] Tensorflow pods IPs: \nps_IPs:\
         \n$ps_IPs \nworker_IPs: \n$worker_IPs"
echo "#######################################"

# dealing with the ps-Pods and worker-pods by ssh to pods, downloading the needed
# files and packages, running the .py files respectively 
#

# IFS.OLD=$IFS
ps_pattern="^tensorflow-ps"
worker_pattern="^tensorflow-worker"
ps_index=0
worker_index=0
# changing the working directory to the base directory
cd ${baseDir}

for podInfo in $pod_IP_Status
do 
    podIndex=1
    # get the Parameter Server(PS) pod name from the psPodInfo
    pod=$(echo $podInfo | gawk -f getPod.gawk n=$podIndex)

    # exec in the pods to (see it in the podSourcesDownLoad script)
    # 1. download the source codes
    # 2. start and run a PS or Worker job in the background
    cat $podSourcesDownloadScript | kubectl exec -i $pod -- /bin/bash -s

    # exec to the pods to execute the source codes
    if [[ $pod =~ $ps_pattern ]]
    then
        # this is a ps pod, so we start the ps job
        commandStr="cd tensorflow_template_application-master/distributed/ \n
                    nohup python dense_classifier.py \
                   --ps_hosts=$ps_IPs \
                   --worker_hosts=$worker_IPs --job_name=ps \
                   --task_index=$ps_index &" 
        echo -e $commandStr | kubectl exec -i $pod -- /bin/bash -s &>logs/log.${pod} &
        ps_index=$[ $ps_index + 1 ]
    else
#        continue
        if [[ $pod =~ $worker_pattern ]]
        then
            # this is a worker pod, so we start the worker job   
            commandStr="cd tensorflow_template_application-master/distributed/ \n
                     nohup python dense_classifier.py \
                   --ps_hosts=$ps_IPs \
                   --worker_hosts=$worker_IPs --job_name=worker \
                   --task_index=$worker_index &"
            echo -e $commandStr | kubectl exec -i $pod -- /bin/bash -s &>logs/log.${pod} &
            worker_index=$[ $worker_index + 1 ]
        else
            echo "[ERROR] no such pod: $pod"
        fi
    fi
    
        
done 

