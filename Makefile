.PHONY: build run test app clean

build:
	swift build -c release

run:
	swift run -c release

test:
	swift test

# Generate an .xcodeproj via xcodegen and build a real .app bundle.
app:
	xcodegen generate
	xcodebuild -scheme FollowerCrusade -configuration Release -derivedDataPath build build
	@echo "App built: build/Build/Products/Release/FollowerCrusade.app"

clean:
	rm -rf .build build FollowerCrusade.xcodeproj
