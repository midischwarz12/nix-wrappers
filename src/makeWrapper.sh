#! @bash@

usage() {
    read -r -d '' usage << EOF
Construct an executable file that wraps the actual executable
makeWrapper EXECUTABLE OUT_PATH ARGS

ARGS:
--argv0        NAME    : set the name of the executed process to NAME
                         (if unset or empty, defaults to EXECUTABLE)
--inherit-argv0        : the executable inherits argv0 from the wrapper.
                         (use instead of --argv0 '$0')
--resolve-argv0        : if argv0 doesn't include a / character, resolve it against PATH
--set          VAR VAL : add VAR with value VAL to the executable's environment
--set-default  VAR VAL : like --set, but only adds VAR if not already set in
                         the environment
--unset        VAR     : remove VAR from the environment
--chdir        DIR     : change working directory (use instead of --run "cd DIR")
--run          COMMAND : run command before the executable
--add-flag     ARG     : prepend the single argument ARG to the invocation of the executable
                         (that is, *before* any arguments passed on the command line)
--append-flag  ARG     : append the single argument ARG to the invocation of the executable
                         (that is, *after* any arguments passed on the command line)
--add-flags    ARGS    : prepend ARGS verbatim to the Bash-interpreted invocation of the executable
--append-flags ARGS    : append ARGS verbatim to the Bash-interpreted invocation of the executable

--prefix          ENV SEP VAL   : suffix/prefix ENV with VAL, separated by SEP
--suffix
--prefix-each     ENV SEP VALS  : like --prefix, but VALS is a list
--suffix-each     ENV SEP VALS  : like --suffix, but VALS is a list
--prefix-contents ENV SEP FILES : like --suffix-each, but contents of FILES
                                  are read first and used as VALS
--suffix-contents
EOF

    echo "$usage" >&2
}

source @out@/libexe/die.sh
source @out@/libexe/make-wrapper.sh

if [[ $# -lt 2 ]]
then
    usage
    exit 1
fi

makeWrapper $@
