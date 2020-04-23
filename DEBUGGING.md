# Debugging

## Using the `cpu` command

Since the stboot image running on a server has much fewer tools and services than usual Linux operating systems, the `cpu` command is the best option for debugging a remote machine. It connects to the remote server, bringing all your local tools and environment with you. It's like magic :)

### Prerequisites

These instructions expect _your system_ to be Linux-based.
You need to have the `go` programming language installed on _your system_.

It also expects you to have access to the serial console of your _remote target_.
Your _remote target_ needs port `2222` to be accessible from the outside.

### Installation

Run:

```shell
$ go get github.com/u-root/cpu/cmds/cpu
$ go install github.com/u-root/cpu/cmds/cpu
```

to install the `cpu` tool to your `$GOPATH` and thus make it available to your `$PATH`.

Now you can run it

```
$ cpu
Usage: cpu [options] host [shell command]:
  -bin string
        path of cpu binary (default "cpud")
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
$ elvish start_cpu.elv
```

This will start the `cpud` with all the required keys.

Now, on your own system run:

```
$ cpu -key path/to/your/private_key hostname.domain.com
```

So, for the testing environment for example:

```
$ cpu -key keys/cpu_keys/cpu_rsa localhost
```

This will connect you to the remote server and bring all your tools and environment with it. Be aware that this process might take up to a few minutes depending on the size of your environment and the power of the remote machine.

Enjoy!

### Testing the `cpu` command using qemu

_NOTE: Make sure you followed all the steps in section [Installation](#Installation)_

Run `./run.sh` to generate all keys and make sure the newest stboot kernel and image has been built.

Run `./start_qemu_mixed-firmware.sh`, wait 6 seconds then press <kbd>Ctrl-C</kbd> to enter the shell.

Inside the shell run `elvish start_cpu.elv` to start the `cpud` server, then open another terminal.

In the newly opened terminal run `cpu -key keys/cpu_keys/cpu_rsa localhost`. This might take a while but it should make you end up inside the qemu machine with all your local tools at hand.
