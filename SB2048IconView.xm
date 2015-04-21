#import "SB2048IconView.h"

%subclass SB2048IconView : SBIconView

- (id)initWithDefaultSize {
	if ((self = %orig())) {
	}
	return self;
}

- (NSString *)accessibilityValue {
	return [self.icon displayName];
}

- (NSString *)accessibilityHint {
	return [self.icon displayName];
}

%end

%hook SB2048Icon

- (Class)iconViewClassForLocation:(int)location {
	return %c(SB2048IconView);
}

%end