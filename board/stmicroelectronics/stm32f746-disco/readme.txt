STM32F746 Discovery
===================

This tutorial describes how to use the predefined Buildroot
configuration for the STM32F746 Discovery evaluation platform.

Building
--------

  make stm32f746_disco_defconfig
  make

Flashing
--------

  ./board/stmicroelectronics/stm32f746-disco/flash.sh output/

It will flash the minimal bootloader, the Device Tree Blob, and the
kernel image which includes the root filesystem as initramfs.
