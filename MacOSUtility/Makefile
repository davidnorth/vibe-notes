CC = clang
CFLAGS = -fobjc-arc -Wall -Werror
LDFLAGS = -framework Cocoa

APP_NAME = VibeNote
SOURCES = main.m AppDelegate.m SettingsWindowController.m Note.m
RESOURCES = Info.plist

all: $(APP_NAME).app

$(APP_NAME).app: $(SOURCES) $(RESOURCES)
	rm -rf $(APP_NAME).app
	mkdir -p $(APP_NAME).app/Contents/MacOS
	mkdir -p $(APP_NAME).app/Contents/Resources
	clang -fobjc-arc -Wall -Werror -framework Cocoa -o $(APP_NAME).app/Contents/MacOS/$(APP_NAME) $(SOURCES)
	cp Info.plist $(APP_NAME).app/Contents/Info.plist
	@echo "Built $(APP_NAME).app"

clean:
	rm -rf $(APP_NAME).app
