#! /bin/sh

#########################################
# this script either activates or desactivates the access to
# sympy-live.org services, based on the first argument's value
#########################################

if [ $1 = "true" ]; then
    for f in $(grep -rl localhost /usr/share/doc/python-sympy-doc/html/); do
	sed -i 's%http://localhost%https://live.sympy.org%' $f
    done
else
    for f in $(grep -rl live.sympy.org /usr/share/doc/python-sympy-doc/html/); do
	sed -i 's%https://live.sympy.org%http://localhost%' $f
    done
fi

    
