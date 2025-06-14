#!/bin/sh

./xilinx-qemu/build/qemu-system-aarch64 -M arm-generic-fdt-7series -m 1G \
    -kernel ./buildroot/output/images/uImage \
    -dtb ./qemu-res/zynq-zc702-cosim.dtb \
    -initrd ./buildroot/output/images/rootfs.cpio.gz \
    -serial /dev/null -serial mon:stdio -display none \
    -machine-path /tmp/ \
    -sync-quantum 1000000 -icount 0 \
    -rtc clock=vm \
    -net nic -net nic -net user,id=eth0,hostfwd=udp::1234-:1234
