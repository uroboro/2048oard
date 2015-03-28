include theos/makefiles/common.mk

TWEAK_NAME = 2048oard
2048oard_FILES = Listener.xm
2048oard_FRAMEWORKS = UIKit CoreGraphics
2048oard_LIBRARIES = activator

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	#PreferenceLoader plist
	$(ECHO_NOTHING)if [ -f Preferences.plist ]; then mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/2048oard; cp Preferences.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/2048oard/; fi$(ECHO_END)

after-install::
	install.exec "killall -9 backboardd || killall -9 SpringBoard"
