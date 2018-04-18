#!/bin/bash
#This script is used to create pods on k8 clusters

# directories and scripts
workDir="/home/zsj/Desktop/kube_yamls"
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
if [ -d $workDir ]; then
    echo "[INFO] The working directory is $workDir"
    cd workDir #Changing workding directory
else
    echo "[ERRO] Workding directory $workDir error" >2 
fi

#
# extract all ps-, worker- yaml files, and create the 
# pods with kubectl ...
yamlFiles=""
for file in $(ls)
do  
    # find the ps-,worker-,ps-svc-,worker-svc.yaml
    if [[ "$file" =~ ^((ps)|(worker))((-|_)(svc))?\.yaml$ ]] ; then
        yamlFiles=${yamlFile}${file}" "
        kubectl create -f $file
    fi
done 
echo "[INFO] the yamlFiles include: $yamlFiles"

# here we wait seconds for the initialization of pods and services,
# and then, get the information of pods and services and ensure
# them working properly
# 
pod_IP_Status=$(kubectl get pods -o wide | gawk '$1 ~ /^tensorflow/{
    
    print $1:$6:$3
     
}')
ps_IPs=$(kubectl get pods -o wide | gawk '$1 ~ /^tensorflow-ps/ {

    print $6":"podPort

}' podPort=$port)
worker_IPs=$(kubectl get pods -o wide | gawk '$1 ~ /^tensorflow-worker/{

    print $6":"podPort

}' podPort=$port)

## formulate the ps_IPs, and worker_IPs, replace '/n' to ','
ps_IPs=$(echo ps_IPs | sed -n 's/ /,/g p')
worker_IPs=$(echo worker_IPs | sed -n 's/ /,/g p')

echo "#######################################"
echo -e "[INFO] Tensorflow pods information: \n $pod_IP_Status"
echo -e "[INFO] Tensorflow pods IPs: \n ps_IPs:\
         \n $ps_IPs \n worker_IPs: \n $worker_IPs"
echo "#######################################"

# dealing with the ps-Pods and worker-pods by ssh to pods, downloading the needed
# files and packages, running the .py files respectively 
#

IFS.OLD=$IFS
ps_pattern="^tensorflow-ps"
worker_pattern="^tensorflow-worker"
ps_index=0
worker_index=0

for podInfo in $pod_IP_Status
do 
    podIndex=1
    # get the Parameter Server(PS) pod name from the psPodInfo
    pod=$(echo $psPodInfo | gawk -f getPod.gawk n=podIndex)

    # exec in the pods to (see it in the podSourcesDownLoad script)
    # 1. download the source codes
    # 2. start and run a PS or Worker job in the background
    cat $podSourcesDownloadScript | kubectl exec -i $pod -- /bin/bash -s

    # exec to the pods to execute the source codes
    if [ $pod =~ $ps_pattern ]
    then
        # this is a ps pod, so we start the ps job
        commandStr="cd tensorflow_template_application-master/distributed/distributed/ \n
                    nohup python dense_classifier.py \
                   --ps_hosts=$ps_IPs \
                   --worker_hosts=$worker_IPs \ 
                   --job_name=ps \
                   --task_index=$job_index > log1 &"
        echo -e $commandStr | kubectl exec -i $pod -- /bin/bash -s
        ps_index=$[ $ps_index + 1 ]
    else
        if [ $pod =~ $worker_pattern ]
        then
            # this is a worker pod, so we start the worker job   
            commandStr="cd tensorflow_template_application-master/distributed/distributed/ \n
                     nohup python classifier.py \
                   --ps_hosts=$ps_IPs \
                   --worker_hosts=$worker_IPs \ 
                   --job_name=worker \
                   --task_index=$worker_index > log1 &"
            echo -e $commandStr | kubectl exec -i $pod -- /bin/bash -s
            worker_index=$[ $worker_index + 1 ]
        else
            echo "[ERROR] no such pod: $pod"
        fi
    fi
    
        
done 

