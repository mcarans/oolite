#
# This makefile is used to build the Javascript dependency for Oolite
#
# This Makefile is used to download and build the Javascript library
# for use by Oolite.
# Depending on invocation, a debug or release (default) version of the
# library will be built.
#
# To use:
# $ make -f libjs.make debug=(yes|no)

include config.make

LIBJS_SRC_DIR                    = ../mozilla-2.0/js/src
LIBJS_CONFIG_FLAGS               = --disable-shared-js
LIBJS_CONFIG_FLAGS               += --enable-threadsafe
LIBJS_CONFIG_FLAGS               += --with-system-nspr
LIBJS_CONFIG_FLAGS               += --disable-tests
ifeq ($(OO_JAVASCRIPT_TRACE),yes)
    LIBJS_CONFIG_FLAGS           += --enable-trace-jscalls
endif
LIBJS_CFLAGS                = -std=gnu89
LIBJS_CXXFLAGS              = -Wno-error=narrowing
ifeq ($(debug),yes)
    LIBJS_BUILD_DIR              = $(LIBJS_SRC_DIR)/build-debug
    LIBJS_CONFIG_FLAGS           += --enable-debug
    LIBJS_CONFIG_FLAGS           += --disable-optimize
else
    LIBJS_BUILD_DIR              = $(LIBJS_SRC_DIR)/build-release
endif
LIBJS                            = $(LIBJS_BUILD_DIR)/libjs_static.a
LIBJS_BUILD_STAMP                = $(LIBJS_BUILD_DIR)/build_stamp
LIBJS_CONFIG_STAMP               = $(LIBJS_BUILD_DIR)/config_stamp


.PHONY: all
all: $(LIBJS)

$(LIBJS): $(LIBJS_BUILD_STAMP)

$(LIBJS_BUILD_STAMP): $(LIBJS_CONFIG_STAMP)
	@echo
	@echo "Building Javascript library..."
	@echo
	$(MAKE) -C $(LIBJS_BUILD_DIR)
	touch $@

$(LIBJS_CONFIG_STAMP):
	@echo
	@echo "Configuring Javascript library..."
	@echo
	mkdir -p $(LIBJS_BUILD_DIR)
	cd $(LIBJS_BUILD_DIR) && CC="gcc $(LIBJS_CFLAGS)" CFLAGS="$(LIBJS_CFLAGS)" CXXFLAGS="$(LIBJS_CXXFLAGS)" ../configure $(LIBJS_CONFIG_FLAGS)
	touch $@

.PHONY: clean
clean:
	-$(MAKE) -C $(LIBJS_BUILD_DIR) clean
	-$(RM) $(LIBJS_BUILD_STAMP)

# This target also removes the configuration status, forcing
# a reconfiguration. Use this after changing LIBJS_CONFIG_FLAGS
.PHONY: distclean
distclean:
	-$(RM) -r $(LIBJS_BUILD_DIR)
