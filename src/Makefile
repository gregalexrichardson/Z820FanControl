obj-m += hp_wmi_sensors.o

KVER ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVER)/build

ifneq ($(shell grep -q '^CONFIG_CC_IS_CLANG=y' $(KDIR)/include/config/auto.conf 2>/dev/null && echo y),)
KERNEL_CC_ARGS := CC=clang LLVM=1
endif

.PHONY: all clean

all:
	$(MAKE) -C $(KDIR) $(KERNEL_CC_ARGS) M=$(CURDIR) modules

clean:
	$(MAKE) -C $(KDIR) $(KERNEL_CC_ARGS) M=$(CURDIR) clean
