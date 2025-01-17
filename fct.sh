#!/usr/bin/env bash

EOC="\e[0m"
BOLD="\e[1m"
RED="\e[91m"
GREEN="\e[92m"
YELLOW="\e[93m"
DBLUE="\e[94m"
PURPLE="\e[95m"
CYAN="\e[96m"
DGREY="\e[1;90m"

incl_path="../"
srcs="srcs"

CC="clang++"
CFLAGS="-Wall -Wextra -Werror -std=c++98"
# CFLAGS+=" -fsanitize=address -g3"

function pheader () {
printf "${EOC}${BOLD}${DBLUE}\
# ****************************************************************************** #
#                                                                                #
#                                :::   :::   :::                                 #
#                              :+:+: :+:+:  :+: :+:                              #
#                            +:+ +:+:+ +:+ +:+                                   #
#                           +#+  +:+  +#+ +#+ +#+                                #
#                          +#+       +#+ +#+ #+#                                 #
#                         #+#       #+# #+# #+#                                  #
#                        ###       ### ### ###  containers_test                  #
#                                                                                #
# ****************************************************************************** #
${EOC}"
}

compile () {
	# 1=file 2=define used {ft/std} 3=output_file 4?=compile_log
	macro_name=$(echo "USING_${2}" | awk '{ print toupper($0) }')
	compile_cmd="$CC $CFLAGS -o ${3} -I./$incl_path -D ${macro_name} ${1}"
	if [ -n "$4" ]; then
		compile_cmd+=" &>${4}"
	fi
	eval "${compile_cmd}"
	return $?
}

getEmoji () {
	# 1=integer
	emoji='';
	case $1 in
		0) emoji="${GREEN}✅";;
		1) emoji="${RED}❌";;
		2) emoji="${YELLOW}⚠️ ";;
	esac
	printf "${BOLD}${emoji}${EOC}"
}

getYN () {
	# 1=integer
	res='';
	case $1 in
		0) res="Y";;
		1) res="N";;
	esac
	printf "${res}"
}

getTime() {
	printf "${GREEN}$1${EOC}"
}

printRes () {
	# 1=file 2=compile 3=bin 4=output 5=std_compile
	# 6=time data (raw)
	printf "%-35s: COMPILE: %s | RET: %s | OUT: %s | STD: [%s] | TIME: %s\n" \
		"$1" "$(getEmoji $2)" "$(getEmoji $3)" "$(getEmoji $4)" "$(getYN $5)" "$(getTime $6)"
}

# If diff_file empty, return 0 -> ok
# If diff is about max_size, return 2 -> warning
# Else, diff is something really important, return 1 -> error
compare_output () {
	# 1=diff_file
	if ! [ -s $1 ]; then
		return 0
	fi
	regex=$(cat <<- EOF
	^[0-9]*c[0-9]*
	< max_size: [0-9]*
	---
	> max_size: [0-9]*$
	EOF
	)

	cat $1 | grep -v -E -q "$regex"
	[ "$?" -eq "0" ] && return 1 || return 2;
}

isEq () {
	[ $1 -eq $2 ] && echo 0 || echo 1
}

cmp_one () {
	# 1=path/to/file

	deepdir="deepthought"; logdir="logs"
	mkdir -p $deepdir $logdir
	container=$(echo $1 | cut -d "/" -f 2)
	file=$(echo $1 | cut -d "/" -f 3)
	testname=$(echo $file | cut -d "." -f 1)
	ft_bin="ft.$container.out"; ft_log="$logdir/ft.$testname.$container.log"
	std_bin="std.$container.out"; std_log="$logdir/std.$testname.$container.log"
	diff_file="$deepdir/$testname.$container.diff"

	clean_trailing_files () {
		rm -f $ft_bin $std_bin
		[ -s "$diff_file" ] || rm -f $diff_file $ft_log $std_log &>/dev/null
		rmdir $deepdir $logdir &>/dev/null
	}

	$CC $CFLAGS -o timeus.out srcs/time.cpp

	compile "$1" "ft"  "$ft_bin"  /dev/null; ft_ret=$?
	compile "$1" "std" "$std_bin" /dev/null; std_ret=$?
	same_compilation=$(isEq $ft_ret $std_ret)
	std_compile=$std_ret

	> $ft_log; > $std_log;
	if [ $ft_ret -eq 0 ]; then
		ft_time_start=`./timeus.out`
		./$ft_bin &>$ft_log; ft_ret=$?
		ft_time_end=`./timeus.out`
	fi
	if [ $std_ret -eq 0 ]; then
		std_time_start=`./timeus.out`
		./$std_bin &>$std_log; std_ret=$?
		std_time_end=`./timeus.out`
	fi
	same_bin=$(isEq $ft_ret $std_ret)

	diff -U3 $std_log $ft_log 2>/dev/null 1>"$diff_file";
	compare_output $diff_file
	same_output=$?

	time_ft=`bc <<< "scale=3; $((${ft_time_end}-${ft_time_start}))/1000"`
	time_std=`bc <<< "scale=3; $((${std_time_end}-${std_time_start}))/1000"`
	if [ $std_compile -eq 0 ]; then
		time_res=`bc <<< "scale=2; ${time_ft}/${time_std}"`
		time_mult=`printf "%0.2fx" ${time_res}`
	else
		time_mult="${time_ft}ms"
	fi

	printRes "$container/$file" $same_compilation $same_bin $same_output $std_compile $time_mult
	clean_trailing_files
}

do_test () {
	# 1=container_name
	test_files=$(find "${srcs}/${1}" -type f -name '*.cpp' | sort)

	for file in ${test_files[@]}; do
		cmp_one "${file}"
	done
}

function main () {
	pheader
	containers=(vector map stack set)
	# containers=(vector list map stack queue deque multimap set multiset)
	if [ $# -ne 0 ]; then
		containers=($@);
	fi

	for container in ${containers[@]}; do
		printf "%40s\n" $container
		do_test $container 2>/dev/null
	done
}
