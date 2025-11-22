CC = clang
CFLAGS = -fobjc-arc -Wall -Werror
LDFLAGS = -framework Cocoa

APP_NAME = MacOSUtility
APP_BUNDLE = $(APP_NAME).app
APP_EXECUTABLE = $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
APP_PLIST = $(APP_BUNDLE)/Contents/Info.plist

SOURCES = main.m AppDelegate.m SettingsWindowController.m Note.m

all: $(APP_BUNDLE)

$(APP_BUNDLE): $(SOURCES) Info.plist
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(APP_EXECUTABLE) $(SOURCES)
	cp Info.plist $(APP_PLIST)
	@echo "Built $(APP_BUNDLE)"

clean:
	rm -rf $(APP_BUNDLE)

