ARCHS := armv7 arm64
TARGET := iphone:clang::8.0

include theos/makefiles/common.mk

TWEAK_NAME = FadeInLSClock
FadeInLSClock_FILES = Tweak.xm
FadeInLSClock_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
