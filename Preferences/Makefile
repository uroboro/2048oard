ARCHS = armv7 arm64
include theos/makefiles/common.mk

BUNDLE_NAME = _2048oard
_2048oard_FILES = _2048oard.mm
_2048oard_INSTALL_PATH = /Library/PreferenceBundles
_2048oard_FRAMEWORKS = UIKit
_2048oard_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/_2048oard.plist$(ECHO_END)
