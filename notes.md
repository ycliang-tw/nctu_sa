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
