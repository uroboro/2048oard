include theos/makefiles/common.mk

TWEAK_NAME = 2048oard
2048oard_FILES = Listener.xm functions.xm _2048oardController.xm
2048oard_FILES += SB2048Icon.xm SB2048IconView.xm
2048oard_FRAMEWORKS = UIKit CoreGraphics
#2048oard_LIBRARIES = activator

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	#PreferenceLoader plist
	$(ECHO_NOTHING)if [ -f Preferences.plist ]; then mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/2048oard; cp Preferences.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/2048oard/; fi$(ECHO_END)

after-install::
	install.exec "killall -9 backboardd || killall -9 SpringBoard"

remove:
#	local
#	@sudo apt-get remove $(THEOS_PACKAGE_NAME)
#	remote
	@exec ssh -p $(THEOS_DEVICE_PORT) root@$(THEOS_DEVICE_IP) "apt-get -y remove $(THEOS_PACKAGE_NAME)"

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
