#! @bash@

usage() {
    read -r -d '' usage << EOF
Replace an executable with a wrapped variant
wrapProgram <PROGRAM> ARGS

ARGS:
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

source @out@/libexec/die.sh
source @out@/libexec/make-wrapper.sh

if [[ $# -lt 1 ]]
then
    usage
    exit 1
fi

wrapProgram $@
