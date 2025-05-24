MKF_PATH := $(lastword $(abspath $(MAKEFILE_LIST)))
MKF_DIR := $(patsubst %/,%,$(dir $(MKF_PATH)))

YABAI_CONFIG_DIR := $(HOME)/.config/yabai

HAMMERSPOON_PATH := $(HOME)/.hammerspoon
SOURCE_PATH := $(MKF_DIR)/src
HAMMERSPOON_SOURCE_FILES := $(notdir $(wildcard $(SOURCE_PATH)/*.lua))
HAMMERSPOON_TARGET_FILES := $(addprefix $(HAMMERSPOON_PATH)/,$(notdir $(wildcard $(SOURCE_PATH)/*.lua)))

# Link all the lua files in the src directory to the hammerspoon config dir
.PHONY: setup
setup: $(HAMMERSPOON_TARGET_FILES) $(YABAI_CONFIG_DIR)/yabairc ;

$(HAMMERSPOON_PATH)/%.lua: $(SOURCE_PATH)/%.lua
	ln -sf $(SOURCE_PATH)/$*.lua $@
	touch $(SOURCE_PATH)/$*.lua

$(YABAI_CONFIG_DIR):
	mkdir -p $@

$(YABAI_CONFIG_DIR)/yabairc: $(YABAI_CONFIG_DIR) $(SOURCE_PATH)/yabairc
	ln -sf $(SOURCE_PATH)/yabairc $@
	touch $(SOURCE_PATH)/yabairc
