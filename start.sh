name=$1
forcebuild=$2
if [[ $name == "forcebuild" ]]
then
    name=''
    forcebuild='forcebuild'
fi

if [[ -z $name ]]
then
    printf "\nAssuming default name is: merlin-tmcrego\n"
    name='merlin-tmcrego'
fi

isexists=$(docker images | grep "\<$name\>")
if [[ -z $isexists || $forcebuild == "forcebuild" ]]
then
    docker build . -t $name
fi
docker run -it --rm -v ${PWD}:/root/ --add-host kubernetes:127.0.0.1 --name $name $name