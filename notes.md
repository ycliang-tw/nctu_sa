# Notes
## Shell Programming
+ [2>&1 explained](http://ibookmen.blogspot.com/2010/11/unix-2.html)
	+ we could use [strace](https://unix.stackexchange.com/questions/467407/is-there-a-way-to-use-strace-to-trace-different-parts-of-a-command-pipeline) to observe the behavior
```shell==
$> strace -ff -o log.txt sh -c 'ls > file.txt 2>&1'
$> vim log.txt.<pid>
...
open("file.txt", O_WRONLY|O_CREAT|O_TRUNC, 0666) = 3		// fd 3 points to file.txt
dup2(3, 1)                              = 1					// fd 1 points wherever fd 3 points ( file.txt here ) // if fd 1 already points elsewhere, this op will close it silently then redirects it. see man dup2.
close(3)                                = 0					// close fd 3
dup2(1, 2)                              = 2					// fd 2 points wherever fd 1 points ( file.txt here )
fcntl(1, F_GETFD)                       = 0
execve("/usr/bin/ls", ["ls"], [/* 53 vars */]) = 0
...

$> strace -ff -o log.txt sh -c 'ls 2>&1 >file.txt'
$> vim log.txt.<pid>
...
dup2(1, 2)                              = 2					// fd 2 points wherever fd 1 points ( stdout here )
fcntl(1, F_GETFD)                       = 0
open("file.txt", O_WRONLY|O_CREAT|O_TRUNC, 0666) = 3		// fd 3 points to file.txt
dup2(3, 1)                              = 1					// fd 1 points wherever fd 3 points ( file.txt )
close(3)                                = 0					// close fd 3
execve("/usr/bin/ls", ["ls"], [/* 53 vars */]) = 0
...
```

+ [redirection and pipe](https://stackoverflow.com/questions/2342826/how-to-pipe-stderr-and-not-stdout)
```
## only pipes stderr

$> exec 3>&1	# store stdout in fd 3
$> ls /root/ /etc/fstab 2>&1 1>&3 | tr a-z A-Z	# pipe only stderr, redirect stdout to fd 3
$> exec 3>&-	# close fd 3
```
Couldn't figure out why the above example worked. Thought that it would form a loop because first we had "3>&1" then "1>&3".
The conclusion. It works because pipe will be set up before redirection command.
Redirection will be evaluated later.

First we have "exec 3>&1", that opens a new fd 3 then redirects it to fd 1 (stdout).
> something like will occur `dup2(1, 3) # return value 3`
Second, we have a pipe here, so it is being processed first.
> `pipe(fd[2]), dup2(fd[0], 1) for ls, dup2(fd[1], 0) for tr`
At this point the fd 1 is already being redirected to the pipe's input,
thus the next operation of '2>&1' is actually redirecting fd 2 to pipe's input as well.
Then restores fd 1 to fd 3 (stdout). No loop is ever created!

+ [dialog tutorial](http://linuxcommand.org/lc3_adv_dialog.php)
Dialog is an utility that displays dialog boxes for shell script.
The result of manipulation in dialog will be outputed through stderr by default.
see man 1 dialog
```
## example of how to manipulate the result of dialog
#!/bin/bash
exec 3>&1
result=`dialog --menu "choose" 30 60 5 1 "Yes" 2 "No" 2>&1 1>&3`
exec 3>&-
case $result in
	"1")
		;;
	"2")
		;;
	*)
		;;
esac
```
\`\`: command substitution will do somethin like pipe to get the output, so here the example script works just like the previous example.
we could get the result through stderr after the redirections are done.

+ [remove leading space](https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable)
```shell==
$> sed 's/^[[:space:]]*//g' <data>

## [:space:]: regex of space
## [[:space:]]: matches only one space
```
	+ [how to match spaces with regex](https://stackoverflow.com/questions/28256178/how-can-i-match-spaces-with-a-regexp-in-bash/28256343)

### keyword
+ process substitution `<( command )`
+ command substitution `\`\``, `$()`
+ here-string `<<<`
+ array `arr=(ele1 ele2)`, `declare -a|-A`
+ zenity (GNOME enviroment)

## Unix Related
### keyword
+ [line discipline](https://blog.csdn.net/dog250/article/details/78818612)
	+ Tmux, Screen

