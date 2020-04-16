# Debugging

## Using the `cpu` command

Since the stboot image running on a server has much fewer tools and services than usual Linux operating systems, the `cpu` command is the best option for debugging a remote machine. It connects to the remote server, bringing all your local tools and environment with you.

### Installation

These instructions expect your system to be Linux-based. It also expects you to have access to the serial console of your remote target.

You need to have the `go` programming language installed on your system.

Run:

```shell
$ go install github.com/u-root/cpu/cmds/cpu
```

to install the cpu tool to your `$GOPATH` and thus make it available to your `$PATH`.

Now you can run it

```
$ cpu
Usage: cpu [options] host [shell command]:
  -bin string
        path of cpu binary (default "cpuserver")
  -bindover string
        : separated list of directories in /tmp/cpu to bind over / (default "/lib:/lib64:/lib32:/usr:/bin:/etc:/home")
  -d    enable debug prints
  -dbg9p
        show 9p io
  -hk string
        file for host key
  -init
        run as init (Debug only; normal test is if we are pid 1
  ...
```

### Usage

Before accessing the remote machine trough `cpu` you first need to start the cpu server. To do that, go to the serial console and press <kbd>Ctrl-C</kbd>. This will give you access to the shell. Then run:

```
$ ./run_cpu.elv
```

This will start the `cpuserver` with all the required keys.

Now, on your own system run:

```
$ cpu -key path/to/your/private_key hostname.domain.com
```

This will connect you to the remote server and bring all your tools and environment with it.
