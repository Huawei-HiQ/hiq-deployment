declare -A dependencies=(
    ["xenial"]="libopenmpi1.10 libgflags2v5 libgoogle-glog0v5 libhwloc5"
    ["bionic"]="libopenmpi2 libgflags2.2 libgoogle-glog0v5 libhwloc5"
    ["eoan"]="libopenmpi3 libgflags2.2 libgoogle-glog0v5 libhwloc5"
    ["focal"]="libopenmpi3 libgflags2.2 libgoogle-glog0v5 libhwloc15"
    ["groovy"]="libopenmpi3 libgflags2.2 libgoogle-glog0v5 libhwloc15")


boost_dependencies=("libboost-system"
		    "libboost-thread"
		    "libboost-mpi"
		    "libboost-program-options")

declare -A boost_versions=(["xenial"]="1.58.0"
			   ["bionic"]="1.65.1"
			   ["eoan"]="1.67.0"
			   ["focal"]="1.71.0"
			   ["groovy"]="1.71.0")

# usage: change_control_dependencies $ubuntu_distro path/to/control
change_control_dependencies()
{
    ubuntu=$1
    control=$2

    # Delete 'Depends:' secion
    sed_args=(-e '/^Depends:/,/^Description/{/^Depends:/!{/^\Description/!d}}'
	      -e '/^Depends:/d')

    var='Depends: '
    for lib in ${global_dependencies[@]}; do
	var="$var$lib,\n\t"
    done
    
    for lib in ${dependencies[$ubuntu]}; do
	var="$var$lib,\n\t"
    done

    # Requires Bash >= 4.2
    for lib in ${boost_dependencies[@]::${#boost_dependencies[@]}-1}; do
    	var="$var$lib${boost_versions[$ubuntu]},\n\t"
    done
    var="$var${boost_dependencies[-1]}${boost_versions[$ubuntu]}"

    sed_args+=(-e "/Architecture:/ a $var")

    sed -i "${sed_args[@]}" $control
}

