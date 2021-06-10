# Requires Bash >= 4
declare -A ubuntu_versions=(["xenial"]="16.04"
			    ["bionic"]="18.04"
			    ["eoan"]="19.10"
			    ["focal"]="20.04"
			    ["groovy"]="20.10"
			    ["hirsute"]="21.04"
			    ["impish"]="21.10")
assume_yes=0
clean_dirs=0
clean_only=0
ubuntu_distro=''
output_dir=''

# ==============================================================================

die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
no_arg() {
    if [ -n "$OPTARG" ]; then die "No arg allowed for --$OPT option"; fi; }
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

python_setup() { python3 setup.py $1 2> /dev/null; }

help_message() {
    echo -e '\nUsage:'
    echo "  " `basename $0` "[options] pkg_name [debuild options]"
    echo -e '\nOptions:'
    echo '  -h,--help          Show this help message and exit'
    echo '  -c,--clean         (optional) start from clean folder'
    echo '  --clean-only       (optional) only perform clean step'
    echo '  -d,--distro [rel]  Specify for which Ubuntu distro the package is'
    echo '                     designed for (supported are: ${!ubuntu_versions[@]})'
    echo '  -o,--output [dir]  (optional) Specify output directory for generated'
    echo '                     files (*.changes, *.dsc, etc.)'
    echo "                     Defaults to: $(realpath $root)"
    echo '  -r,--root [dir]    (optional) Specify location to extract archives'
    echo '                     to'
    echo "                     Defaults to: $(realpath $root)"
    echo '  -y,--yes           Assume yes to all prompts'
    echo ''
    echo 'Any options passede *after* the package name will be forwarded to'
    echo '`debuild`'
    echo -e '\nExample calls:'
    if [[ "$0" =~ dep.bash$ ]]; then
	echo "$0 -d eoan -y urllib3"
	echo "$0 -d xenial -o /tmp/data cython -S -sd"
    else
	echo "$0 -d eoan -y hiq-projectq"
	echo "$0 -d xenial -o /tmp/data hiq-circuit -S -sd"
    fi
}

# ------------------------------------------------------------------------------

while getopts hcyo:r:d:-: OPT; do
    if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
	OPT="${OPTARG%%=*}"       # extract long option name
	OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
	OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
    fi

    case "$OPT" in
	h | help )    no_arg;
		      help_message >&2
		      exit 1 ;;
	c | clean )   no_arg;
		      clean_dirs=1
		      ;;
	clean-only )  no_arg;
		      clean_only=1
		      ;;
	d | distro )  needs_arg;
		      ubuntu_distro=$OPTARG
		      ;;
	o | output )  needs_arg;
		      output_dir=$OPTARG
		      ;;
	r | root )    needs_arg;
		      root=$OPTARG
		      ;;
	y | yes )     no_arg;
		      assume_yes=1
		      ;;
	??* )           die "Illegal option --OPT: $OPT" ;;
	\? )            exit 2 ;;  # bad short option (error reported via getopts)
    esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

# ------------------------------------------------------------------------------

pkg=$1
shift
args=("$@")

# Get Ubuntu distro name and version number
if [ -z "$ubuntu_distro" ]; then
    die "Missing -d,--distro!"
fi
ubuntu_distro_num=${ubuntu_versions[$ubuntu_distro]}
if [ -z "$ubuntu_distro_num" ]; then
    die "Invalid distro name: $ubuntu_distro (allowed values: ${!ubuntu_versions[@]})"
fi

# ==============================================================================

if [ ! -f $HERE/../setup_env.bash ]; then
    die "Missing $HERE/../setup_env.bash"
fi
source $HERE/../setup_env.bash
source $HERE/functions.bash

# ------------------------------------------------------------------------------

if [ -z "$DEBFULLNAME" ]; then
    die "Please define the DEBFULLNAME environment variable (e.g. 'John Doe')"
fi
if [ -z "$DEBEMAIL" ]; then
    die "Please define the DEBEMAIL environment variable (e.g. 'john@example.com')"
fi

if python3 -m pip > /dev/null; then
    :
else
    die "Unable to find the Python pip module!"
fi

# ==============================================================================
