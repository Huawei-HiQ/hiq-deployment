#! /bin/bash

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

os_name=$(cat /etc/os-release | grep ID= | sort | head -n1 | cut -d '=' -f2 | tr -d '"')
os_ver=$(cat /etc/os-release | grep VERSION_ID | cut -d '=' -f2 | tr -d '"')

srpms_root=$HERE/../srpms
nowait=0
background=0
dry_run=0

# ==============================================================================

die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
no_arg() {
    if [ -n "$OPTARG" ]; then die "No arg allowed for --$OPT option"; fi; }
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

python_setup() { python3 setup.py $1 2> /dev/null; }

help_message() {
    echo -e '\nUsage:'
    echo "  " `basename $0` "[options] packages"
    echo -e '\nOptions:'
    echo '  -h,--help        Show this help message and exit'
    echo '  -n,--dry-run     Do not actually submit the jobs'
    echo '                   (only print the commands)'
    echo '  --os-name [name] Use [name] instead of deduced OS name'
    echo '  --os-ver [ver]   Use [ver] instead of deduced OS version'
    echo '  --parallel       Execute build in parallel (implies --nowait)'
    echo '  --nowait         Do not wait for build (passed onto copr-cli)'
    echo '  --background     Mark the build as a background job. It will have'
    echo '                   lesser priority than regular builds.'
    echo '                   (passed onto copr-cli)'
}

# ------------------------------------------------------------------------------

while getopts hn-: OPT; do
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi

  case "$OPT" in
      h | help )           no_arg;
		           help_message >&2
		           exit 1 ;;
      n | dry-run )        no_arg;
		           dry_run=1
		           ;;
      parallel | nowait )  no_arg;
		           nowait=1
			   ;;
      background )         no_arg;
			   background=1
			   ;;
      os-name )            needs_arg;
			   os_name=$OPTARG
			   ;;
      os-ver )             needs_arg;
			   os_ver=$OPTARG
			   ;;
      ??* )                die "Illegal option --OPT: $OPT" ;;
      \? )                 exit 2 ;;
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

# ------------------------------------------------------------------------------

copr_repo="$1"
shift

repo_chroot=("$1")
shift

# ==============================================================================

source $HERE/functions.bash

chroots_known=$(copr-cli list-chroots)

args=()
if [ $nowait -eq 1 ]; then
    args+=(--nowait)
fi
if [ $background -eq 1 ]; then
    args+=(--background)
fi

args+=($copr_repo)
for chroot in ${repo_chroot[@]}; do
    for name in $(echo "$chroots_known" | grep $chroot); do
	args+=(-r $name)
    done
done

arch_name=$(get_arch_name)
srpms=$(ls $srpms_root/*.src.rpm | grep -- $arch_name)

pkg_args=()
for rpm in "$@"; do
    rpm=$(echo "$srpms" | grep -i $rpm)
    if [ -n "$rpm" ]; then
	pkg_args+=($rpm)
    fi
done

if [ -n "${pkg_args[*]}" ]; then
    ECHO=
    if [ $dry_run -ne 0 ]; then
	ECHO=echo
    fi
    $ECHO copr-cli build "${args[@]}" "${pkg_args[@]}"
fi

# ==============================================================================
